// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_to_list_in_spreads, unused_import

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/medicine_provider.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/providers/order_provider.dart';
import 'package:medicore/providers/cart_provider.dart';
import 'package:medicore/models/medicine_model.dart';
import 'package:medicore/models/order_item_model.dart';
import 'package:medicore/services/order_service.dart';
import 'package:medicore/services/payment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicineCartScreen extends StatelessWidget {
  const MedicineCartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.cartItems.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _showClearCartDialog(context, cartProvider),
                tooltip: 'Clear Cart',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.cartItems.isEmpty) {
              return _buildEmptyCart(context);
            }

            return Column(
              children: [
                // Cart Items Count
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.shade50,
                  child: Row(
                    children: [
                      const Icon(Icons.shopping_cart,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '${cartProvider.cartItems.length} ${cartProvider.cartItems.length == 1 ? 'item' : 'items'} in cart',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) {
                      final medicine = cartProvider.cartItems[index];
                      return _buildCartItem(medicine, context, cartProvider)
                          .animate(delay: (index * 40).ms)
                          .fadeIn(duration: 250.ms)
                          .slideY(
                              begin: 0.05,
                              end: 0,
                              duration: 250.ms,
                              curve: Curves.easeOut);
                    },
                  ),
                ),
                // Total and Checkout Section
                _buildCheckoutSection(context, cartProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse our medicine store and add items to your cart',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.medication),
            label: const Text('Browse Medicines'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
      Medicine medicine, BuildContext context, CartProvider cartProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Medicine Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        medicine.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.medication,
                                color: Colors.grey, size: 30),
                          );
                        },
                      ),
                    )
                  : const Icon(Icons.medication, color: Colors.grey, size: 30),
            ),
            const SizedBox(width: 12),

            // Medicine Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medicine.brand,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '৳${medicine.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      if (medicine.hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          '৳${medicine.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${medicine.discountPercentage.round()}% OFF',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (medicine.isOutOfStock) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Out of Stock',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Remove Button
            IconButton(
              onPressed: () {
                cartProvider.removeFromCart(medicine);
                _showRemovedSnackbar(context, medicine.name);
              },
              icon: Icon(
                Icons.remove_circle_outline,
                color: Colors.red.shade600,
                size: 28,
              ),
              tooltip: 'Remove from cart',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSection(
      BuildContext context, CartProvider cartProvider) {
    final hasOutOfStockItems =
        cartProvider.cartItems.any((medicine) => medicine.isOutOfStock);
    final deliveryCharge = 60.00;
    final totalWithDelivery = cartProvider.cartTotal + deliveryCharge;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Colors.grey, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Order Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Items:', style: TextStyle(fontSize: 14)),
                    Text('${cartProvider.cartItems.length}',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontSize: 14)),
                    Text('৳${cartProvider.cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery:', style: TextStyle(fontSize: 14)),
                    Text('৳${deliveryCharge.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '৳${totalWithDelivery.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Out of Stock Warning
          if (hasOutOfStockItems) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Some items are out of stock. Please remove them to proceed.',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Checkout Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: hasOutOfStockItems ? null : () => _checkout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasOutOfStockItems ? Colors.grey : Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Continue Shopping Button
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  void _checkout(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Removed unused OrderProvider to avoid deactivated context and lints

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to place order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (cartProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for out of stock items
    final outOfStockItems = cartProvider.cartItems
        .where((medicine) => medicine.isOutOfStock)
        .toList();
    if (outOfStockItems.isNotEmpty) {
      _showOutOfStockDialog(context, outOfStockItems, cartProvider);
      return;
    }

    // Ask for shipping address, then confirm
    final messenger = ScaffoldMessenger.of(context);
    final initialAddress = authProvider.currentUser?.address ?? '';
    _askShippingAddress(context, initialAddress).then((address) {
      if (address == null || address.trim().isEmpty) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Confirm Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please review your order:'),
                const SizedBox(height: 12),
                Text('Items: ${cartProvider.cartItems.length}'),
                Text('Subtotal: ৳${cartProvider.cartTotal.toStringAsFixed(2)}'),
                const Text('Delivery: ৳60.00'),
                Text(
                    'Total: ৳${(cartProvider.cartTotal + 60.00).toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                const Text('Shipping Address:'),
                Text(address,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Choose your payment method:'),
                const SizedBox(height: 8),
                Center(
                  child: Image.network(
                    'https://cloudcampus24.com/assets/img/partners/ssl-commerz.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _placeOrder(
                  context,
                  cartProvider,
                  authProvider,
                  payOnline: false,
                  messenger: messenger,
                  shippingAddress: address,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Cash on Delivery'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final method = await _selectPaymentMethod(context);
                if (method == null) return;
                await _placeOrder(
                  context,
                  cartProvider,
                  authProvider,
                  payOnline: true,
                  messenger: messenger,
                  shippingAddress: address,
                  selectedMethod: method,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Pay Online'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _placeOrder(
    BuildContext context,
    CartProvider cartProvider,
    AuthProvider authProvider, {
    required bool payOnline,
    required ScaffoldMessengerState messenger,
    String? shippingAddress,
    PaymentMethod? selectedMethod,
  }) async {
    try {
      final user = authProvider.currentUser!;
      final cartItems = cartProvider.cartItems;

      // Convert cart items to order items
      final orderItems = cartItems
          .map((medicine) => OrderItem(
                medicineId: medicine.id,
                medicineName: medicine.name,
                price: medicine.finalPrice,
                quantity: 1,
                imageUrl: medicine.imageUrl ?? '',
              ))
          .toList();

      if (payOnline) {
        // First take payment; only create order if payment succeeds
        final paymentService = PaymentService();
        final tempOrderId = 'TEMP_${DateTime.now().millisecondsSinceEpoch}';
        final onlinePayment = await paymentService.processSslPayment(
          context: context,
          orderId: tempOrderId,
          amount: cartProvider.cartTotal + 60.0,
          method: selectedMethod ?? PaymentMethod.bkash,
          customerName: user.name,
          customerEmail: user.email,
          customerPhone: user.phone,
          shippingAddress: shippingAddress,
        );

        if (onlinePayment.status == 'successful') {
          final order = await OrderService().placeOrder(
            userId: user.id,
            userName: user.name,
            userEmail: user.email,
            userPhone: user.phone,
            shippingAddress:
                (shippingAddress == null || shippingAddress.trim().isEmpty)
                    ? 'Dhaka, Bangladesh'
                    : shippingAddress.trim(),
            items: orderItems,
            totalAmount: cartProvider.cartTotal + 60.0,
            paymentMethod: 'online',
          );

          // Link the payment to the real order id
          try {
            await FirebaseFirestore.instance
                .collection('payments')
                .doc(onlinePayment.id)
                .update({'orderId': order.id});
          } catch (_) {}

          await OrderService().updateOrderStatus(order.id, 'confirmed');
          cartProvider.clearCart();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Order confirmed.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Payment failed or cancelled.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Cash on delivery: create order first, then record pending cash payment
        final order = await OrderService().placeOrder(
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
          userPhone: user.phone,
          shippingAddress:
              (shippingAddress == null || shippingAddress.trim().isEmpty)
                  ? 'Dhaka, Bangladesh'
                  : shippingAddress.trim(),
          items: orderItems,
          totalAmount: cartProvider.cartTotal + 60.0,
          paymentMethod: 'cash',
        );
        await PaymentService().markCashPayment(
          orderId: order.id,
          amount: order.totalAmount,
        );
        cartProvider.clearCart();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Order placed (Cash on Delivery).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error placing order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<PaymentMethod?> _selectPaymentMethod(BuildContext context) async {
    return showModalBottomSheet<PaymentMethod>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.pink),
                title: const Text('bKash'),
                onTap: () => Navigator.pop(ctx, PaymentMethod.bkash),
              ),
              ListTile(
                leading: const Icon(Icons.payments_rounded,
                    color: Colors.deepOrange),
                title: const Text('Nagad'),
                onTap: () => Navigator.pop(ctx, PaymentMethod.nagad),
              ),
              ListTile(
                leading:
                    const Icon(Icons.swap_horiz_rounded, color: Colors.blue),
                title: const Text('Rocket'),
                onTap: () => Navigator.pop(ctx, PaymentMethod.rocket),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _askShippingAddress(
      BuildContext context, String initial) async {
    final controller = TextEditingController(text: initial);
    String? result;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Shipping Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide your delivery address'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'House, Road, Area, City',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                Navigator.pop(dialogContext);
                return;
              }
              result = controller.text.trim();
              Navigator.pop(dialogContext);
            },
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
    return result;
  }

  void _showClearCartDialog(BuildContext context, CartProvider cartProvider) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text(
            'Are you sure you want to remove all items from your cart? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              cartProvider.clearCart();
              Navigator.pop(dialogContext);
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Clear Cart'),
          ),
        ],
      ),
    );
  }

  void _showOutOfStockDialog(BuildContext context,
      List<Medicine> outOfStockItems, CartProvider cartProvider) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Out of Stock Items'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following items are currently out of stock:'),
              const SizedBox(height: 12),
              ...outOfStockItems
                  .map((medicine) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• ${medicine.name}',
                          style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500),
                        ),
                      ))
                  .toList(),
              const SizedBox(height: 12),
              const Text(
                  'Please remove them from your cart to continue with checkout.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Remove all out of stock items
              for (final medicine in outOfStockItems) {
                cartProvider.removeFromCart(medicine);
              }
              Navigator.pop(dialogContext);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                      'Removed ${outOfStockItems.length} out of stock items'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('Remove Out of Stock'),
          ),
        ],
      ),
    );
  }

  void _showRemovedSnackbar(BuildContext context, String medicineName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$medicineName removed from cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Note: Undo functionality would require storing the removed item
          },
        ),
      ),
    );
  }
}
