import 'package:flutter/material.dart';

class CartItemWidget extends StatelessWidget {
  final String itemName;
  final double price;
  final int quantity;
  final String? imageUrl;
  final String? manufacturer;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;

  const CartItemWidget({
    super.key,
    required this.itemName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.manufacturer,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                color: Colors.grey.shade200,
                image: imageUrl != null && imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: imageUrl == null || imageUrl!.isEmpty
                  ? const Icon(Icons.medication, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),

            // Medicine Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (manufacturer != null && manufacturer!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      manufacturer!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '৳${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Remove from cart',
            ),
          ],
        ),
      ),
    );
  }
}
