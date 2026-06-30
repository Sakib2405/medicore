// widgets/admin/medicine_card_admin.dart
import 'package:flutter/material.dart';
import 'package:medicore/models/medicine_model.dart';

class MedicineCardAdmin extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineCardAdmin({
    super.key,
    required this.medicine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Medicine Image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: (medicine.imageUrl?.isNotEmpty ?? false)
                        ? DecorationImage(
                            image: NetworkImage(medicine.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (medicine.imageUrl?.isEmpty ?? true)
                      ? Icon(Icons.medication, color: Colors.grey[400])
                      : null,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medicine.manufacturer ?? 'Unknown Manufacturer',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        medicine.category,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Stock Status
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStockColor(medicine.stockQuantity),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Stock: ${medicine.stockQuantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Price and Actions
            Row(
              children: [
                // Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '৳${medicine.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (medicine.hasDiscount)
                        Text(
                          '৳${medicine.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),

                // Action Buttons (fixed size to avoid expansion)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.edit, color: Colors.blue[700]),
                        onPressed: onEdit,
                        tooltip: 'Edit Medicine',
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.delete, color: Colors.red[700]),
                        onPressed: onDelete,
                        tooltip: 'Delete Medicine',
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Additional Info
            if ((medicine.dosage?.isNotEmpty ?? false) ||
                (medicine.sideEffects?.isNotEmpty ?? false))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  if (medicine.dosage?.isNotEmpty ?? false)
                    Text(
                      'Dosage: ${medicine.dosage}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  if (medicine.sideEffects?.isNotEmpty ?? false)
                    Text(
                      'Side Effects: ${medicine.sideEffects}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getStockColor(int stock) {
    if (stock == 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    return Colors.green;
  }
}
