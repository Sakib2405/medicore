class CartItemModel {
  final String id; // This is usually the medicineId
  final String name;
  final double price;
  int quantity;

  CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get totalPrice => price * quantity;
}
