class OrderItem {
  final String medicineId;
  final String medicineName;
  final double price;
  final int quantity;
  final String imageUrl;

  const OrderItem({
    required this.medicineId,
    required this.medicineName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      medicineId: map['medicineId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 1).toInt(),
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicineId': medicineId,
      'medicineName': medicineName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }

  OrderItem copyWith({
    String? medicineId,
    String? medicineName,
    double? price,
    int? quantity,
    String? imageUrl,
  }) {
    return OrderItem(
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'OrderItem(medicineId: $medicineId, medicineName: $medicineName, price: $price, quantity: $quantity)';
  }
}
