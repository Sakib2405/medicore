// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String currentStatus;

  const OrderStatusTimeline({super.key, required this.currentStatus});

  @override
  Widget build(BuildContext context) {
    final statuses = [
      _StatusItem('pending', 'Order Placed', Icons.shopping_cart),
      _StatusItem('confirmed', 'Confirmed', Icons.check_circle),
      _StatusItem('processing', 'Processing', Icons.settings),
      _StatusItem('shipped', 'Shipped', Icons.local_shipping),
      _StatusItem('delivered', 'Delivered', Icons.verified),
    ];

    final currentIndex = statuses
        .indexWhere((status) => status.id == currentStatus.toLowerCase());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...statuses.asMap().entries.map((entry) {
              final index = entry.key;
              final status = entry.value;
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return _buildTimelineItem(
                status: status,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isLast: index == statuses.length - 1,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required _StatusItem status,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline line and icon
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                status.icon,
                color: Colors.white,
                size: 12,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Status text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.green : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                if (isCurrent)
                  Text(
                    'Current Status',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusItem {
  final String id;
  final String title;
  final IconData icon;

  _StatusItem(this.id, this.title, this.icon);
}
