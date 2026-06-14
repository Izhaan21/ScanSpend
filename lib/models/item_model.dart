class Item {
  final String name;
  final double price;

  Item({required this.name, required this.price});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      name: json['name'] as String? ?? 'Unknown Item',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }

  Item copyWith({
    String? name,
    double? price,
  }) {
    return Item(
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }
}
