// screens/admin/manage_store_screen.dart
// ignore_for_file: deprecated_member_use, unnecessary_brace_in_string_interps, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:medicore/services/store_service.dart';
import 'package:medicore/widgets/admin/medicine_card_admin.dart';
import 'package:medicore/models/medicine_model.dart';
import 'package:medicore/widgets/image_upload_dialog.dart';

class ManageStoreScreen extends StatefulWidget {
  const ManageStoreScreen({super.key});

  @override
  State<ManageStoreScreen> createState() => _ManageStoreScreenState();
}

class _ManageStoreScreenState extends State<ManageStoreScreen> {
  final StoreService _storeService = StoreService();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedAvailability = 'all';

  final List<String> _categories = [
    'all',
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Ointment',
    'Drops',
    'Inhaler',
    'Other'
  ];

  final List<String> _availabilityOptions = [
    'all',
    'available',
    'out_of_stock'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Store'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildFilterSection(),

          // Medicines List
          Expanded(
            child: StreamBuilder<List<Medicine>>(
              stream: _getFilteredMedicinesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final medicines = snapshot.data!;

                return _buildMedicinesList(medicines);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewMedicine,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search medicines by name, brand, or description...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.blue[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Filters Row
          Row(
            children: [
              // Category Filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: Colors.blue[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    dropdownColor: Colors.white,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category == 'all' ? 'All Categories' : category,
                          style: TextStyle(
                            color: Colors.grey[800],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Availability Filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedAvailability,
                    decoration: InputDecoration(
                      labelText: 'Availability',
                      labelStyle: TextStyle(color: Colors.blue[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    dropdownColor: Colors.white,
                    items: _availabilityOptions.map((availability) {
                      return DropdownMenuItem<String>(
                        value: availability,
                        child: Text(
                          availability == 'all'
                              ? 'All Status'
                              : availability == 'available'
                                  ? 'In Stock'
                                  : 'Out of Stock',
                          style: TextStyle(
                            color: Colors.grey[800],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAvailability = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Medicines...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 64),
          const SizedBox(height: 16),
          Text(
            'Error loading medicines',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, color: Colors.grey[400], size: 80),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateMessage(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty ||
              _selectedCategory != 'all' ||
              _selectedAvailability != 'all')
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'all';
                  _selectedAvailability = 'all';
                });
              },
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicinesList(List<Medicine> medicines) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        final medicine = medicines[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: MedicineCardAdmin(
            medicine: medicine,
            onEdit: () => _editMedicine(medicine),
            onDelete: () => _deleteMedicine(medicine),
          ),
        );
      },
    );
  }

  Stream<List<Medicine>> _getFilteredMedicinesStream() {
    Stream<List<Medicine>> baseStream;

    if (_searchQuery.isNotEmpty) {
      baseStream = _storeService.searchMedicines(_searchQuery);
    } else {
      baseStream = _storeService.getAllMedicinesForAdmin();
    }

    if (_selectedCategory == 'all' && _selectedAvailability == 'all') {
      return baseStream;
    }

    return baseStream.map((medicines) {
      return medicines.where((medicine) {
        // Category filter
        final matchesCategory = _selectedCategory == 'all' ||
            medicine.category.toLowerCase() == _selectedCategory.toLowerCase();

        // Availability filter
        final matchesAvailability = _selectedAvailability == 'all' ||
            (_selectedAvailability == 'available' &&
                medicine.stockQuantity > 0) ||
            (_selectedAvailability == 'out_of_stock' &&
                medicine.stockQuantity <= 0);

        return matchesCategory && matchesAvailability;
      }).toList();
    });
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'No medicines found for "$_searchQuery"';
    }
    if (_selectedCategory != 'all') {
      return 'No ${_selectedCategory} medicines found';
    }
    if (_selectedAvailability != 'all') {
      return 'No ${_selectedAvailability == 'available' ? 'in stock' : 'out of stock'} medicines found';
    }
    return 'No medicines found';
  }

  void _addNewMedicine() {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final dosageController = TextEditingController();
    final manufacturerController = TextEditingController();
    final expiryController = TextEditingController();
    final compositionController = TextEditingController();
    final sideEffectsController = TextEditingController();
    final storageInstructionsController = TextEditingController();

    String selectedCategory = 'Tablet';
    String? imageUrl;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Add New Medicine',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Image Upload Section
                    GestureDetector(
                      onTap: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => ImageUploadDialog(
                            title: 'Upload Medicine Image',
                            currentImageUrl: imageUrl,
                            onImageSelected: (url) {
                              setState(() {
                                imageUrl = url.isEmpty ? null : url;
                              });
                              Navigator.pop(context);
                            },
                            useCloudinary: true,
                            cloudinaryKind: 'medicine',
                          ),
                        );
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue[300]!,
                            width: 2,
                          ),
                        ),
                        child: imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  imageUrl ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.medication,
                                        size: 40, color: Colors.grey);
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      color: Colors.blue[300], size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Image',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildFormField(
                      controller: nameController,
                      label: 'Medicine Name',
                      icon: Icons.medication,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: brandController,
                      label: 'Brand',
                      icon: Icons.business,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Category and Price Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryDropdown(
                            value: selectedCategory,
                            onChanged: (value) =>
                                setState(() => selectedCategory = value!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: priceController,
                            label: 'Price (৳)',
                            icon: Icons.attach_money,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock and Dosage Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: stockController,
                            label: 'Stock Quantity',
                            icon: Icons.inventory,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: dosageController,
                            label: 'Dosage',
                            icon: Icons.medical_services,
                            hintText: 'e.g., 500mg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: manufacturerController,
                      label: 'Manufacturer',
                      icon: Icons.factory,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: expiryController,
                      label: 'Expiry Date',
                      icon: Icons.calendar_today,
                      hintText: 'DD/MM/YYYY',
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: compositionController,
                      label: 'Composition',
                      icon: Icons.science,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: sideEffectsController,
                      label: 'Side Effects',
                      icon: Icons.warning,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: storageInstructionsController,
                      label: 'Storage Instructions',
                      icon: Icons.storage,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: descriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_validateForm(
                            nameController,
                            brandController,
                            priceController,
                            stockController,
                          )) {
                            final medicine = Medicine(
                              id: '',
                              name: nameController.text.trim(),
                              brand: brandController.text.trim(),
                              description: descriptionController.text.trim(),
                              category: selectedCategory,
                              price: double.tryParse(priceController.text) ?? 0,
                              discountPrice:
                                  double.tryParse(priceController.text) ?? 0,
                              discount: 0,
                              manufacturer:
                                  manufacturerController.text.trim().isEmpty
                                      ? null
                                      : manufacturerController.text.trim(),
                              imageUrl: imageUrl,
                              stockQuantity:
                                  int.tryParse(stockController.text) ?? 0,
                              dosage: dosageController.text.trim().isEmpty
                                  ? null
                                  : dosageController.text.trim(),
                              expiryDate: expiryController.text.trim().isEmpty
                                  ? null
                                  : expiryController.text.trim(),
                              composition:
                                  compositionController.text.trim().isEmpty
                                      ? null
                                      : compositionController.text.trim(),
                              sideEffects:
                                  sideEffectsController.text.trim().isEmpty
                                      ? null
                                      : sideEffectsController.text.trim(),
                              storageInstructions: storageInstructionsController
                                      .text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : storageInstructionsController.text.trim(),
                              tags: [],
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                              isActive: true,
                              prescriptionRequired: false,
                            );

                            try {
                              await _storeService.addMedicine(medicine);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${medicine.name} added successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add medicine: $e'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Add Medicine'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editMedicine(Medicine medicine) {
    final nameController = TextEditingController(text: medicine.name);
    final brandController = TextEditingController(text: medicine.brand);
    final descriptionController =
        TextEditingController(text: medicine.description);
    final priceController =
        TextEditingController(text: medicine.price.toString());
    final stockController =
        TextEditingController(text: medicine.stockQuantity.toString());
    final dosageController = TextEditingController(text: medicine.dosage ?? '');
    final manufacturerController =
        TextEditingController(text: medicine.manufacturer ?? '');
    final expiryController =
        TextEditingController(text: medicine.expiryDate ?? '');
    final compositionController =
        TextEditingController(text: medicine.composition ?? '');
    final sideEffectsController =
        TextEditingController(text: medicine.sideEffects ?? '');
    final storageInstructionsController =
        TextEditingController(text: medicine.storageInstructions ?? '');

    String selectedCategory = medicine.category;
    String? imageUrl = medicine.imageUrl;
    bool isActive = medicine.isActive;
    bool prescriptionRequired = medicine.prescriptionRequired;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: medicine.imageUrl != null
                          ? NetworkImage(medicine.imageUrl!)
                          : null,
                      child: medicine.imageUrl == null
                          ? const Icon(Icons.medication, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edit Medicine',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            medicine.name,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _editMedicineImage(medicine),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      tooltip: 'Change Image',
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Image Display
                    GestureDetector(
                      onTap: () => _editMedicineImage(medicine),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange[300]!,
                            width: 2,
                          ),
                        ),
                        child: imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.medication,
                                        size: 40, color: Colors.grey);
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.medication,
                                      color: Colors.orange[300], size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No Image',
                                    style: TextStyle(
                                      color: Colors.orange[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildFormField(
                      controller: nameController,
                      label: 'Medicine Name',
                      icon: Icons.medication,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: brandController,
                      label: 'Brand',
                      icon: Icons.business,
                      isRequired: true,
                    ),
                    const SizedBox(height: 16),

                    // Category and Price Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildCategoryDropdown(
                            value: selectedCategory,
                            onChanged: (value) =>
                                setState(() => selectedCategory = value!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: priceController,
                            label: 'Price (৳)',
                            icon: Icons.attach_money,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stock and Dosage Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: stockController,
                            label: 'Stock Quantity',
                            icon: Icons.inventory,
                            isRequired: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: dosageController,
                            label: 'Dosage',
                            icon: Icons.medical_services,
                            hintText: 'e.g., 500mg',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: manufacturerController,
                      label: 'Manufacturer',
                      icon: Icons.factory,
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: expiryController,
                      label: 'Expiry Date',
                      icon: Icons.calendar_today,
                      hintText: 'DD/MM/YYYY',
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: compositionController,
                      label: 'Composition',
                      icon: Icons.science,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: sideEffectsController,
                      label: 'Side Effects',
                      icon: Icons.warning,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: storageInstructionsController,
                      label: 'Storage Instructions',
                      icon: Icons.storage,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: descriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Toggle Switches
                    Row(
                      children: [
                        Expanded(
                          child: _buildToggleSwitch(
                            value: isActive,
                            onChanged: (value) =>
                                setState(() => isActive = value),
                            label: 'Active',
                            activeColor: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildToggleSwitch(
                            value: prescriptionRequired,
                            onChanged: (value) =>
                                setState(() => prescriptionRequired = value),
                            label: 'Prescription Required',
                            activeColor: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_validateForm(
                            nameController,
                            brandController,
                            priceController,
                            stockController,
                          )) {
                            final updatedMedicine = medicine.copyWith(
                              name: nameController.text.trim(),
                              brand: brandController.text.trim(),
                              description: descriptionController.text.trim(),
                              price: double.tryParse(priceController.text) ??
                                  medicine.price,
                              stockQuantity:
                                  int.tryParse(stockController.text) ??
                                      medicine.stockQuantity,
                              category: selectedCategory,
                              dosage: dosageController.text.trim().isEmpty
                                  ? null
                                  : dosageController.text.trim(),
                              manufacturer:
                                  manufacturerController.text.trim().isEmpty
                                      ? null
                                      : manufacturerController.text.trim(),
                              expiryDate: expiryController.text.trim().isEmpty
                                  ? null
                                  : expiryController.text.trim(),
                              composition:
                                  compositionController.text.trim().isEmpty
                                      ? null
                                      : compositionController.text.trim(),
                              sideEffects:
                                  sideEffectsController.text.trim().isEmpty
                                      ? null
                                      : sideEffectsController.text.trim(),
                              storageInstructions: storageInstructionsController
                                      .text
                                      .trim()
                                      .isEmpty
                                  ? null
                                  : storageInstructionsController.text.trim(),
                              imageUrl: imageUrl,
                              isActive: isActive,
                              prescriptionRequired: prescriptionRequired,
                              discountPrice:
                                  double.tryParse(priceController.text) ??
                                      medicine.price,
                            );

                            try {
                              await _storeService
                                  .updateMedicine(updatedMedicine);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${medicine.name} updated successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Failed to update medicine: $e'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown({
    required String value,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: 'Category',
          prefixIcon: Icon(Icons.category, color: Colors.blue[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        items: _categories.where((cat) => cat != 'all').map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required Function(bool) onChanged,
    required String label,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }

  bool _validateForm(
    TextEditingController name,
    TextEditingController brand,
    TextEditingController price,
    TextEditingController stock,
  ) {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter medicine name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    if (brand.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter brand name'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    if (price.text.trim().isEmpty || double.tryParse(price.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid price'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    if (stock.text.trim().isEmpty || int.tryParse(stock.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid stock quantity'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    return true;
  }

  void _editMedicineImage(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => ImageUploadDialog(
        title: 'Update Medicine Image',
        currentImageUrl: medicine.imageUrl,
        onImageSelected: (imageUrl) async {
          try {
            final updatedMedicine = medicine.copyWith(
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
            );
            await _storeService.updateMedicine(updatedMedicine);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(imageUrl.isEmpty
                    ? 'Medicine image removed'
                    : 'Medicine image updated successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update image: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _deleteMedicine(Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[400],
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Delete Medicine?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete ${medicine.name}? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await _storeService.deleteMedicine(medicine.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${medicine.name} deleted successfully'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Failed to delete ${medicine.name}: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete'),
                    ),
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
