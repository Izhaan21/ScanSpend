import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _apiKey = 'AIzaSyAcB1RFZ0_qnWQM9CIuIoC__dvkfRuGYiI';

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

  // ─── FALLBACK: Parse OCR text through Gemini ─────────────────────────────
  Future<Map<String, dynamic>> parseReceiptText(String rawText) async {
    if (rawText.trim().isEmpty) {
      throw Exception('No text could be read from the image. Try better lighting or a clearer photo.');
    }

    try {
      final prompt = '$_systemInstruction\n\n--- RECEIPT TEXT ---\n$rawText\n--- END ---';
      final response = await _textModel.generateContent([Content.text(prompt)]);
      return _parse(response.text, source: 'ocr-text');
    } on GenerativeAIException catch (e) {
      throw _mapApiError(e);
    } catch (e) {
      throw Exception('Text parsing failed: $e');
    }
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
        throw Exception('_fallback_needed'); // triggers OCR fallback
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
