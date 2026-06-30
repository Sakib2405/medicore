import 'package:flutter/material.dart';
import 'package:medicore/widgets/patient/store/medicine_card.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/medicine_provider.dart';
import 'package:medicore/providers/cart_provider.dart';
import 'package:medicore/models/medicine_model.dart';

class MedicineStoreScreen extends StatefulWidget {
  const MedicineStoreScreen({super.key});

  @override
  State<MedicineStoreScreen> createState() => _MedicineStoreScreenState();
}

class _MedicineStoreScreenState extends State<MedicineStoreScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedicineProvider>(context, listen: false).loadMedicines();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Store'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Badge(
                label: Text(cartProvider.cartItemsCount.toString()),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedicineCartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                Provider.of<MedicineProvider>(context, listen: false)
                    .setSearchQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),
          // Category Filter
          Consumer<MedicineProvider>(
            builder: (context, medicineProvider, child) {
              return SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: medicineProvider.categories.length,
                  itemBuilder: (context, index) {
                    final category = medicineProvider.categories[index];
                    final isSelected =
                        medicineProvider.selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          Provider.of<MedicineProvider>(context, listen: false)
                              .setSelectedCategory(selected ? category : 'All');
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Consumer<MedicineProvider>(
              builder: (context, medicineProvider, child) {
                if (medicineProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (medicineProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${medicineProvider.errorMessage!}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => medicineProvider.loadMedicines(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final medicines = medicineProvider.filteredMedicines;

                if (medicines.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medication, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No Medicines Found',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('Try adjusting your search or filter'),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final medicine = medicines[index];
                    return _buildMedicineCard(medicine, context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine, BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final isInCart = cartProvider.isInCart(medicine);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine Image
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              color: Colors.grey.shade100,
            ),
            child: Stack(
              children: [
                // Medicine Image
                if (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      medicine.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage();
                      },
                    ),
                  )
                else
                  _buildPlaceholderImage(),

                // Discount Badge
                if (medicine.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${medicine.discountPercentage.round()}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Stock Status
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: medicine.inStock
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medicine.inStock ? 'In Stock' : 'Out of Stock',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  medicine.brand,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                // Price
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
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Add to Cart Button
                ElevatedButton(
                  onPressed: medicine.inStock
                      ? () {
                          if (isInCart) {
                            cartProvider.removeFromCart(medicine);
                            _showSnackbar(
                                context, '${medicine.name} removed from cart');
                          } else {
                            cartProvider.addToCart(medicine);
                            _showSnackbar(
                                context, '${medicine.name} added to cart');
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isInCart ? Colors.red.shade600 : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isInCart ? 'Remove from Cart' : 'Add to Cart',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
