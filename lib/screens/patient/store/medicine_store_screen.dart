import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/medicine_provider.dart';
import 'package:medicore/providers/cart_provider.dart';
import 'package:medicore/models/medicine_model.dart';
import 'package:medicore/screens/patient/store/medicine_detail_screen.dart';
import 'package:medicore/config/routes.dart';

class MedicineStoreScreen extends StatefulWidget {
  const MedicineStoreScreen({super.key});

  @override
  State<MedicineStoreScreen> createState() => _MedicineStoreScreenState();
}

class _MedicineStoreScreenState extends State<MedicineStoreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _searchFocused = false;

  static const _primaryGrad = [Color(0xFF4776E6), Color(0xFF8E54E9)];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicineProvider>().loadMedicines();
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
      backgroundColor: const Color(0xFFF2F4F8),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildCategoryChips()),
              SliverToBoxAdapter(child: _buildPromoBanner()),
              SliverToBoxAdapter(child: _buildSectionHeader('All Medicines')),
              _buildMedicineGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          _buildFloatingCart(),
        ],
      ),
    );
  }

  // ─────────────────── AppBar ───────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: _primaryGrad,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Medicine Store',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.myOrders),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.receipt_long_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 5),
                              Text('My Orders',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quality medicines, delivered to your door',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── Search ───────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Focus(
        onFocusChange: (f) => setState(() => _searchFocused = f),
        child: TextField(
          controller: _searchController,
          onChanged: (v) =>
              context.read<MedicineProvider>().setSearchQuery(v),
          decoration: InputDecoration(
            hintText: 'Search medicines, brands…',
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded,
                color: _searchFocused
                    ? const Color(0xFF4776E6)
                    : Colors.grey.shade400),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    color: Colors.grey.shade400,
                    onPressed: () {
                      _searchController.clear();
                      context
                          .read<MedicineProvider>()
                          .setSearchQuery('');
                      setState(() {});
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: Color(0xFF4776E6), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────── Category chips ───────────────────
  Widget _buildCategoryChips() {
    return Consumer<MedicineProvider>(
      builder: (_, prov, __) {
        final categories = prov.categories;
        return SizedBox(
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (_, i) {
              final cat = categories[i];
              final selected = prov.selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => prov.setSelectedCategory(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: _primaryGrad,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: selected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: selected
                          ? null
                          : Border.all(color: Colors.grey.shade300),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF4776E6)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─────────────────── Promo banner ───────────────────
  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF11998E).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.local_offer_rounded,
                  color: Colors.white, size: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Use code SAVE5',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                    const SizedBox(height: 3),
                    Text('Get 5% off your next order',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Shop Now',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────── Section header ───────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          Consumer<MedicineProvider>(builder: (_, prov, __) {
            return Text('${prov.filteredMedicines.length} items',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500));
          }),
        ],
      ),
    );
  }

  // ─────────────────── Grid ───────────────────
  Widget _buildMedicineGrid() {
    return Consumer<MedicineProvider>(
      builder: (_, prov, __) {
        if (prov.isLoading) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final medicines = prov.filteredMedicines;

        if (medicines.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, i) => _MedicineCard(
                medicine: medicines[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MedicineDetailScreen(medicine: medicines[i]),
                  ),
                ),
              ),
              childCount: medicines.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text('No medicines found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Text('Try a different search or category',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ─────────────────── Floating cart ───────────────────
  Widget _buildFloatingCart() {
    return Positioned(
      bottom: 20,
      left: 24,
      right: 24,
      child: Consumer<CartProvider>(
        builder: (_, cart, __) {
          if (cart.isCartEmpty) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, Routes.cart),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: _primaryGrad,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4776E6).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${cart.totalItemsCount} item${cart.totalItemsCount == 1 ? '' : 's'} in cart',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '৳${cart.cartTotalWithQuantity.toStringAsFixed(0)}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Row(
                    children: [
                      Text('View Cart',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────── Medicine Card ───────────────────
class _MedicineCard extends StatefulWidget {
  final Medicine medicine;
  final VoidCallback onTap;

  const _MedicineCard({required this.medicine, required this.onTap});

  @override
  State<_MedicineCard> createState() => _MedicineCardState();
}

class _MedicineCardState extends State<_MedicineCard> {
  bool _adding = false;

  Future<void> _addToCart(BuildContext context) async {
    if (widget.medicine.isOutOfStock) return;
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding = true);
    await Future.delayed(const Duration(milliseconds: 200));

    if (cart.isInCart(widget.medicine)) {
      cart.updateCartItemQuantity(
          widget.medicine.id, cart.getItemQuantity(widget.medicine.id) + 1);
    } else {
      cart.addToCartWithQuantity(widget.medicine, 1);
    }

    if (mounted) {
      setState(() => _adding = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${widget.medicine.name} added to cart'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.medicine;
    final isInCart = context.watch<CartProvider>().isInCart(m);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: const Color(0xFFF0F4FF),
                    child: m.imageUrl != null && m.imageUrl!.isNotEmpty
                        ? Image.network(
                            m.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                if (m.hasDiscount)
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
                        '-${m.discountPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                if (m.isOutOfStock)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(18)),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Out of Stock',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Info area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      m.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                    const Spacer(),
                    // Price row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${m.finalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4776E6)),
                        ),
                        if (m.hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            '৳${m.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Stock indicator
                    if (!m.isOutOfStock && m.isLowStock)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 12, color: Colors.orange.shade600),
                            const SizedBox(width: 3),
                            Text('Only ${m.stockQuantity} left',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: m.isOutOfStock
                          ? OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Unavailable',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade400)),
                            )
                          : isInCart
                              ? ElevatedButton.icon(
                                  onPressed: () => _addToCart(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  icon: _adding
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(Icons.add_shopping_cart_rounded, size: 15),
                                  label: const Text('Add More',
                                      style: TextStyle(fontSize: 12)),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _addToCart(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4776E6),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  icon: _adding
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Icon(Icons.add_rounded, size: 16),
                                  label: const Text('Add to Cart',
                                      style: TextStyle(fontSize: 12)),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Center(
        child: Icon(Icons.medication_rounded,
            size: 52, color: const Color(0xFF4776E6).withValues(alpha: 0.3)),
      );
}
