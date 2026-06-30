// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicore/models/order_model.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final firstItemName =
        order.items.isNotEmpty ? order.items.first.medicineName : 'No items';
    final remainingItems = order.items.length - 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.medication, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$firstItemName${remainingItems > 0 ? ' (+$remainingItems more)' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.shopping_bag, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${order.items.length} items • ${order.totalQuantity} total',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Placed on',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy').format(order.orderDate),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '৳${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusInfo.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: 14, color: statusInfo.color),
          const SizedBox(width: 4),
          Text(
            statusInfo.text,
            style: TextStyle(
              color: statusInfo.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return _StatusInfo(Colors.orange, 'PENDING', Icons.pending);
      case 'confirmed':
        return _StatusInfo(Colors.blue, 'CONFIRMED', Icons.check_circle);
      case 'processing':
        return _StatusInfo(Colors.blueAccent, 'PROCESSING', Icons.settings);
      case 'shipped':
        return _StatusInfo(Colors.purple, 'SHIPPED', Icons.local_shipping);
      case 'delivered':
        return _StatusInfo(Colors.green, 'DELIVERED', Icons.verified);
      case 'cancelled':
        return _StatusInfo(Colors.red, 'CANCELLED', Icons.cancel);
      default:
        return _StatusInfo(Colors.grey, 'UNKNOWN', Icons.help);
    }
  }
}

class _StatusInfo {
  final Color color;
  final String text;
  final IconData icon;

  _StatusInfo(this.color, this.text, this.icon);
}
