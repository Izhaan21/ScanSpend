import 'item_model.dart';

class Expense {
  final String id;
  final String merchantName;
  final DateTime date;
  final double total;
  final String category;
  final List<Item> items;
  final String memo;
  final String status;

  Expense({
    required this.id,
    required this.merchantName,
    required this.date,
    required this.total,
    required this.category,
    required this.items,
    this.memo = '',
    this.status = 'Pending',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<Item> items = itemsList.map((i) => Item.fromJson(i)).toList();

    return Expense(
      id: json['id'] as String? ?? '',
      merchantName: json['merchantName'] as String? ?? 'Unknown Merchant',
      date: _safeParseDate(json['date']),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Other',
      items: items,
      memo: json['memo'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
    );
  }

  /// Safely parses an ISO date string, falling back to [DateTime.now()] on any error.
  static DateTime _safeParseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchantName': merchantName,
      'date': date.toIso8601String(),
      'total': total,
      'category': category,
      'items': items.map((i) => i.toJson()).toList(),
      'memo': memo,
      'status': status,
    };
  }

  Expense copyWith({
    String? id,
    String? merchantName,
    DateTime? date,
    double? total,
    String? category,
    List<Item>? items,
    String? memo,
    String? status,
  }) {
    return Expense(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      total: total ?? this.total,
      category: category ?? this.category,
      items: items ?? this.items,
      memo: memo ?? this.memo,
      status: status ?? this.status,
    );
  }
}
