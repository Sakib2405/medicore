import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicore/models/medicine_model.dart';
import 'package:medicore/providers/cart_provider.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;
  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  int _quantity = 1;

  void _inc() => setState(() => _quantity++);
  void _dec() => setState(() {
        if (_quantity > 1) _quantity--;
      });

  @override
  Widget build(BuildContext context) {
    final med = widget.medicine;
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(med.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: (med.imageUrl != null && med.imageUrl!.isNotEmpty)
                      ? Image.network(
                          med.imageUrl!,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, st) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(med.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              if (med.brand.isNotEmpty)
                Text(med.brand, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 12),

              // Price row
              Row(children: [
                Text('৳${med.finalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                const SizedBox(width: 8),
                if (med.hasDiscount)
                  Text('৳${med.price.toStringAsFixed(2)}',
                      style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey.shade500)),
              ]),

              const SizedBox(height: 12),

              // Stock and prescription
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                      color: med.inStock
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(med.inStock ? 'In Stock' : 'Out of Stock',
                      style: TextStyle(
                          color: med.inStock
                              ? Colors.green.shade700
                              : Colors.red.shade700)),
                ),
                const SizedBox(width: 8),
                if (med.prescriptionRequired)
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Prescription Required',
                          style: TextStyle(color: Colors.orange.shade800))),
              ]),

              const SizedBox(height: 16),

              if (med.description.isNotEmpty) ...[
                const Text('Description',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(med.description),
                const SizedBox(height: 12),
              ],
              if ((med.composition ?? '').isNotEmpty) ...[
                const Text('Composition',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(med.composition ?? ''),
                const SizedBox(height: 12),
              ],
              if ((med.dosage ?? '').isNotEmpty) ...[
                const Text('Dosage',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(med.dosage ?? ''),
                const SizedBox(height: 12),
              ],
              if ((med.sideEffects ?? '').isNotEmpty) ...[
                const Text('Side Effects',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(med.sideEffects ?? ''),
                const SizedBox(height: 12),
              ],
              if ((med.manufacturer ?? '').isNotEmpty) ...[
                const Text('Manufacturer',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(med.manufacturer ?? ''),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  IconButton(
                    onPressed: _dec,
                    icon: const Icon(Icons.remove, size: 18),
                    padding: const EdgeInsets.all(4),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text('$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  IconButton(
                    onPressed: _inc,
                    icon: const Icon(Icons.add, size: 18),
                    padding: const EdgeInsets.all(4),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: med.inStock
                      ? () {
                          cart.addToCartWithQuantity(med, _quantity);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${med.name} (x$_quantity) added to cart'),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('Add to Cart'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        height: 220,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Icon(Icons.medication, size: 72, color: Colors.grey),
      );
}
