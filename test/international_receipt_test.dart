import 'package:flutter_test/flutter_test.dart';
import 'package:scanspend/services/ai_service.dart';

void main() {
  final aiService = AIService();

  group('International Receipt Extraction Tests', () {
    test('1. UAE Receipt (AED)', () {
      const rawText = '''
Carrefour
Mall of the Emirates, Dubai
Tel: +971 4 409 9000
Receipt #: 100456
Date: 15-08-2023
--------------------------------
Fresh Milk 2L           1 x AED 12.50
Bread                   1 x AED 4.75
Chicken Breast          1 x AED 25.00
--------------------------------
Subtotal: AED 42.25
Tax (VAT 5%): AED 2.11
Total: AED 44.36
Payment: Visa
Thank you for shopping!
      ''';

      final result = aiService.parseReceiptTextLocally(rawText);

      expect(result['merchantName'], 'Carrefour');
      expect(result['currency'], 'AED');
      expect(result['total'], 44.36);
      expect(result['items'].length, 3);
      expect(result['paymentMethod'], 'Card');
    });

    test('2. UK Receipt (GBP)', () {
      const rawText = '''
Tesco Superstore
High Street, London
Ph: 0345 677 9000
Invoice: 89901
Date: 10/09/2023
--------------------------------
Tea Bags                1 x £ 3.50
Biscuits                2 x £ 1.20
--------------------------------
Total: £ 5.90
Payment: Card
Please keep your receipt.
      ''';

      final result = aiService.parseReceiptTextLocally(rawText);

      expect(result['merchantName'], 'Tesco Superstore');
      expect(result['currency'], '£');
      expect(result['total'], 5.90);
      expect(result['items'].length, 2);
    });

    test('3. European Receipt (EUR with comma decimals)', () {
      const rawText = '''
REWE Markt
Berlin, Germany
Tel: +49 30 123456
Date: 20-10-2023
--------------------------------
Apfelsaft               1 x 2,99 €
Brot                    1 x 1,50 €
Käse                    1 x 4,20 €
--------------------------------
Total: 8,69 €
Payment: Cash
Vielen Dank!
      ''';

      final result = aiService.parseReceiptTextLocally(rawText);

      expect(result['currency'], '€');
      expect(result['total'], 8.69); // Parsed correctly from comma decimal
      expect(result['items'].length, 3);
      expect(result['items'][0]['price'], 2.99);
      expect(result['paymentMethod'], 'Cash');
    });

    test('4. Indian Receipt (INR)', () {
      const rawText = '''
Reliance Smart
Mumbai, India
Tel: +91 9876543210
Date: 12-11-2023
--------------------------------
Rice 5kg                1 x ₹ 350.00
Dal 1kg                 1 x ₹ 120.00
Oil 1L                  1 x ₹ 150.00
--------------------------------
Sub Total: ₹ 620.00
Total: ₹ 620.00
Payment: UPI
Thank you!
      ''';

      final result = aiService.parseReceiptTextLocally(rawText);

      expect(result['currency'], '₹');
      expect(result['total'], 620.00);
      expect(result['items'].length, 3);
      expect(result['paymentMethod'], 'UPI');
    });

    test('5. Saudi Arabia Receipt (SAR)', () {
      const rawText = '''
Panda Supermarket
Riyadh, KSA
Tel: +966 11 123 4567
Date: 05-12-2023
--------------------------------
Water 1.5L              1 x SAR 2.00
Dates 1kg               1 x SAR 35.00
--------------------------------
Total: SAR 37.00
Payment: Mada (Card)
      ''';

      final result = aiService.parseReceiptTextLocally(rawText);

      expect(result['currency'], 'SAR');
      expect(result['total'], 37.00);
      expect(result['items'].length, 2);
    });
  });
}
