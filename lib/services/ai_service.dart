import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _apiKey = 'AIzaSyAcB1RFZ0_qnWQM9CIuIoC__dvkfRuGYiI';

  /// Sentinel thrown by [_parse] when the vision response has no usable total,
  /// signalling the OCR fallback pipeline should be tried instead.
  static const String kFallbackNeeded = 'FALLBACK_NEEDED';

  final GenerativeModel _model;
  final GenerativeModel _textModel;

  AIService()
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1,
            responseMimeType: 'application/json',
          ),
        ),
        _textModel = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.1,
            responseMimeType: 'application/json',
          ),
        );

  // ── Retry helper ─────────────────────────────────────────────────────────────
  /// Retries [fn] up to [maxAttempts] times with 1-second backoff.
  /// Intentional signals (kFallbackNeeded, quota errors) are never retried.
  Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 2,
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } catch (e) {
        final msg = e.toString();
        // Never retry intentional signals or non-recoverable API errors
        if (msg.contains(kFallbackNeeded) ||
            msg.contains('QUOTA_EXCEEDED') ||
            msg.contains('INVALID_KEY') ||
            msg.contains('MODEL_ERROR')) {
          rethrow;
        }
        if (attempt == maxAttempts) rethrow;
        debugPrint('Gemini attempt $attempt failed: $msg — retrying...');
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw StateError('_withRetry: unreachable');
  }

  // ── System instruction ───────────────────────────────────────────────────────
  static String get _systemInstruction {
    final today = DateTime.now().toIso8601String();
    return '''
You are an expert receipt and invoice parser that works with ANY type of receipt:
supermarkets, restaurants, pharmacies, petrol stations, utility bills, medical labs,
clothing stores, electronics shops, hotels, and more.

ALWAYS return valid JSON in exactly this shape (no markdown, no explanation):
{
  "merchantName": "string",
  "address": "string",
  "phone": "string",
  "receiptNumber": "string",
  "date": "YYYY-MM-DDTHH:mm:ss.000",
  "paymentMethod": "string",
  "currency": "string",
  "items": [{"name": "string", "quantity": 1, "price": 0}],
  "subtotal": 0,
  "tax": 0,
  "discount": 0,
  "total": 0,
  "category": "string"
}

FIELD RULES:
merchantName:
  - Read from the TOP HEADER of the receipt (first 1-3 lines).
  - NEVER use footer text ("Thank You", "Please Come Again", exchange/refund policies).
  - Use the exact store/business name as printed.

currency:
  - \$ for USD or AUD or any dollar
  - Rs or PKR for Pakistani Rupees
  - £ for GBP
  - € for EUR
  - AED for UAE Dirham
  - SAR for Saudi Riyal
  - INR or ₹ for Indian Rupee
  - Use whatever symbol is printed on the receipt.

address:
  - Full address from the receipt header. Empty string "" if absent.

phone:
  - A REAL phone/contact number only.
  - SKU codes, barcode numbers, ABN numbers, card numbers are NOT phone numbers.
  - A phone number typically starts with + or 0 and has 7-15 digits with spaces/dashes.
  - Empty string "" if none found.

receiptNumber:
  - Receipt #, Invoice #, Order #, Bill #, Ref #. Empty string "" if absent.

date:
  - ISO 8601 format. If absent, use: $today

paymentMethod:
  - Detect from keywords: cash, card, credit card, debit card, visa, mastercard,
    eftpos, easypaisa, jazzcash, UPI, online, bank transfer, apple pay, google pay.
  - Empty string "" if absent.

items:
  - List EVERY individual line item from the body of the receipt.
  - name: exact product/service/test name.
  - quantity: number of units (default 1).
  - price: line-item total as a plain number. Strip \$, Rs, £, €, AED, SAR, etc.
  - Handle dot-thousands: \$1.997.00 → 1997, \$2.020.90 → 2020.90
  - Handle comma-thousands: 1,500 → 1500, 1,500.00 → 1500.00
  - SKU lines (lines starting with SKU:) are NOT items.

subtotal: total before tax/discount. 0 if absent.
tax: GST/VAT/tax/service charge amount. 0 if absent.
discount: discount/rebate amount as positive number. 0 if absent.

total — THIS IS THE MOST IMPORTANT FIELD:
  - The FINAL amount charged. Look for: Total, Grand Total, Net Payable,
    Amount Due, Net Amount, Bill Amount, Amount Payable.
  - ALWAYS read the EXACT number printed next to "Total" on the receipt.
  - Do NOT recalculate or recompute it — use what the receipt says.
  - If no explicit total line exists, SUM all item prices + tax - discount.
  - MUST be a positive number. NEVER return 0 if any prices are visible.
  - If you can see ANY monetary amount on the receipt, total MUST NOT be 0.
  - Apply same number cleaning as items (strip symbols, handle dot/comma thousands).

category — pick ONE:
  Healthcare   : hospitals, labs, pharmacies, clinics, doctors, medical tests, pathology
  Food & Dining: restaurants, cafes, fast food, bakeries, canteens, dhabas
  Groceries    : supermarkets, general stores, kiryana, hypermarkets
  Transport    : fuel/petrol, taxi, uber, careem, ride-share, tolls, parking
  Electronics  : mobiles, laptops, gadgets, repair shops, electronics stores
  Utilities    : electricity, gas, water, internet, WAPDA, SUI, telecom bills
  Shopping     : clothing, malls, department stores (Kmart, Target, Walmart, etc.)
  Other        : anything else

CRITICAL RULES:
- Prices must be plain numbers: strip ALL currency symbols and commas.
- Dot-thousands (e.g. 1.997.00, 2.020.90) → remove all dots except the last decimal.
- If a field is missing: return "" for strings, 0 for numbers.
- The total MUST NEVER be 0 when items or any price is visible on the receipt.
- Return ONLY the raw JSON object. No markdown fences, no extra text.
''';
  }

  // ── PRIMARY: Gemini Vision (image → JSON) ────────────────────────────────────
  Future<Map<String, dynamic>> parseReceiptImage(String imagePath) async {
    return _withRetry(() async {
      try {
        final bytes = await File(imagePath).readAsBytes();
        final ext = imagePath.split('.').last.toLowerCase();
        final mimeType = switch (ext) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };

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
        final msg = e.toString();
        if (msg.contains(kFallbackNeeded)) rethrow;
        throw Exception('Image processing failed: $e');
      }
    });
  }

  // ── FALLBACK: Gemini Text (OCR text → JSON) ──────────────────────────────────
  Future<Map<String, dynamic>> parseReceiptText(String rawText) async {
    if (rawText.trim().isEmpty) {
      throw Exception(
          'No text could be read from the image. Try better lighting or a clearer photo.');
    }

    try {
      return await _withRetry(() async {
        final prompt =
            '$_systemInstruction\n\n--- RECEIPT TEXT ---\n$rawText\n--- END ---';
        final response =
            await _textModel.generateContent([Content.text(prompt)]);
        return _parse(response.text, source: 'ocr-text');
      });
    } catch (e) {
      debugPrint('Gemini text API failed: $e — running local parser...');
      return parseReceiptTextLocally(rawText);
    }
  }

  // ── LOCAL FALLBACK PARSER (Regex + Heuristics) ────────────────────────────────
  /// Pure-Dart, no-network parser. Used when all API methods fail.
  Map<String, dynamic> parseReceiptTextLocally(String rawText,
      {String? defaultCurrency}) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return _emptyResult();
    }

    final rawLower = rawText.toLowerCase();

    // ── 1. Merchant Name ──────────────────────────────────────────────────────
    // Skip common header noise so we land on the actual business name.
    // Strategy: the real merchant name is in the FIRST 1-3 lines and never
    // contains metadata keywords, policy text, or starts with digits/symbols.
    String merchantName = 'Unknown Merchant';
    const merchantSkip = [
      'date', 'time', 'tax', 'receipt', 'invoice', 'welcome',
      'tel:', 'phone:', 'contact:', 'cashier', 'rs.', 'pkr', r'$', 'www.',
      'http', 'sku:', 'abn ', 'operator', 'please', 'thank',
      'item desc', 'qty', 'quantity', 'amount', 'price', 'total',
      ' rd,', ' rd.', '.vic', '.nsw', '.qld', '.wa', '.sa', '.tas',
      // Footer / policy text that can appear at any line
      'excluded', 'change of mind', 'refund', 'policy', 'exchange',
      'some items', 'not applicable', 'conditions', 'proof of',
      'subject to', 'reserve the right',
    ];
    for (final line in lines) {
      final l = line.toLowerCase();
      // Skip if contains any noise keyword
      final skip = merchantSkip.any((kw) => l.contains(kw)) ||
          RegExp(r'^\d').hasMatch(line) || // starts with digit
          RegExp(r'^[^a-zA-Z]').hasMatch(line) || // starts with symbol
          line.length < 3;
      if (!skip) {
        merchantName = line;
        break;
      }
    }

    // ── 2. Address ────────────────────────────────────────────────────────────
    String address = '';
    final addressRegex = RegExp(
      r'\b(street|road|avenue|block|sector|town|city|near|opposite|'
      r'westfield|shopping centre|plaza|market|rd\b|lane|drive|floor|level)\b',
      caseSensitive: false,
    );
    for (final line in lines) {
      if (line == merchantName) continue; // don't re-use merchant line
      if (addressRegex.hasMatch(line)) {
        address = line;
        break;
      }
    }

    // ── 3. Phone ──────────────────────────────────────────────────────────────
    // A real phone: 7-15 digits, may have +, spaces, dashes.
    // Excludes: SKU lines, ABN lines, card number lines.
    String phone = '';
    final phoneRegex = RegExp(r'(\+?\d[\d\s\-]{5,14}\d)');
    final phoneNoiseLine = RegExp(r'sku|abn|xxxx|xxxx|\*\*\*\*|barcode',
        caseSensitive: false);

    // Priority 1: lines explicitly labelled tel/ph/contact
    for (final line in lines) {
      final l = line.toLowerCase();
      if (phoneNoiseLine.hasMatch(l)) continue;
      if (l.contains('tel') || l.contains('ph:') || l.contains('contact')) {
        final m = phoneRegex.firstMatch(line);
        if (m != null) {
          phone = m.group(0)!.trim();
          break;
        }
      }
    }
    // Priority 2: standalone number that looks like a phone (7-15 digits)
    if (phone.isEmpty) {
      for (final line in lines) {
        if (phoneNoiseLine.hasMatch(line.toLowerCase())) continue;
        final m = phoneRegex.firstMatch(line);
        if (m != null) {
          final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
          if (digits.length >= 7 && digits.length <= 15) {
            phone = m.group(0)!.trim();
            break;
          }
        }
      }
    }

    // ── 4. Receipt Number ─────────────────────────────────────────────────────
    String receiptNumber = '';
    final receiptNoRegex = RegExp(
      r'\b(?:receipt|invoice|bill|order|ref|booking)\s*[#:\-]?\s*([A-Z0-9\-]+)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final m = receiptNoRegex.firstMatch(line);
      if (m != null) {
        receiptNumber = m.group(1)!.trim();
        break;
      }
    }

    // ── 5. Date ───────────────────────────────────────────────────────────────
    String dateStr = DateTime.now().toIso8601String();
    final numericDateRegex = RegExp(r'(\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4})');
    outerDate:
    for (final line in lines) {
      final match = numericDateRegex.firstMatch(line);
      if (match != null) {
        final parsed = _tryParseDate(match.group(0)!);
        if (parsed != null) {
          dateStr = parsed;
          break outerDate;
        }
      }
      final written = _tryParseWrittenDate(line);
      if (written != null) {
        dateStr = written;
        break outerDate;
      }
    }

    // ── 6. Payment Method ─────────────────────────────────────────────────────
    String paymentMethod = '';
    if (rawLower.contains('easypaisa')) {
      paymentMethod = 'EasyPaisa';
    } else if (rawLower.contains('jazzcash')) {
      paymentMethod = 'JazzCash';
    } else if (rawLower.contains('apple pay')) {
      paymentMethod = 'Apple Pay';
    } else if (rawLower.contains('google pay') || rawLower.contains('gpay')) {
      paymentMethod = 'Google Pay';
    } else if (rawLower.contains('upi')) {
      paymentMethod = 'UPI';
    } else if (rawLower.contains('eftpos') ||
        rawLower.contains('credit card') ||
        rawLower.contains('visa') ||
        rawLower.contains('mastercard') ||
        rawLower.contains('amex') ||
        rawLower.contains('card type')) {
      paymentMethod = 'Card';
    } else if (rawLower.contains('debit')) {
      paymentMethod = 'Debit Card';
    } else if (rawLower.contains('bank transfer') ||
        rawLower.contains('online transfer')) {
      paymentMethod = 'Bank Transfer';
    } else if (rawLower.contains('cash')) {
      paymentMethod = 'Cash';
    } else if (rawLower.contains('online')) {
      paymentMethod = 'Online';
    }

    // ── 7. Items / Prices ─────────────────────────────────────────────────────
    final List<Map<String, dynamic>> items = [];
    double subtotal = 0.0;
    double tax = 0.0;
    double discount = 0.0;
    double explicitTotal = 0.0;
    double parsedItemSum = 0.0;

    // Price pattern: currency symbol prefix OR decimal .XX suffix OR standalone number
    final strictPriceRegex = RegExp(
      r'(?:(?:Rs\.?|PKR|AED|SAR|SR|INR|₹|\$|€|£)\s*(\d[\d.,]*\d|\d+)'
      r'|\b(\d+(?:[.,]\d{3})*[.,]\d{2})'
      r'|\b(\d+\.\d{1,2})\b)',
      caseSensitive: false,
    );

    // Qty at line start: "2x", "2 x", "1 "
    final qtyRegex = RegExp(r'^\s*(\d+)\s*x?\s+', caseSensitive: false);

    // Lines to skip in the items loop (metadata, footer, card info, etc.)
    final metadataKeywords = [
      'phone', 'ph:', 'tel:', 'fax:', 'address:', 'date:', 'time:',
      'receipt', 'invoice', 'order #', 'order:', 'bill #', 'ref #',
      'register:', 'cashier:', 'welcome', 'customer', 'patient',
      'dha phase', 'street', ' road', ' near', 'bank card', 'card type',
      'entry mode', 'swiped', 'visa', 'mastercard', 'amex', 'xxxx', '****',
      'thank you', 'rewards', 'visit', 'sku:', 'item desc', 'abn ',
      'refund policy', 'come back', 'please come', 'exchange',
      'operator', 'westfield', 'shopping centre',
    ];

    for (final line in lines) {
      final lLower = line.toLowerCase();

      if (metadataKeywords.any((kw) => lLower.contains(kw))) {
        // Still try to harvest receipt number from order/receipt lines
        if (receiptNumber.isEmpty &&
            (lLower.contains('order #') || lLower.contains('receipt #'))) {
          final m = RegExp(r'(?:order|receipt)\s*#:?\s*([A-Z0-9\-]+)',
                  caseSensitive: false)
              .firstMatch(line);
          if (m != null) receiptNumber = m.group(1)!.trim();
        }
        continue;
      }

      final isSubtotalLine = lLower.contains('subtotal') ||
          lLower.contains('sub total') ||
          lLower.contains('sub-total') ||
          lLower.contains('subtptal');
      final isTotalLine = !isSubtotalLine &&
          (lLower.contains('total') ||
              lLower.contains('net payable') ||
              lLower.contains('amount due') ||
              lLower.contains('amount payable') ||
              lLower.contains('payable') ||
              lLower.contains('bill amount') ||
              lLower.contains('grand total') ||
              lLower.contains('net amount'));
      final isTaxLine = lLower.contains('tax') ||
          lLower.contains('gst') ||
          lLower.contains('vat') ||
          lLower.contains('service charge') ||
          lLower.contains('gst included');
      final isDiscountLine =
          lLower.contains('discount') || lLower.contains('rebate') || lLower.contains('promo');

      final matches = strictPriceRegex.allMatches(line);
      if (matches.isEmpty) continue;

      final lastMatch = matches.last;
      final rawPriceStr =
          (lastMatch.group(1) ?? lastMatch.group(2) ?? lastMatch.group(3) ?? '').trim();
      final priceVal = _toDouble(rawPriceStr);
      if (priceVal <= 0) continue;

      if (isTotalLine) {
        if (priceVal > explicitTotal) explicitTotal = priceVal;
        continue;
      }
      if (isSubtotalLine) {
        subtotal = priceVal;
        continue;
      }
      if (isTaxLine) {
        tax = priceVal;
        continue;
      }
      if (isDiscountLine) {
        discount = priceVal;
        continue;
      }

      // Item line: extract name + quantity
      String itemLine = line.substring(0, lastMatch.start).trim();
      int quantity = 1;

      final qMatch = qtyRegex.firstMatch(itemLine);
      if (qMatch != null) {
        quantity = int.tryParse(qMatch.group(1)!) ?? 1;
        itemLine = itemLine.substring(qMatch.end).trim();
      }

      String name = itemLine
          .replaceAll(RegExp(r'^\s*[\+\-\*\.\)]\s*'), '')
          .replaceAll(RegExp(r'^\d+[\.!\)]\s*'), '')
          .replaceAll(RegExp(r'[*|]'), '')
          .trim();

      if (name.length >= 2) {
        items.add({'name': name, 'price': priceVal, 'quantity': quantity});
        parsedItemSum += priceVal;
      }
    }

    // ── 8. Totals ─────────────────────────────────────────────────────────────
    if (subtotal == 0.0 && parsedItemSum > 0.0) subtotal = parsedItemSum;

    double total = explicitTotal;
    if (total == 0.0) {
      total = subtotal > 0.0 ? subtotal - discount + tax : parsedItemSum;
    }

    // Safety net: if total is still 0 but we found items, use item sum
    if (total <= 0.0 && parsedItemSum > 0.0) {
      total = parsedItemSum;
    }

    // Last resort: if total is still 0, scan ALL lines for the largest number
    if (total <= 0.0) {
      final anyNumberRegex = RegExp(r'(\d+[.,]\d{2})');
      double largestNum = 0.0;
      for (final line in lines) {
        for (final m in anyNumberRegex.allMatches(line)) {
          final val = _toDouble(m.group(1));
          if (val > largestNum) largestNum = val;
        }
      }
      if (largestNum > 0) total = largestNum;
    }

    if (items.isEmpty && total > 0) {
      items.add({'name': 'Total Expense', 'price': total, 'quantity': 1});
    }

    // ── 9. Category ───────────────────────────────────────────────────────────
    String category = _detectCategory(rawLower);

    // ── 10. Currency ──────────────────────────────────────────────────────────
    String currency = defaultCurrency ?? '\$';
    if (rawText.contains('Rs.') ||
        rawText.contains('Rs ') ||
        rawText.contains('PKR') ||
        rawText.contains('Rs:')) {
      currency = 'Rs';
    } else if (rawText.contains('AED') || rawText.contains('د.إ')) {
      currency = 'AED';
    } else if (rawText.contains('SAR') ||
        rawText.contains('ريال') ||
        rawText.contains(' SR ')) {
      currency = 'SAR';
    } else if (rawText.contains('INR') || rawText.contains('₹')) {
      currency = '₹';
    } else if (rawText.contains('£')) {
      currency = '£';
    } else if (rawText.contains('€')) {
      currency = '€';
    } else if (rawText.contains('\$') || rawText.contains('AUD')) {
      currency = '\$';
    }

    return {
      'merchantName': merchantName,
      'address': address,
      'phone': phone,
      'receiptNumber': receiptNumber,
      'date': dateStr,
      'paymentMethod': paymentMethod,
      'currency': currency,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'category': category,
      'items': items,
    };
  }

  // ── Category detection ────────────────────────────────────────────────────────
  String _detectCategory(String rawLower) {
    if (rawLower.contains('pharma') ||
        rawLower.contains('hospital') ||
        rawLower.contains('medical') ||
        rawLower.contains('clinic') ||
        rawLower.contains('prescription') ||
        rawLower.contains('lab') ||
        rawLower.contains('doctor') ||
        rawLower.contains('patholog') ||
        rawLower.contains('radiology') ||
        rawLower.contains('diagnostic') ||
        rawLower.contains('health')) {
      return 'Healthcare';
    }
    if (rawLower.contains('restaurant') ||
        rawLower.contains('cafe') ||
        rawLower.contains('coffee') ||
        rawLower.contains('pizza') ||
        rawLower.contains('burger') ||
        rawLower.contains('biryani') ||
        rawLower.contains('bakery') ||
        rawLower.contains('canteen') ||
        rawLower.contains('dhaba') ||
        rawLower.contains('grill') ||
        rawLower.contains('shawarma') ||
        rawLower.contains('fast food')) {
      return 'Food & Dining';
    }
    if (rawLower.contains('grocer') ||
        rawLower.contains('supermarket') ||
        rawLower.contains('hypermarket') ||
        rawLower.contains('kiryana') ||
        rawLower.contains('agha') ||
        rawLower.contains('naheed') ||
        rawLower.contains('al-fatah') ||
        rawLower.contains('carrefour') ||
        rawLower.contains('lulu') ||
        rawLower.contains('metro cash')) {
      return 'Groceries';
    }
    if (rawLower.contains('petrol') ||
        rawLower.contains('fuel') ||
        rawLower.contains('diesel') ||
        rawLower.contains('pso') ||
        rawLower.contains('shell') ||
        rawLower.contains('caltex') ||
        rawLower.contains('taxi') ||
        rawLower.contains('uber') ||
        rawLower.contains('careem') ||
        rawLower.contains('toll') ||
        rawLower.contains('parking')) {
      return 'Transport';
    }
    if (rawLower.contains('wapda') ||
        rawLower.contains('electricity') ||
        rawLower.contains('gas bill') ||
        rawLower.contains('sngpl') ||
        rawLower.contains('ssgc') ||
        rawLower.contains('sui northern') ||
        rawLower.contains('internet') ||
        rawLower.contains('broadband') ||
        rawLower.contains('ptcl') ||
        rawLower.contains('utility')) {
      return 'Utilities';
    }
    if (rawLower.contains('mobile') ||
        rawLower.contains('smartphone') ||
        rawLower.contains('laptop') ||
        rawLower.contains('iphone') ||
        rawLower.contains('samsung') ||
        rawLower.contains('gadget') ||
        rawLower.contains('electronics') ||
        rawLower.contains('computer') ||
        rawLower.contains('repair')) {
      return 'Electronics';
    }
    // Shopping: department/clothing stores & known chains
    if (rawLower.contains('mall') ||
        rawLower.contains('shopping') ||
        rawLower.contains('clothing') ||
        rawLower.contains('fashion') ||
        rawLower.contains('apparel') ||
        rawLower.contains('kmart') ||
        rawLower.contains('target') ||
        rawLower.contains('walmart') ||
        rawLower.contains('woolworths') ||
        rawLower.contains('coles') ||
        rawLower.contains('zara') ||
        rawLower.contains('h&m') ||
        rawLower.contains('uniqlo') ||
        rawLower.contains('j. crew') ||
        rawLower.contains('department')) {
      return 'Shopping';
    }
    return 'Other';
  }

  // ── Date helpers ──────────────────────────────────────────────────────────────
  String? _tryParseDate(String raw) {
    try {
      // Normalise separators to '-'
      final cleaned = raw.trim().replaceAll(RegExp(r'[./]'), '-');
      final parts = cleaned.split('-');
      if (parts.length == 3) {
        // Try as-is (handles YYYY-MM-DD)
        final attempt = DateTime.tryParse(cleaned);
        if (attempt != null) return attempt.toIso8601String();
        // Try DD-MM-YYYY
        if (parts[0].length <= 2 && parts[2].length == 4) {
          final reordered =
              '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
          final attempt2 = DateTime.tryParse(reordered);
          if (attempt2 != null) return attempt2.toIso8601String();
        }
        // Try MM-DD-YYYY (US format)
        if (parts[0].length <= 2 &&
            parts[1].length <= 2 &&
            parts[2].length == 4) {
          final reordered =
              '${parts[2]}-${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}';
          final attempt3 = DateTime.tryParse(reordered);
          if (attempt3 != null) return attempt3.toIso8601String();
        }
      }
    } catch (_) {}
    return null;
  }

  String? _tryParseWrittenDate(String line) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final pattern = RegExp(
      r'(\d{1,2})[\s\-/]([A-Za-z]{3,9})[\s\-/,]+(\d{4})',
      caseSensitive: false,
    );
    final m = pattern.firstMatch(line);
    if (m != null) {
      final day = int.tryParse(m.group(1)!) ?? 1;
      final monthStr = m.group(2)!.toLowerCase().substring(0, 3);
      final year = int.tryParse(m.group(3)!) ?? DateTime.now().year;
      final month = months[monthStr];
      if (month != null) return DateTime(year, month, day).toIso8601String();
    }
    return null;
  }

  // ── Response parser ───────────────────────────────────────────────────────────
  Map<String, dynamic> _parse(String? text, {required String source}) {
    if (text == null || text.trim().isEmpty) {
      throw Exception('Gemini returned an empty response ($source).');
    }

    // Strip accidental markdown fences
    String cleaned = text
        .trim()
        .replaceAll(RegExp(r'```json\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw Exception(
          'No valid JSON found in Gemini response ($source):\n$cleaned');
    }
    cleaned = cleaned.substring(start, end + 1);

    final Map<String, dynamic> parsed = jsonDecode(cleaned);

    final merchant = parsed['merchantName']?.toString().trim() ?? '';
    double total = _toDouble(parsed['total']);

    final rawItems = parsed['items'] as List<dynamic>? ?? [];
    final items = rawItems.map<Map<String, dynamic>>((item) => {
          'name': item['name']?.toString() ?? 'Item',
          'price': _toDouble(item['price']),
          'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
        }).toList();

    // Compute item sum for fallback
    double itemSum = 0.0;
    for (final item in items) {
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      itemSum += price * qty;
    }

    // If total is 0 but we have items with prices, compute from items + tax - discount
    if (total <= 0 && itemSum > 0) {
      final tax = _toDouble(parsed['tax']);
      final discount = _toDouble(parsed['discount']);
      total = itemSum + tax - discount;
      debugPrint('$source: total was 0, computed from items: $total');
    }

    // If total is 0 but subtotal exists, use subtotal
    if (total <= 0) {
      final subtotal = _toDouble(parsed['subtotal']);
      if (subtotal > 0) {
        final tax = _toDouble(parsed['tax']);
        final discount = _toDouble(parsed['discount']);
        total = subtotal + tax - discount;
        debugPrint('$source: total was 0, computed from subtotal: $total');
      }
    }

    final totalMissing = total <= 0;

    // If vision returned $0 total AND no items → run OCR fallback
    if (source == 'image' && totalMissing) {
      throw Exception(AIService.kFallbackNeeded);
    }
    // If OCR text parse returned $0 total AND no items → throw so parseReceiptText
    // catches it and falls back to the local regex parser.
    if (source == 'ocr-text' && totalMissing) {
      throw Exception('OCR-text: total not extracted — using local parser.');
    }

    // If Gemini returned no items but total > 0, create a single fallback item
    if (items.isEmpty && total > 0) {
      items.add({
        'name': merchant.isNotEmpty ? merchant : 'Total Expense',
        'price': total,
        'quantity': 1,
      });
    }

    return {
      'merchantName': merchant.isNotEmpty ? merchant : 'Unknown Merchant',
      'address': parsed['address']?.toString().trim() ?? '',
      'phone': parsed['phone']?.toString().trim() ?? '',
      'receiptNumber': parsed['receiptNumber']?.toString().trim() ?? '',
      'date': _parseDate(parsed['date']?.toString()),
      'paymentMethod': parsed['paymentMethod']?.toString().trim() ?? '',
      'currency': parsed['currency']?.toString().trim().isNotEmpty == true
          ? parsed['currency'].toString().trim()
          : '\$',
      'subtotal': _toDouble(parsed['subtotal']),
      'tax': _toDouble(parsed['tax']),
      'discount': _toDouble(parsed['discount']),
      'total': total,
      'category': _normaliseCategory(parsed['category']?.toString()),
      'items': items,
    };
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    String str = value.toString().trim();
    if (str.isEmpty) return 0.0;

    // Remove any leading/trailing currency symbols
    str = str.replaceAll(
        RegExp(r'^[\$£€₹]|Rs\.?|PKR|AED|SAR|SR|INR', caseSensitive: false),
        '');
    str = str.trim();

    // Handle dot-thousands: 1.997.00 or 2.020.90 → strip all but last separator
    final dotCount = '.'.allMatches(str).length;
    final commaCount = ','.allMatches(str).length;

    if (dotCount > 1) {
      // e.g. "1.997.00" → "199700" → "1997.00"
      final lastDotIdx = str.lastIndexOf('.');
      final intPart = str.substring(0, lastDotIdx).replaceAll('.', '');
      final decPart = str.substring(lastDotIdx); // ".00"
      str = '$intPart$decPart';
    } else if (commaCount > 1) {
      // e.g. "1,500,00" → strip commas
      str = str.replaceAll(',', '');
    } else if (dotCount == 1 && commaCount == 1) {
      // "1,500.00" or "1.500,00"
      final dotIdx = str.indexOf('.');
      final commaIdx = str.indexOf(',');
      if (commaIdx < dotIdx) {
        // comma is thousands separator: "1,500.00" → "1500.00"
        str = str.replaceAll(',', '');
      } else {
        // dot is thousands separator (European): "1.500,00" → "1500.00"
        str = str.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (commaCount == 1 && dotCount == 0) {
      // e.g. "1500,00" (European decimal) or "1,500" (thousands)
      final commaIdx = str.indexOf(',');
      final afterComma = str.substring(commaIdx + 1);
      if (afterComma.length == 2) {
        // Looks like decimal: "1500,00" → "1500.00"
        str = str.replaceAll(',', '.');
      } else {
        // Thousands comma: "1,500" → "1500"
        str = str.replaceAll(',', '');
      }
    }

    final cleaned = str.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  String _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return DateTime.now().toIso8601String();
    }
    try {
      return DateTime.parse(raw).toIso8601String();
    } catch (_) {
      return DateTime.now().toIso8601String();
    }
  }

  String _normaliseCategory(String? raw) {
    if (raw == null) return 'Other';
    return _detectCategory(raw.toLowerCase());
  }

  Map<String, dynamic> _emptyResult() => {
        'merchantName': 'Unknown Merchant',
        'address': '',
        'phone': '',
        'receiptNumber': '',
        'date': DateTime.now().toIso8601String(),
        'paymentMethod': '',
        'currency': '\$',
        'subtotal': 0.0,
        'tax': 0.0,
        'discount': 0.0,
        'total': 0.0,
        'category': 'Other',
        'items': <Map<String, dynamic>>[],
      };

  Exception _mapApiError(GenerativeAIException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('quota') ||
        msg.contains('resource_exhausted') ||
        msg.contains('429')) {
      return Exception(
        'QUOTA_EXCEEDED: Gemini API free-tier quota used up.\n'
        'Visit: console.cloud.google.com → Enable Billing or wait for reset.',
      );
    }
    if (msg.contains('api key') ||
        msg.contains('api_key') ||
        msg.contains('invalid')) {
      return Exception(
          'INVALID_KEY: The Gemini API key is invalid or not enabled.');
    }
    if (msg.contains('not found') || msg.contains('model')) {
      return Exception(
          'MODEL_ERROR: Gemini model not available. '
          'The model name may be outdated or your API key may not have access to it.');
    }
    return Exception('GEMINI_ERROR: ${e.message}');
  }
}
