import 'item_model.dart';

class Expense {
  final String id;
  final String merchantName;
  final DateTime date;
  final double total;
  final double subtotal;
  final double tax;
  final double discount;
  final String category;
  final List<Item> items;
  final String memo;
  final String status;
  final String paymentMethod;
  final String address;
  final String phone;
  final String receiptNumber;
  final String currency;

  Expense({
    required this.id,
    required this.merchantName,
    required this.date,
    required this.total,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.category,
    required this.items,
    this.memo = '',
    this.status = 'Pending',
    this.paymentMethod = '',
    this.address = '',
    this.phone = '',
    this.receiptNumber = '',
    this.currency = '\$',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<Item> items = itemsList.map((i) => Item.fromJson(i)).toList();

    return Expense(
      id: json['id'] as String? ?? '',
      merchantName: json['merchantName'] as String? ?? 'Unknown Merchant',
      date: _safeParseDate(json['date']),
      total: _safeDouble(json['total']),
      subtotal: _safeDouble(json['subtotal']),
      tax: _safeDouble(json['tax']),
      discount: _safeDouble(json['discount']),
      category: json['category'] as String? ?? 'Other',
      items: items,
      memo: json['memo'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      paymentMethod: json['paymentMethod'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      receiptNumber: json['receiptNumber'] as String? ?? '',
      currency: json['currency'] as String? ?? '\$',
    );
  }

  static DateTime _safeParseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  static double _safeDouble(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    String str = raw.toString().trim();
    if (str.isEmpty) return 0.0;

    final dotCount = '.'.allMatches(str).length;
    if (dotCount > 1) {
      final lastDotIdx = str.lastIndexOf('.');
      final firstPart = str.substring(0, lastDotIdx).replaceAll('.', '');
      final lastPart = str.substring(lastDotIdx);
      str = '$firstPart$lastPart';
    }

    final cleaned = str.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantName': merchantName,
      'date': date.toIso8601String(),
      'total': total,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'category': category,
      'items': items.map((i) => i.toJson()).toList(),
      'memo': memo,
      'status': status,
      'paymentMethod': paymentMethod,
      'address': address,
      'phone': phone,
      'receiptNumber': receiptNumber,
      'currency': currency,
    };
  }

  Expense copyWith({
    String? id,
    String? merchantName,
    DateTime? date,
    double? total,
    double? subtotal,
    double? tax,
    double? discount,
    String? category,
    List<Item>? items,
    String? memo,
    String? status,
    String? paymentMethod,
    String? address,
    String? phone,
    String? receiptNumber,
    String? currency,
  }) {
    return Expense(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      category: category ?? this.category,
      items: items ?? this.items,
      memo: memo ?? this.memo,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      currency: currency ?? this.currency,
    );
  }
}
