class Item {
  final String name;
  final double price;
  final int quantity;

  Item({required this.name, required this.price, this.quantity = 1});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'] as String? ?? 'Unknown Item',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  Item copyWith({
    String? name,
    double? price,
    int? quantity,
  }) {
    return Item(
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}
