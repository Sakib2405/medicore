// ignore_for_file: deprecated_member_use, unnecessary_to_list_in_spreads, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medicore/models/order_model.dart';
import 'package:medicore/providers/order_provider.dart';
import 'package:medicore/widgets/patient/order_status_timeline.dart';
import 'package:medicore/services/payment_service.dart';
import 'package:medicore/models/payment_model.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? _order;
  final _paymentSvc = PaymentService();

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  void _loadOrderDetails() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = orderProvider.getOrderById(widget.orderId);
    if (order != null) {
      setState(() {
        _order = order;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final order = _order!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          if (order.status == 'pending' || order.status == 'confirmed')
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => _cancelOrder(context, order.id),
              tooltip: 'Cancel Order',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            _buildOrderHeader(order),
            const SizedBox(height: 20),

            // Order Status Timeline
            OrderStatusTimeline(currentStatus: order.status),
            const SizedBox(height: 20),

            // Order Items
            _buildOrderItems(order),
            const SizedBox(height: 20),

            // Order Summary
            _buildOrderSummary(order),
            const SizedBox(height: 20),

            // Shipping Information
            _buildShippingInfo(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getStatusColor(order.status)),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Placed on ${DateFormat('MMM dd, yyyy - hh:mm a').format(order.orderDate)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...order.items
                .map((item) => ListTile(
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                          image: item.imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(item.imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: item.imageUrl.isEmpty
                            ? const Icon(Icons.medication, color: Colors.grey)
                            : null,
                      ),
                      title: Text(item.medicineName),
                      subtitle: Text('Quantity: ${item.quantity}'),
                      trailing: Text(
                        '৳${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
                'Subtotal', '৳${order.totalAmount.toStringAsFixed(2)}'),
            _buildSummaryRow('Delivery Fee', '৳60.00'),
            const Divider(),
            _buildSummaryRow(
              'Total Amount',
              '৳${(order.totalAmount + 60.00).toStringAsFixed(2)}',
              isBold: true,
              isTotal: true,
            ),
            const SizedBox(height: 12),
            StreamBuilder<PaymentModel?>(
              stream: _paymentSvc.watchLatestPaymentForOrder(order.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final payment = snapshot.data!;
                final statusLabel = payment.status.toLowerCase() == 'successful'
                    ? 'Paid'
                    : payment.status;
                final txnId = payment.gatewayTransactionId ?? payment.id;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                        'Payment Method', payment.method.toUpperCase()),
                    _buildSummaryRow('Payment Status', statusLabel),
                    if (txnId.isNotEmpty)
                      _buildSummaryRow('Transaction ID', txnId),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfo(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Customer Name', order.userName),
            _buildInfoRow('Email', order.userEmail),
            _buildInfoRow('Phone', order.userPhone),
            _buildInfoRow('Shipping Address', order.shippingAddress),
            _buildInfoRow('Payment Method', order.paymentMethod),
            if (order.deliveryDate != null)
              _buildInfoRow(
                'Expected Delivery',
                DateFormat('MMM dd, yyyy').format(order.deliveryDate!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.blueAccent;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _cancelOrder(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final orderProvider =
                  Provider.of<OrderProvider>(context, listen: false);
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);

              final success = await orderProvider.cancelOrder(
                  orderId, authProvider.currentUser!.id);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
