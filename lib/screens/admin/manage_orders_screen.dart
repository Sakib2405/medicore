// screens/admin/manage_orders_screen.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_brace_in_string_interps, unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:medicore/services/order_service.dart';
import 'package:medicore/widgets/admin/order_card_admin.dart';
import 'package:medicore/models/order_model.dart';
import 'package:medicore/services/payment_service.dart';
import 'package:medicore/models/payment_model.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedTimeFilter = 'all';

  final List<String> _statuses = [
    'all',
    'pending',
    'confirmed',
    'shipped',
    'delivered',
    'cancelled'
  ];
  final List<String> _timeFilters = ['all', 'today', 'week'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Orders'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildFilterSection(),

          // Orders List
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: _getFilteredOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[300], size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading orders',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            color: Colors.grey[400], size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _getEmptyStateMessage(),
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderCardAdmin(
                        order: order,
                        onTap: () => _viewOrderDetails(order),
                        onUpdateStatus: () => _updateOrderStatus(order),
                        onCancel: order.status == 'pending' ||
                                order.status == 'confirmed'
                            ? () => _cancelOrder(order)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search orders by ID, customer name, or medicine...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // Filters Row
          Row(
            children: [
              // Status Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: _statuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status == 'all' ? 'All Status' : status.toUpperCase(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Time Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTimeFilter,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: _timeFilters.map((filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Text(
                        filter == 'all'
                            ? 'All Time'
                            : filter == 'today'
                                ? 'Today'
                                : 'This Week',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTimeFilter = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<List<Order>> _getFilteredOrdersStream() {
    // Always start with all orders, then filter on the client side
    Stream<List<Order>> baseStream = _orderService.getAllOrders();

    return baseStream.map((orders) {
      return orders.where((order) {
        // Status filter
        final matchesStatus = _selectedStatus == 'all' ||
            order.status.toLowerCase() == _selectedStatus.toLowerCase();

        // Time filter
        bool matchesTime = true;
        if (_selectedTimeFilter == 'today') {
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          matchesTime = order.orderDate.isAfter(startOfDay);
        } else if (_selectedTimeFilter == 'week') {
          final weekAgo = DateTime.now().subtract(const Duration(days: 7));
          matchesTime = order.orderDate.isAfter(weekAgo);
        }

        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.userEmail
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            order.status.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.items.any((item) => item.medicineName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()));

        return matchesStatus && matchesTime && matchesSearch;
      }).toList();
    });
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'No orders found for "$_searchQuery"';
    }
    if (_selectedStatus != 'all') {
      return 'No ${_selectedStatus} orders found';
    }
    if (_selectedTimeFilter != 'all') {
      return 'No orders found for ${_selectedTimeFilter == 'today' ? 'today' : 'this week'}';
    }
    return 'No orders found';
  }

  void _viewOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details - #${order.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOrderDetailRow('Customer', order.userName),
              _buildOrderDetailRow('Email', order.userEmail),
              _buildOrderDetailRow('Phone', order.userPhone),
              _buildOrderDetailRow('Address', order.shippingAddress),
              _buildOrderDetailRow('Status', order.status.toUpperCase()),
              _buildOrderDetailRow(
                  'Total', '৳${order.totalAmount.toStringAsFixed(2)}'),
              _buildOrderDetailRow(
                  'Payment', order.paymentMethod.toUpperCase()),
              const SizedBox(height: 8),
              StreamBuilder<PaymentModel?>(
                stream: _paymentService.watchLatestPaymentForOrder(order.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final payment = snapshot.data!;
                  final statusLabel =
                      payment.status.toLowerCase() == 'successful'
                          ? 'Paid'
                          : payment.status;
                  final txnId = payment.gatewayTransactionId ?? payment.id;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOrderDetailRow('Payment Status', statusLabel),
                      if (txnId.isNotEmpty)
                        _buildOrderDetailRow('Transaction ID', txnId),
                      if (payment.gateway != null)
                        _buildOrderDetailRow('Gateway', payment.gateway!),
                    ],
                  );
                },
              ),
              _buildOrderDetailRow('Date', _formatFullDate(order.orderDate)),
              const SizedBox(height: 16),
              const Text(
                'Order Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(
                                    '${item.medicineName} (x${item.quantity})')),
                            Text('৳${item.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _updateOrderStatus(Order order) {
    final statuses = ['pending', 'confirmed', 'shipped', 'delivered'];
    final currentIndex = statuses.indexWhere((s) => s == order.status);
    final nextStatus = currentIndex < statuses.length - 1
        ? statuses[currentIndex + 1]
        : statuses.last;

    // Capture the parent ScaffoldMessenger before opening dialog to avoid using a disposed context
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Text(
            'Change order status from "${order.status}" to "$nextStatus"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close the dialog using its own context
              Navigator.pop(dialogContext);
              try {
                await _orderService.updateOrderStatus(order.id, nextStatus);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Order status updated to $nextStatus'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to update status: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(Order order) {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _orderService.cancelOrder(order.id);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Order cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel order: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
