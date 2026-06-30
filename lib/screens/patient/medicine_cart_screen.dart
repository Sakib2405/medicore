import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/cart_provider.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/models/order_item_model.dart';
import 'package:medicore/services/order_service.dart';
import 'package:medicore/config/routes.dart';

class MedicineCartScreen extends StatefulWidget {
  const MedicineCartScreen({super.key});

  @override
  State<MedicineCartScreen> createState() => _MedicineCartScreenState();
}

class _MedicineCartScreenState extends State<MedicineCartScreen> {
  bool _isPlacingOrder = false;

  double _calculateTotal(List<CartItem> items) {
    return items.fold<double>(0.0, (sum, i) => sum + i.totalPrice);
  }

  Future<void> _placeOrder(List<CartItem> items) async {
    if (items.isEmpty) return;
    setState(() => _isPlacingOrder = true);
    try {
      final orderService = OrderService();
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;

      final total = _calculateTotal(items);
      // Convert CartItem -> OrderItem for order service
      final orderItems = items
          .map((c) => OrderItem(
                medicineId: c.medicine.id,
                medicineName: c.medicine.name,
                price: c.medicine.finalPrice,
                quantity: c.quantity,
                imageUrl: c.medicine.imageUrl ?? '',
              ))
          .toList();

      final order = await orderService.placeOrder(
        userId: user?.id ?? 'guest',
        userName: user?.name ?? 'Guest',
        userEmail: user?.email ?? '',
        userPhone: user?.phone ?? '',
        shippingAddress: user?.address ?? 'Not provided',
        items: orderItems,
        totalAmount: total,
        paymentMethod: 'cash',
      );

      // On success, clear cart from provider and navigate
      cartProvider.clearCart();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.myOrders,
          arguments: order.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Cart'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cart = cartProvider.cartItemsWithQuantity;

          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Your cart is empty',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                    ),
                    child: const Text('Browse Medicines'),
                  )
                ],
              ),
            );
          }

          final total = _calculateTotal(cart);

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return _CartItemTile(
                      item: item,
                      onRemove: () =>
                          cartProvider.removeFromCart(item.medicine),
                      onQtyChanged: (qty) => cartProvider
                          .updateCartItemQuantity(item.medicine.id, qty),
                    );
                  },
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('৳${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isPlacingOrder
                                ? null
                                : () => cartProvider.clearCart(),
                            child: const Text('Clear Cart'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isPlacingOrder
                                ? null
                                : () => _placeOrder(cart),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _isPlacingOrder
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation(Colors.white),
                                    ),
                                  )
                                : const Text('Checkout'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final void Function(int qty) onQtyChanged;

  const _CartItemTile(
      {required this.item, required this.onRemove, required this.onQtyChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (item.medicine.imageUrl ?? '').isNotEmpty
                ? Image.network(item.medicine.imageUrl!,
                    width: 64, height: 64, fit: BoxFit.cover)
                : Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey.shade100,
                    child: Icon(Icons.medication, color: Colors.grey.shade400),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.medicine.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('৳${item.medicine.finalPrice.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(width: 12),
                    Text('Sub: ৳${item.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QtyControl(
            qty: item.quantity,
            onChanged: onQtyChanged,
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
          )
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int qty;
  final void Function(int) onChanged;
  const _QtyControl({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: qty > 1 ? () => onChanged(qty - 1) : null,
            child: Icon(Icons.remove,
                size: 18, color: qty > 1 ? Colors.black : Colors.grey.shade300),
          ),
          const SizedBox(width: 8),
          Text(qty.toString(),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => onChanged(qty + 1),
            child: Icon(Icons.add, size: 18, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
