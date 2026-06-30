// providers/cart_provider.dart
import 'package:flutter/material.dart';
import 'package:medicore/models/medicine_model.dart';

class CartProvider with ChangeNotifier {
  final List<Medicine> _cartItems = [];
  final List<CartItem> _cartItemsWithQuantity = [];

  List<Medicine> get cartItems => _cartItems;
  List<CartItem> get cartItemsWithQuantity => _cartItemsWithQuantity;

  // Get cart total
  double get cartTotal {
    return _cartItems.fold(
        0.0, (total, medicine) => total + medicine.finalPrice);
  }

  // Get cart total with quantity consideration
  double get cartTotalWithQuantity {
    return _cartItemsWithQuantity.fold(
        0.0,
        (total, cartItem) =>
            total + (cartItem.medicine.finalPrice * cartItem.quantity));
  }

  // Get cart items count (simple)
  int get cartItemsCount {
    return _cartItems.length;
  }

  // Get cart items count with quantities
  int get totalItemsCount {
    return _cartItemsWithQuantity.fold(
        0, (total, cartItem) => total + cartItem.quantity);
  }

  // ==================== CART METHODS ====================

  // Simple cart methods (without quantity)
  void addToCart(Medicine medicine) {
    if (!_cartItems.contains(medicine)) {
      _cartItems.add(medicine);
      notifyListeners();
    }
  }

  void removeFromCart(Medicine medicine) {
    _cartItems.remove(medicine);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _cartItemsWithQuantity.clear();
    notifyListeners();
  }

  bool isInCart(Medicine medicine) {
    return _cartItems.any((item) => item.id == medicine.id);
  }

  // Advanced cart methods (with quantity)
  void addToCartWithQuantity(Medicine medicine, [int quantity = 1]) {
    final existingIndex = _cartItemsWithQuantity
        .indexWhere((item) => item.medicine.id == medicine.id);

    if (existingIndex != -1) {
      // Update quantity if already in cart
      _cartItemsWithQuantity[existingIndex] = CartItem(
          medicine: medicine,
          quantity: _cartItemsWithQuantity[existingIndex].quantity + quantity);
    } else {
      // Add new item to cart
      _cartItemsWithQuantity
          .add(CartItem(medicine: medicine, quantity: quantity));

      // Also add to simple cart for backward compatibility
      if (!isInCart(medicine)) {
        _cartItems.add(medicine);
      }
    }
    notifyListeners();
  }

  void updateCartItemQuantity(String medicineId, int newQuantity) {
    final existingIndex = _cartItemsWithQuantity
        .indexWhere((item) => item.medicine.id == medicineId);

    if (existingIndex != -1) {
      if (newQuantity <= 0) {
        // Remove if quantity is 0 or less
        _cartItemsWithQuantity.removeAt(existingIndex);
        _cartItems.removeWhere((item) => item.id == medicineId);
      } else {
        // Update quantity
        _cartItemsWithQuantity[existingIndex] = CartItem(
            medicine: _cartItemsWithQuantity[existingIndex].medicine,
            quantity: newQuantity);
      }
      notifyListeners();
    }
  }

  void removeFromCartById(String medicineId) {
    _cartItems.removeWhere((medicine) => medicine.id == medicineId);
    _cartItemsWithQuantity
        .removeWhere((item) => item.medicine.id == medicineId);
    notifyListeners();
  }

  int getItemQuantity(String medicineId) {
    final cartItem = _cartItemsWithQuantity.firstWhere(
        (item) => item.medicine.id == medicineId,
        orElse: () => CartItem(medicine: Medicine.empty(), quantity: 0));
    return cartItem.quantity;
  }

  // Check if cart is empty
  bool get isCartEmpty {
    return _cartItems.isEmpty && _cartItemsWithQuantity.isEmpty;
  }

  // Get cart summary
  Map<String, dynamic> get cartSummary {
    return {
      'itemCount': cartItemsCount,
      'totalItemsCount': totalItemsCount,
      'totalAmount': cartTotal,
      'totalAmountWithQuantity': cartTotalWithQuantity,
      'hasItems': !isCartEmpty,
    };
  }

  // Clear only cart (keep medicines in provider)
  void clearCartOnly() {
    _cartItems.clear();
    _cartItemsWithQuantity.clear();
    notifyListeners();
  }
}

// Cart Item model for quantity tracking
class CartItem {
  final Medicine medicine;
  int quantity;

  CartItem({
    required this.medicine,
    required this.quantity,
  });

  double get totalPrice => medicine.finalPrice * quantity;
}
