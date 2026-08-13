import 'package:flutter_test/flutter_test.dart';
import 'package:scanspend/services/ai_service.dart';

void main() {
  final aiService = AIService();

  group('Receipt Extraction Verification Tests (Local Parser Fallback)', () {
    test('1. Medical / Hospital Receipt Extraction', () {
      const medicalReceiptText = '''
CHUGHTAI LAB / DR. RIZWAN CLINIC
Main Boulevard, Gulberg III, Lahore
Ph: 042-111-456-789
Date: 25-07-2026  Time: 14:30
Receipt #: CL-88492
Patient Name: Ali Khan

--- ITEMS / TESTS ---
1. Complete Blood Count (CBC)   Rs. 1,200.00
2. Liver Function Test (LFT)    Rs. 2,500.00
3. Fasting Blood Sugar          Rs. 500.00

----------------------------------------
Subtotal:          Rs. 4,200.00
Discount:          Rs. 700.00
Total Payable:     Rs. 3,500.00
Payment Method:    Cash
''';

      final result = aiService.parseReceiptTextLocally(medicalReceiptText);

      expect(result['merchantName'], contains('CHUGHTAI LAB'));
      expect(result['category'], equals('Healthcare'));
      expect(result['subtotal'], equals(4200.0));
      expect(result['discount'], equals(700.0));
      expect(result['total'], equals(3500.0));
      expect(result['items'].length, equals(3));
      expect(result['items'][0]['name'], contains('Complete Blood Count'));
      expect(result['items'][0]['price'], equals(1200.0));
    });

    test('2. Supermarket / Grocery Receipt Extraction', () {
      const groceryReceiptText = '''
AL-FATAH SUPERMARKET
DHA Phase 5, Lahore
Invoice: AF-99381
Date: 2026-07-24

1x Milk 1L              180.00
2x Bread Large          320.00
1x Olper Cream          150.00
5x Eggs Box             600.00

Subtotal:              1250.00
Tax (5%):                62.50
Grand Total:           1312.50
Payment: Card
''';

      final result = aiService.parseReceiptTextLocally(groceryReceiptText);

      expect(result['merchantName'], equals('AL-FATAH SUPERMARKET'));
      expect(result['category'], equals('Groceries'));
      expect(result['subtotal'], equals(1250.0));
      expect(result['tax'], equals(62.5));
      expect(result['total'], equals(1312.5));
      expect(result['items'].length, equals(4));
      expect(result['items'][1]['name'], equals('Bread Large'));
      expect(result['items'][1]['quantity'], equals(2));
      expect(result['items'][1]['price'], equals(320.0));
    });

    test('3. Coffee Shop Receipt Extraction (User Image Case)', () {
      const coffeeReceiptText = '''
2847 Madison Avenue
New York, NY 10017
(212) 555-0142
10/25/2025, 8:47:03 AM

Order #: 10847
Cashier: Sarah M.
Register: 3

1 Grande Latte \$5.25
+ Oat Milk \$0.50
+ Extra Shot \$1.20
1 Blueberry Muffin \$3.00
1 Americano (Tall) \$3.90

Subtotal \$10.94
Tax \$2.91
Total \$13.85

Bank Card **** **** **** 1234
Entry Mode Swiped
Card Type Visa
''';

      final result = aiService.parseReceiptTextLocally(coffeeReceiptText);

      expect(result['receiptNumber'], equals('10847'));
      expect(result['currency'], equals('\$'));
      expect(result['subtotal'], equals(10.94));
      expect(result['tax'], equals(2.91));
      expect(result['total'], equals(13.85));
      expect(result['items'].length, equals(5));
      expect(result['items'][0]['name'], equals('Grande Latte'));
      expect(result['items'][0]['price'], equals(5.25));
      expect(result['items'][1]['name'], equals('Oat Milk'));
      expect(result['items'][1]['price'], equals(0.50));
      expect(result['items'][2]['name'], equals('Extra Shot'));
      expect(result['items'][2]['price'], equals(1.20));
      expect(result['items'][3]['name'], equals('Blueberry Muffin'));
      expect(result['items'][3]['price'], equals(3.00));
      expect(result['items'][4]['name'], equals('Americano (Tall)'));
      expect(result['items'][4]['price'], equals(3.90));
    });

    test('4. Kmart Australia Receipt Extraction (Dot-thousands & Typos)', () {
      const kmartReceiptText = '''
Kmart Australia Ltd
ABN 73 004 700 485
Shop 48-49, Westfield Doncaster
619 Doncaster Rd, Doncaster.VIC

Date: 08/04/2025 11:18
Operator: Mia L

Item Descriction                \$
Limited Edition Chihuahua    \$1.997.00
SKU: 933545678901
Melissa Mitchell Ltd, Ed. A    \$19.95
SKU: 932045678902
Reese's Peanut Butter Cups 3    \$3.95
SKU: 930061425678

Subtptal                    \$2.020.90
GST Included                   183.80
Total                       \$2.020.90
Paid via EFTPOS VISA
Card Type XXXX XXXX XXX 2027
''';

      final result = aiService.parseReceiptTextLocally(kmartReceiptText);

      print('\n========================================');
      print('TEST 4: KMART AUSTRALIA RECEIPT EXTRACTION');
      print('========================================');
      print('Merchant      : ${result['merchantName']}');
      print('Currency      : ${result['currency']}');
      print('Subtotal      : \$${result['subtotal']}');
      print('GST/Tax       : \$${result['tax']}');
      print('Total         : \$${result['total']}');
      print('Payment       : ${result['paymentMethod']}');
      print('Line Items (${(result['items'] as List).length}):');
      for (final item in result['items']) {
        print('  - ${item['name']} (x${item['quantity']}): \$${item['price']}');
      }

      expect(result['merchantName'], contains('Kmart Australia'));
      expect(result['currency'], equals('\$'));
      expect(result['subtotal'], equals(2020.90));
      expect(result['tax'], equals(183.80));
      expect(result['total'], equals(2020.90));
      expect(result['paymentMethod'], equals('Card'));
      expect(result['items'].length, equals(3));
      expect(result['items'][0]['name'], equals('Limited Edition Chihuahua'));
      expect(result['items'][0]['price'], equals(1997.00));
      expect(result['items'][1]['name'], equals('Melissa Mitchell Ltd, Ed. A'));
      expect(result['items'][1]['price'], equals(19.95));
      expect(result['items'][2]['name'], equals("Reese's Peanut Butter Cups 3"));
      expect(result['items'][2]['price'], equals(3.95));
    });
  });
}
