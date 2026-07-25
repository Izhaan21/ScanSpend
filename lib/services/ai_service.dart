import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _apiKey = 'AIzaSyAcB1RFZ0_qnWQM9CIuIoC__dvkfRuGYiI';

  /// Sentinel thrown by [_parse] when the image-mode response is valid JSON
  /// but has no recognisable merchant name, signalling that the OCR fallback
  /// pipeline should be tried instead.
  static const String kFallbackNeeded = 'FALLBACK_NEEDED';

  // Model with JSON output mode + low temperature for deterministic extraction
  final GenerativeModel _model;
  final GenerativeModel _textModel;

  AIService()
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1,
            responseMimeType: 'application/json',
          ),
        ),
        _textModel = GenerativeModel(
          model: 'gemini-2.0-flash',
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1,
            responseMimeType: 'application/json',
          ),
        );

  // ─── System instruction (built fresh each call to include current date) ──
  static String get _systemInstruction => '''
You are an expert receipt and invoice parser.
Your job is to extract structured data from receipt images or text.

ALWAYS return valid JSON in exactly this shape:
{
  "merchantName": "string",
  "date": "YYYY-MM-DDTHH:mm:ss.000",
  "total": number,
  "category": "string",
  "items": [{"name": "string", "price": number}]
}

Rules:
- merchantName: The EXACT business/clinic/store name from the header. Never return "Unknown Merchant" if any name is visible.
- total: The final charged amount. Search for Total, Grand Total, Net Payable, Amount Due, Rs., PKR, \$, £. Strip currency symbols.
- date: ISO 8601. If not found use today: ${DateTime.now().toIso8601String()}.
- category: Pick ONE from: Healthcare | Food & Dining | Groceries | Transport | Electronics | Shopping | Utilities | Other
  - Healthcare for hospitals, labs, pharmacies, clinics, doctors
  - Food & Dining for restaurants, cafes, fast food
  - Groceries for supermarkets, general stores
- items: Every individual line item / test / service with price. If no individual items are visible, use [{"name": "Total", "price": <total value>}].
- Prices: strip all currency symbols (Rs, PKR, \$, £, €) and return only the number.
- For medical receipts: each test (CBC, LFTs, Blood Sugar, Urine RE, X-Ray, etc.) is a SEPARATE item.
- Do NOT add any explanation, markdown, or text outside the JSON object.
''';

  // ─── PRIMARY: Send image bytes directly to Gemini Vision ─────────────────
  Future<Map<String, dynamic>> parseReceiptImage(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final ext = imagePath.split('.').last.toLowerCase();
      final mimeType = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

      // TextPart FIRST, then DataPart — required ordering for Gemini
      final response = await _model.generateContent([
        Content.multi([
          TextPart(_systemInstruction),
          DataPart(mimeType, bytes),
        ]),
      ]);

      return _parse(response.text, source: 'image');
    } on GenerativeAIException catch (e) {
      throw _mapApiError(e);
    } catch (e) {
      throw Exception('Image read failed: $e');
    }
  }

  // ── FALLBACK: Parse OCR text through Gemini ─────────────────────────────
  Future<Map<String, dynamic>> parseReceiptText(String rawText) async {
    if (rawText.trim().isEmpty) {
      throw Exception('No text could be read from the image. Try better lighting or a clearer photo.');
    }

    try {
      final prompt = '$_systemInstruction\n\n--- RECEIPT TEXT ---\n$rawText\n--- END ---';
      final response = await _textModel.generateContent([Content.text(prompt)]);
      return _parse(response.text, source: 'ocr-text');
    } catch (e) {
      // Automatic Fallback to Local Parser on any Gemini/API error (e.g. Quota Exceeded)
      // Using a log function instead of print to pass lints
      final logMessage = 'Gemini API failed with error: $e. Falling back to local parser...';
      debugPrint(logMessage);
      return parseReceiptTextLocally(rawText);
    }
  }

  // ── LOCAL FALLBACK PARSER (Regex & Heuristics) ───────────────────────────
  Map<String, dynamic> parseReceiptTextLocally(String rawText) {
    final lines = rawText.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return {
        'merchantName': 'Unknown Merchant',
        'date': DateTime.now().toIso8601String(),
        'total': 0.0,
        'category': 'Other',
        'items': <Map<String, dynamic>>[],
      };
    }

    // 1. Identify Merchant Name (First logical non-skipped line)
    String merchantName = 'Unknown Merchant';
    final skipKeywords = ['date', 'time', 'tax', 'receipt', 'invoice', 'welcome', 'tel', 'phone', 'cashier', 'rs.', 'pkr', '\$'];
    for (final line in lines) {
      final l = line.toLowerCase();
      bool skip = false;
      for (final kw in skipKeywords) {
        if (l.contains(kw)) {
          skip = true;
          break;
        }
      }
      if (!skip && line.length > 2) {
        merchantName = line;
        break;
      }
    }

    // 2. Extract Date
    String dateStr = DateTime.now().toIso8601String();
    final dateRegex = RegExp(r'(\d{2,4}[-/.]\d{2}[-/.]\d{2,4})');
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        final dateParsed = _tryParseDate(match.group(0)!);
        if (dateParsed != null) {
          dateStr = dateParsed;
          break;
        }
      }
    }

    // 3. Extract items & prices
    final List<Map<String, dynamic>> items = [];
    final priceRegex = RegExp(r'(\d+\.\d{2})'); // Match decimal values

    double parsedTotal = 0.0;
    double maxNum = 0.0;

    for (final line in lines) {
      final matches = priceRegex.allMatches(line);
      if (matches.isNotEmpty) {
        final lastMatch = matches.last.group(0)!;
        final price = double.tryParse(lastMatch) ?? 0.0;
        
        // Find item name (everything before the price)
        final idx = line.lastIndexOf(lastMatch);
        String name = line.substring(0, idx).trim()
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .trim();
            
        if (name.isEmpty) name = 'Item';
        
        final l = line.toLowerCase();
        if (l.contains('total') || l.contains('net') || l.contains('subtotal') || l.contains('amount')) {
          if (price > maxNum) {
            maxNum = price;
          }
          continue;
        }

        if (price > 0) {
          items.add({'name': name, 'price': price});
          parsedTotal += price;
        }
      }
    }

    // 4. Extract Total Amount
    double total = 0.0;
    bool foundTotalKeyword = false;
    for (final line in lines) {
      final l = line.toLowerCase();
      if (l.contains('total') || l.contains('net') || l.contains('payable') || l.contains('amount due')) {
        final matches = priceRegex.allMatches(line);
        if (matches.isNotEmpty) {
          total = double.tryParse(matches.last.group(0)!) ?? 0.0;
          foundTotalKeyword = true;
          break;
        }
      }
    }

    if (!foundTotalKeyword || total == 0.0) {
      total = maxNum > 0.0 ? maxNum : (parsedTotal > 0.0 ? parsedTotal : 0.0);
    }

    // 5. Category identification
    String category = 'Other';
    final rawTextLower = rawText.toLowerCase();
    if (rawTextLower.contains('pharma') || rawTextLower.contains('hospital') || rawTextLower.contains('medical') || rawTextLower.contains('clinic') || rawTextLower.contains('prescription') || rawTextLower.contains('lab')) {
      category = 'Healthcare';
    } else if (rawTextLower.contains('restaurant') || rawTextLower.contains('cafe') || rawTextLower.contains('coffee') || rawTextLower.contains('pizza') || rawTextLower.contains('burger') || rawTextLower.contains('food')) {
      category = 'Food & Dining';
    } else if (rawTextLower.contains('grocer') || rawTextLower.contains('supermarket') || rawTextLower.contains('mart') || rawTextLower.contains('store')) {
      category = 'Groceries';
    } else if (rawTextLower.contains('taxi') || rawTextLower.contains('uber') || rawTextLower.contains('careem') || rawTextLower.contains('fuel') || rawTextLower.contains('petrol')) {
      category = 'Transport';
    } else if (rawTextLower.contains('elec') || rawTextLower.contains('mobile') || rawTextLower.contains('laptop')) {
      category = 'Electronics';
    } else if (rawTextLower.contains('mall') || rawTextLower.contains('shopping') || rawTextLower.contains('clothing')) {
      category = 'Shopping';
    }

    if (items.isEmpty && total > 0) {
      items.add({'name': 'Total Expense', 'price': total});
    }

    return {
      'merchantName': merchantName,
      'date': dateStr,
      'total': total,
      'category': category,
      'items': items,
    };
  }

  String? _tryParseDate(String raw) {
    try {
      final cleaned = raw.replaceAll(RegExp(r'[./]'), '-');
      final parts = cleaned.split('-');
      if (parts.length == 3) {
        return DateTime.parse(cleaned).toIso8601String();
      }
    } catch (_) {}
    return null;
  }

  // ─── Response parser ──────────────────────────────────────────────────────
  Map<String, dynamic> _parse(String? text, {required String source}) {
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned an empty response ($source).');
    }

    // With responseMimeType=application/json the response should be clean JSON
    // but still strip any accidental fences just in case
    String cleaned = text.trim()
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Find the first { ... } block
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw Exception('No valid JSON found in Gemini response ($source):\n$cleaned');
    }
    cleaned = cleaned.substring(start, end + 1);

    final Map<String, dynamic> parsed = jsonDecode(cleaned);

    // Validate merchant — if still unknown, that's a real extraction failure
    final merchant = parsed['merchantName']?.toString().trim() ?? '';
    final total = _toDouble(parsed['total']);

    if (merchant.isEmpty || merchant.toLowerCase() == 'unknown merchant') {
      if (source == 'image') {
        throw Exception(AIService.kFallbackNeeded); // triggers OCR fallback
      }
      throw Exception('Could not identify the merchant name from this receipt.');
    }

    final rawItems = parsed['items'] as List<dynamic>? ?? [];
    final items = rawItems.map<Map<String, dynamic>>((item) => {
      'name': item['name']?.toString() ?? 'Item',
      'price': _toDouble(item['price']),
    }).toList();

    // If no items parsed but total exists, add a single fallback item
    if (items.isEmpty && total > 0) {
      items.add({'name': merchant, 'price': total});
    }

    return {
      'merchantName': merchant.isNotEmpty ? merchant : 'Unknown Merchant',
      'date': _parseDate(parsed['date']?.toString()),
      'total': total,
      'category': _normaliseCategory(parsed['category']?.toString()),
      'items': items,
    };
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final cleaned = value.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return DateTime.now().toIso8601String();
    try {
      return DateTime.parse(raw).toIso8601String();
    } catch (_) {
      return DateTime.now().toIso8601String();
    }
  }

  String _normaliseCategory(String? raw) {
    if (raw == null) return 'Other';
    final r = raw.toLowerCase();
    if (r.contains('health') || r.contains('medical') || r.contains('pharma') || r.contains('lab')) {
      return 'Healthcare';
    }
    if (r.contains('food') || r.contains('dining') || r.contains('restaurant') || r.contains('cafe')) {
      return 'Food & Dining';
    }
    if (r.contains('grocer') || r.contains('supermark') || r.contains('mart')) return 'Groceries';
    if (r.contains('transport') || r.contains('travel') || r.contains('uber') || r.contains('taxi')) {
      return 'Transport';
    }
    if (r.contains('electr')) return 'Electronics';
    if (r.contains('shop') || r.contains('retail')) return 'Shopping';
    if (r.contains('util') || r.contains('electric') || r.contains('gas') || r.contains('water') || r.contains('internet')) {
      return 'Utilities';
    }
    return raw; // pass through whatever Gemini returned
  }

  Exception _mapApiError(GenerativeAIException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('quota') || msg.contains('resource_exhausted') || msg.contains('429')) {
      return Exception(
        'QUOTA_EXCEEDED: Your Gemini API free-tier quota is used up.\n'
        'Visit: console.cloud.google.com → Enable Billing or wait for quota reset.',
      );
    }
    if (msg.contains('api key') || msg.contains('api_key') || msg.contains('invalid')) {
      return Exception('INVALID_KEY: The Gemini API key is invalid or not enabled for this project.');
    }
    if (msg.contains('not found') || msg.contains('model')) {
      return Exception('MODEL_ERROR: Model not available. Check your API key\'s allowed models.');
    }
    return Exception('GEMINI_ERROR: ${e.message}');
  }
}
