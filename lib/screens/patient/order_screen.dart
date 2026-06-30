// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicore/models/order_model.dart';
import 'package:medicore/models/order_item_model.dart';
import 'package:medicore/providers/order_provider.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/services/payment_service.dart';
import 'package:medicore/models/payment_model.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  final _paymentSvc = PaymentService();
  late final TabController _tabController;

  static const _tabs = ['All', 'Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];

  static const _gradColors = [Color(0xFF4776E6), Color(0xFF8E54E9)];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final orders = context.read<OrderProvider>();
      if (auth.currentUser != null) {
        orders.subscribeToUserOrders(auth.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Order> _filtered(OrderProvider prov, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return prov.orders;
      case 1:
        return prov.pendingOrders;
      case 2:
        return prov.confirmedOrders;
      case 3:
        return prov.shippedOrders;
      case 4:
        return prov.deliveredOrders;
      case 5:
        return prov.cancelledOrders;
      default:
        return prov.orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Consumer2<AuthProvider, OrderProvider>(
        builder: (context, auth, orderProv, _) {
          if (auth.currentUser == null) {
            return _buildNotLoggedIn();
          }

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              _buildSliverAppBar(orderProv),
            ],
            body: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(_tabs.length, (i) {
                      if (orderProv.isLoading && orderProv.orders.isEmpty) {
                        return _buildLoading();
                      }
                      final list = _filtered(orderProv, i);
                      if (list.isEmpty) return _buildEmpty(i);
                      return _buildList(list, orderProv, auth);
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────
  Widget _buildSliverAppBar(OrderProvider prov) {
    final stats = prov.orderStatistics;
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: _gradColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(width: 8),
                      Text('My Orders',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _statChip('Total', '${stats['total']}'),
                      const SizedBox(width: 10),
                      _statChip('Pending', '${stats['pending']}',
                          color: Colors.orange.shade300),
                      const SizedBox(width: 10),
                      _statChip('Delivered', '${stats['delivered']}',
                          color: Colors.green.shade300),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
        ],
      ),
    );
  }

  // ─── Tab bar ──────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: const Color(0xFF4776E6),
        unselectedLabelColor: Colors.grey.shade500,
        indicatorColor: const Color(0xFF4776E6),
        indicatorWeight: 3,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  // ─── List ─────────────────────────────────────────────
  Widget _buildList(List<Order> orders, OrderProvider prov, AuthProvider auth) {
    return RefreshIndicator(
      onRefresh: () async {
        if (auth.currentUser != null) {
          prov.subscribeToUserOrders(auth.currentUser!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        itemCount: orders.length,
        itemBuilder: (_, i) =>
            _OrderCard(order: orders[i], onTap: () => _showDetail(orders[i])),
      ),
    );
  }

  // ─── States ───────────────────────────────────────────
  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildEmpty(int tabIndex) {
    final isAll = tabIndex == 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4776E6).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAll
                  ? Icons.shopping_bag_outlined
                  : Icons.inbox_outlined,
              size: 48,
              color: const Color(0xFF4776E6).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isAll ? 'No Orders Yet' : 'No ${_tabs[tabIndex]} Orders',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            isAll
                ? 'Your order history will appear here'
                : 'No orders with this status',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          if (isAll) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.medication_rounded),
              label: const Text('Browse Medicines'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4776E6),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Please Login',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Login to view your orders'),
          ],
        ),
      );

  // ─── Order detail bottom sheet ────────────────────────
  void _showDetail(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrderDetailSheet(
        order: order,
        paymentSvc: _paymentSvc,
      ),
    );
  }
}

// ─────────────────── Order Card ───────────────────────
class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  static const _statusConfig = {
    'pending': (Colors.orange, Icons.hourglass_empty_rounded),
    'confirmed': (Colors.blue, Icons.check_circle_outline_rounded),
    'shipped': (Colors.purple, Icons.local_shipping_rounded),
    'delivered': (Colors.green, Icons.done_all_rounded),
    'cancelled': (Colors.red, Icons.cancel_outlined),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _statusConfig[order.status];
    final statusColor = cfg?.$1 ?? Colors.grey;
    final statusIcon = cfg?.$2 ?? Icons.help_outline;
    final date = order.orderDate;
    final dateStr =
        '${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(dateStr,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status[0].toUpperCase() +
                          order.status.substring(1),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Items preview
              ...order.items.take(2).map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4776E6)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(item.imageUrl,
                                      fit: BoxFit.cover),
                                )
                              : const Icon(Icons.medication_rounded,
                                  size: 18, color: Color(0xFF4776E6)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${item.medicineName}  ×${item.quantity}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '৳${(item.price * item.quantity).toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
              if (order.items.length > 2)
                Text('+${order.items.length - 2} more item(s)',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400)),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.paymentMethod.toUpperCase()} · ${order.totalQuantity} item${order.totalQuantity == 1 ? '' : 's'}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                  Text(
                    '৳${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4776E6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Order Detail Sheet ───────────────
class _OrderDetailSheet extends StatefulWidget {
  final Order order;
  final PaymentService paymentSvc;

  const _OrderDetailSheet(
      {required this.order, required this.paymentSvc});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  bool _cancelling = false;

  bool get _isCancelable {
    final diff = DateTime.now().difference(widget.order.orderDate);
    return diff <= const Duration(minutes: 30) &&
        !['shipped', 'delivered', 'cancelled'].contains(widget.order.status);
  }

  int get _minutesLeft {
    final deadline =
        widget.order.orderDate.add(const Duration(minutes: 30));
    final left = deadline.difference(DateTime.now());
    return left.isNegative ? 0 : left.inMinutes + (left.inSeconds % 60 > 0 ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${o.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _formatDate(o.orderDate),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusTimeline(o.status),
                  const SizedBox(height: 20),
                  _sectionHeader('Items'),
                  const SizedBox(height: 10),
                  ...o.items.map(_buildItem),
                  const SizedBox(height: 16),
                  _sectionHeader('Order Summary'),
                  const SizedBox(height: 10),
                  _buildSummary(o),
                  const SizedBox(height: 16),
                  _sectionHeader('Shipping Info'),
                  const SizedBox(height: 10),
                  _buildShippingInfo(o),
                  const SizedBox(height: 16),
                  if (_isCancelable) _buildCancelSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800));

  Widget _buildStatusTimeline(String status) {
    final steps = ['pending', 'confirmed', 'shipped', 'delivered'];
    final isCancelled = status == 'cancelled';
    final currentStep = isCancelled ? -1 : steps.indexOf(status);

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel_rounded, color: Colors.red.shade600),
            const SizedBox(width: 10),
            const Text('This order has been cancelled.',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final done = stepIndex < currentStep;
          return Expanded(
            child: Container(
              height: 3,
              color: done
                  ? const Color(0xFF4776E6)
                  : Colors.grey.shade200,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final done = stepIndex <= currentStep;
        final labels = ['Ordered', 'Confirmed', 'Shipped', 'Delivered'];
        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? const Color(0xFF4776E6)
                    : Colors.grey.shade200,
              ),
              child: Icon(
                done
                    ? Icons.check_rounded
                    : Icons.circle_outlined,
                color: done ? Colors.white : Colors.grey.shade400,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(labels[stepIndex],
                style: TextStyle(
                    fontSize: 9,
                    color: done
                        ? const Color(0xFF4776E6)
                        : Colors.grey.shade400,
                    fontWeight:
                        done ? FontWeight.w700 : FontWeight.w500)),
          ],
        );
      }),
    );
  }

  Widget _buildItem(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: item.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(item.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.medication_rounded,
                            color: Color(0xFF4776E6))),
                  )
                : const Icon(Icons.medication_rounded,
                    color: Color(0xFF4776E6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.medicineName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Qty: ${item.quantity}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text('৳${(item.price * item.quantity).toStringAsFixed(0)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF4776E6))),
        ],
      ),
    );
  }

  Widget _buildSummary(Order o) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '৳${o.totalAmount.toStringAsFixed(0)}'),
          _summaryRow('Payment', o.paymentMethod.toUpperCase()),
          _summaryRow('Status', o.status[0].toUpperCase() + o.status.substring(1)),
          if (o.deliveryDate != null)
            _summaryRow('Delivered On', _formatDate(o.deliveryDate!)),
          const Divider(height: 20),
          _summaryRow('Total', '৳${o.totalAmount.toStringAsFixed(0)}',
              bold: true),
          // Live payment record
          StreamBuilder<PaymentModel?>(
            stream: widget.paymentSvc.watchLatestPaymentForOrder(o.id),
            builder: (_, snap) {
              final payment = snap.data;
              if (payment == null) return const SizedBox.shrink();
              final statusLabel = payment.status.toLowerCase() == 'successful'
                  ? 'Paid ✓'
                  : payment.status;
              return Column(children: [
                const SizedBox(height: 4),
                _summaryRow('Payment Status', statusLabel,
                    valueColor: Colors.green.shade700),
                if ((payment.gatewayTransactionId ?? '').isNotEmpty)
                  _summaryRow(
                      'Transaction ID', payment.gatewayTransactionId!),
              ]);
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildShippingInfo(Order o) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.person_rounded,
                size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(o.userName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ]),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.location_on_rounded,
                size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(o.shippingAddress,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600)),
            ),
          ]),
          if (o.userPhone.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.phone_rounded,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(o.userPhone,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.timer_rounded, color: Colors.red.shade600, size: 16),
            const SizedBox(width: 6),
            Text('Cancel within ${_minutesLeft}m',
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _cancelling ? null : _cancelOrder,
              icon: _cancelling
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red.shade600),
                    )
                  : const Icon(Icons.cancel_rounded),
              label: const Text('Cancel Order'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Cancel Order?'),
        content:
            const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _cancelling = true);

    final auth = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    final ok = await orders.cancelOrder(widget.order.id, userId);

    if (!mounted) return;
    setState(() => _cancelling = false);

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orders.errorMessage ?? 'Failed to cancel order'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
