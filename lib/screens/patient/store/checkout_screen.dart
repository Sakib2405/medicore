// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/providers/cart_provider.dart';
import 'package:medicore/providers/order_provider.dart';
import 'package:medicore/models/order_item_model.dart';
import 'package:medicore/services/payment_service.dart';
import 'package:medicore/services/sslcommerz_service.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _method = PaymentMethod.cash; // default: cash
  bool _placing = false;
  String _recipientName = '';
  String _contactPhone = '';
  String _shippingAddress = 'Dhaka, Bangladesh';
  String _deliveryMethod = 'standard';
  double _shippingFee = 60.0;
  double _discountAmount = 0.0;
  final TextEditingController _promoCtrl = TextEditingController();
  String? _promoMessage;
  bool _promoValid = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      if (_recipientName.isEmpty) _recipientName = user.name;
      if (_contactPhone.isEmpty) _contactPhone = user.phone;
    }
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  // ── Totals ────────────────────────────────────────────────────────────────
  // totals are computed inline in Builder widgets to stay reactive

  // ── Promo ─────────────────────────────────────────────────────────────────
  void _applyPromo() {
    final code = _promoCtrl.text.trim().toUpperCase();
    if (code == 'SAVE5') {
      setState(() {
        _discountAmount = (context.read<CartProvider>().cartTotalWithQuantity * .05).clamp(0, 300);
        _promoMessage = '5% discount applied (max ৳300)';
        _promoValid = true;
      });
    } else if (code == 'FREESHIP') {
      setState(() {
        _shippingFee = 0;
        _promoMessage = 'Free shipping applied!';
        _promoValid = true;
      });
    } else {
      setState(() {
        _discountAmount = 0;
        _promoMessage = code.isEmpty ? 'Enter a promo code' : 'Invalid code';
        _promoValid = false;
      });
    }
  }

  // ── Confirm order ─────────────────────────────────────────────────────────
  Future<void> _confirmOrder() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();

    if (cart.isCartEmpty) {
      _snack('Your cart is empty', error: true);
      return;
    }
    final user = auth.currentUser;
    if (user == null) {
      _snack('Please log in to place an order', error: true);
      return;
    }
    if (_shippingAddress.trim().isEmpty) {
      _snack('Please enter a shipping address', error: true);
      return;
    }

    setState(() => _placing = true);

    try {
      final items = cart.cartItemsWithQuantity
          .map((ci) => OrderItem(
                medicineId: ci.medicine.id,
                medicineName: ci.medicine.name,
                price: ci.medicine.finalPrice,
                quantity: ci.quantity,
                imageUrl: ci.medicine.imageUrl ?? '',
              ))
          .toList();

      final subtotal = cart.cartTotalWithQuantity;
      final discount = _discountAmount.clamp(0.0, subtotal);
      final shipping = subtotal > 0 ? _shippingFee : 0.0;
      final total = subtotal - discount + shipping;

      // ── Online payment: launch SSL gateway BEFORE placing order ───────────
      PaymentGatewayResult? gatewayResult;
      if (_method != PaymentMethod.cash) {
        final svc = PaymentService();
        gatewayResult = await svc.startSslPayment(
          context: context,
          amount: total,
          method: _method,
          customerName: user.name,
          customerEmail: user.email,
          customerPhone: _contactPhone.trim().isEmpty
              ? user.phone
              : _contactPhone.trim(),
          shippingAddress: _shippingAddress,
        );

        if (gatewayResult == null || !gatewayResult.success) {
          _snack(
            (gatewayResult?.status ?? 'cancelled') == 'cancelled'
                ? 'Payment was cancelled'
                : 'Payment failed. Please try again.',
            error: true,
          );
          setState(() => _placing = false);
          return;
        }
      }

      // ── Place order in Firestore ──────────────────────────────────────────
      final success = await orders.placeOrder(
        userId: user.id,
        userName: user.name,
        userEmail: user.email,
        userPhone: _contactPhone.trim().isEmpty ? user.phone : _contactPhone.trim(),
        shippingAddress: _shippingAddress,
        items: items,
        totalAmount: total,
        paymentMethod: _method.name,
      );

      if (!success) {
        _snack(orders.errorMessage ?? 'Failed to place order', error: true);
        setState(() => _placing = false);
        return;
      }

      // ── Save payment record AFTER order exists in Firestore ───────────────
      final newOrderId = orders.latestOrder?.id;
      if (newOrderId != null) {
        final svc = PaymentService();
        if (_method == PaymentMethod.cash) {
          await svc.markCashPayment(orderId: newOrderId, amount: total);
        } else if (gatewayResult != null) {
          await svc.saveSuccessfulPayment(
            tranId: gatewayResult.tranId,
            orderId: newOrderId,
            amount: total,
            method: _method,
            bankTranId: gatewayResult.bankTranId,
          );
        }
      }

      orders.subscribeToUserOrders(user.id);
      cart.clearCart();

      if (!mounted) return;
      await _showSuccessDialog(total);
    } catch (e) {
      _snack('Error: ${e.toString().replaceAll('Exception: ', '')}',
          error: true);
      setState(() => _placing = false);
    }
  }

  Future<void> _showSuccessDialog(double total) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child:
                  Icon(Icons.check_rounded, color: Colors.green.shade600, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Order Placed!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _method == PaymentMethod.cash
                  ? 'Your order of ৳${total.toStringAsFixed(0)} will be paid on delivery.'
                  : 'Payment of ৳${total.toStringAsFixed(0)} confirmed!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.myOrders,
                    (r) => r.settings.name == Routes.patientHome,
                  );
                },
                child: const Text('View My Orders',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
    ));
  }

  // ── Address editor ────────────────────────────────────────────────────────
  Future<void> _editAddress() async {
    final nameCtrl = TextEditingController(text: _recipientName);
    final phoneCtrl = TextEditingController(text: _contactPhone);
    final addrCtrl = TextEditingController(text: _shippingAddress);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Shipping Details',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          VoiceTextField(
              controller: nameCtrl,
              labelText: 'Recipient Name',
              decoration: const InputDecoration(
                  labelText: 'Recipient Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          VoiceTextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone Number', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          VoiceTextField(
              controller: addrCtrl,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Full Address',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                setState(() {
                  _recipientName = nameCtrl.text.trim();
                  _contactPhone = phoneCtrl.text.trim();
                  _shippingAddress = addrCtrl.text.trim();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Shipping address ──────────────────────────────────────────────
          _Section(
            icon: Icons.location_on_rounded,
            iconColor: Colors.blue.shade600,
            title: 'Delivery Address',
            trailing: TextButton(
              onPressed: _editAddress,
              child: const Text('Edit'),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_recipientName.isEmpty ? 'Tap Edit to add name' : _recipientName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 4),
              Text(_shippingAddress,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              if (_contactPhone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(_contactPhone,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          // ── Delivery method ───────────────────────────────────────────────
          _Section(
            icon: Icons.local_shipping_rounded,
            iconColor: Colors.orange.shade600,
            title: 'Delivery Method',
            child: Row(children: [
              _DeliveryChip(
                label: 'Standard',
                sublabel: '৳60 • 3-5 days',
                selected: _deliveryMethod == 'standard',
                onTap: () => setState(() {
                  _deliveryMethod = 'standard';
                  if (_promoMessage != 'Free shipping applied!') _shippingFee = 60;
                }),
              ),
              const SizedBox(width: 10),
              _DeliveryChip(
                label: 'Express',
                sublabel: '৳120 • 1-2 days',
                selected: _deliveryMethod == 'express',
                onTap: () => setState(() {
                  _deliveryMethod = 'express';
                  if (_promoMessage != 'Free shipping applied!') _shippingFee = 120;
                }),
              ),
            ]),
          ),
          const SizedBox(height: 12),

          // ── Cart items ────────────────────────────────────────────────────
          _Section(
            icon: Icons.shopping_bag_rounded,
            iconColor: Colors.green.shade600,
            title: 'Items',
            child: Consumer<CartProvider>(
              builder: (_, cart, __) {
                final items = cart.cartItemsWithQuantity;
                if (items.isEmpty) {
                  return Text('Cart is empty',
                      style: TextStyle(color: Colors.grey.shade500));
                }
                return Column(
                  children: items
                      .map((ci) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.local_pharmacy,
                                    color: Colors.green.shade600, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(ci.medicine.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13)),
                                      Text(
                                          '৳${ci.medicine.finalPrice.toStringAsFixed(0)} × ${ci.quantity}',
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12)),
                                    ]),
                              ),
                              Text(
                                  '৳${(ci.medicine.finalPrice * ci.quantity).toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ]),
                          ))
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // ── Payment method ────────────────────────────────────────────────
          _Section(
            icon: Icons.payment_rounded,
            iconColor: Colors.purple.shade600,
            title: 'Payment Method',
            child: Column(
              children: [
                _PaymentTile(
                  method: PaymentMethod.cash,
                  selected: _method == PaymentMethod.cash,
                  label: 'Cash on Delivery',
                  sublabel: 'Pay when your order arrives',
                  icon: Icons.money_rounded,
                  color: Colors.green.shade600,
                  onTap: () => setState(() => _method = PaymentMethod.cash),
                ),
                const SizedBox(height: 8),
                _PaymentTile(
                  method: PaymentMethod.online,
                  selected: _method == PaymentMethod.online,
                  label: 'Online Payment',
                  sublabel: 'bKash, Nagad, Rocket, Card & more',
                  icon: Icons.credit_card_rounded,
                  color: Colors.blue.shade700,
                  onTap: () => setState(() => _method = PaymentMethod.online),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Promo code ────────────────────────────────────────────────────
          _Section(
            icon: Icons.local_offer_rounded,
            iconColor: Colors.red.shade500,
            title: 'Promo Code',
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _promoCtrl,
                    decoration: InputDecoration(
                      hintText: 'SAVE5 or FREESHIP',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: _applyPromo,
                  child: const Text('Apply'),
                ),
              ]),
              if (_promoMessage != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(
                    _promoValid ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: _promoValid ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(_promoMessage!,
                      style: TextStyle(
                          color: _promoValid
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontSize: 13)),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 12),

          // ── Order summary ─────────────────────────────────────────────────
          _Section(
            icon: Icons.receipt_long_rounded,
            iconColor: Colors.teal.shade600,
            title: 'Order Summary',
            child: Consumer<CartProvider>(builder: (_, cart, __) {
              final subtotal = cart.cartTotalWithQuantity;
              final discount = _discountAmount.clamp(0.0, subtotal);
              final shipping = subtotal > 0 ? _shippingFee : 0.0;
              final total = subtotal - discount + shipping;
              return Column(children: [
                _SummaryRow('Subtotal', '৳${subtotal.toStringAsFixed(0)}'),
                if (discount > 0)
                  _SummaryRow('Discount', '-৳${discount.toStringAsFixed(0)}',
                      valueColor: Colors.green.shade600),
                _SummaryRow(
                    '${_deliveryMethod == 'express' ? 'Express' : 'Standard'} Shipping',
                    shipping == 0 ? 'FREE' : '৳${shipping.toStringAsFixed(0)}',
                    valueColor: shipping == 0 ? Colors.green.shade600 : null),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider()),
                _SummaryRow('Total', '৳${total.toStringAsFixed(0)}',
                    bold: true, valueColor: Colors.blue.shade700),
              ]);
            }),
          ),

          const SizedBox(height: 100), // space for bottom bar
        ]),
      ),

      // ── Bottom confirm bar ─────────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Consumer<CartProvider>(builder: (_, cart, __) {
          final subtotal = cart.cartTotalWithQuantity;
          final discount = _discountAmount.clamp(0.0, subtotal);
          final shipping = subtotal > 0 ? _shippingFee : 0.0;
          final total = subtotal - discount + shipping;

          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4)),
              ],
            ),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Total', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                Text('৳${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _placing ? null : _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _method == PaymentMethod.cash
                        ? Colors.green.shade600
                        : Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _placing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(
                            _method == PaymentMethod.cash
                                ? Icons.money_rounded
                                : Icons.lock_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _method == PaymentMethod.cash
                                ? 'Place Order'
                                : 'Pay Now',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ]),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 10),
            Text(title,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            if (trailing != null) ...[const Spacer(), trailing!],
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      ),
    );
  }
}

// ── Payment tile ──────────────────────────────────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.07) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected ? color : Colors.black87)),
              Text(sublabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color : Colors.transparent,
              border: Border.all(
                  color: selected ? color : Colors.grey.shade400, width: 2),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ── Delivery chip ─────────────────────────────────────────────────────────────
class _DeliveryChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryChip({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? Colors.orange.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? Colors.orange.shade400 : Colors.grey.shade200,
                width: selected ? 1.8 : 1),
          ),
          child: Column(children: [
            Icon(Icons.local_shipping_rounded,
                color: selected ? Colors.orange.shade600 : Colors.grey.shade400,
                size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color:
                        selected ? Colors.orange.shade700 : Colors.grey.shade700)),
            Text(sublabel,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ),
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SummaryRow(this.label, this.value,
      {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: bold ? 15 : 13,
                  color: bold ? Colors.black87 : Colors.grey.shade600)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  fontSize: bold ? 15 : 13,
                  color: valueColor ?? (bold ? Colors.black87 : Colors.grey.shade700))),
        ],
      ),
    );
  }
}
