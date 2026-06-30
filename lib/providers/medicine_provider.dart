// ignore_for_file: avoid_print, unnecessary_overrides

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/medicine_model.dart';

class MedicineProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  // Get filtered medicines based on search and category
  List<Medicine> get filteredMedicines {
    var filtered = _medicines.where((medicine) => medicine.isActive).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((medicine) {
        final query = _searchQuery.toLowerCase();
        return medicine.name.toLowerCase().contains(query) ||
            medicine.brand.toLowerCase().contains(query) ||
            medicine.category.toLowerCase().contains(query) ||
            (medicine.manufacturer != null &&
                medicine.manufacturer!.toLowerCase().contains(query)) ||
            medicine.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((medicine) => medicine.category == _selectedCategory)
          .toList();
    }

    return filtered;
  }

  // Get all unique categories
  List<String> get categories {
    final allCategories = _medicines
        .where((medicine) => medicine.isActive)
        .map((medicine) => medicine.category)
        .toSet()
        .toList();
    allCategories.sort();
    return ['All', ...allCategories];
  }

  Future<void> loadMedicines() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot =
          await _firestore.collection('medicines').orderBy('name').get();

      _medicines =
          querySnapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      _errorMessage = 'Failed to load medicines: $e';
      print('Error loading medicines: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Stream for real-time updates
  Stream<List<Medicine>> getMedicinesStream() {
    return _firestore
        .collection('medicines')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    });
  }

  // Stream for active medicines only
  Stream<List<Medicine>> getActiveMedicinesStream() {
    return _firestore
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    notifyListeners();
  }

  // Get featured medicines (medicines with discount)
  List<Medicine> get featuredMedicines {
    return _medicines
        .where((medicine) => medicine.hasDiscount && medicine.isActive)
        .toList();
  }

  // Get out of stock medicines
  List<Medicine> get outOfStockMedicines {
    return _medicines
        .where((medicine) => medicine.isOutOfStock && medicine.isActive)
        .toList();
  }

  // Get low stock medicines
  List<Medicine> get lowStockMedicines {
    return _medicines
        .where((medicine) => medicine.isLowStock && medicine.isActive)
        .toList();
  }

  // Get medicines by category
  List<Medicine> getMedicinesByCategory(String category) {
    return _medicines
        .where((medicine) => medicine.category == category && medicine.isActive)
        .toList();
  }

  // Search medicines
  List<Medicine> searchMedicines(String query) {
    return _medicines.where((medicine) {
      final searchQuery = query.toLowerCase();
      return medicine.name.toLowerCase().contains(searchQuery) ||
          medicine.brand.toLowerCase().contains(searchQuery) ||
          (medicine.manufacturer != null &&
              medicine.manufacturer!.toLowerCase().contains(searchQuery)) ||
          medicine.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
    }).toList();
  }

  // Get medicine by ID
  Medicine? getMedicineById(String id) {
    try {
      return _medicines.firstWhere((medicine) => medicine.id == id);
    } catch (e) {
      return null;
    }
  }

  // Refresh medicines
  Future<void> refreshMedicines() async {
    await loadMedicines();
  }

  // Check if any medicines are loading
  bool get hasMedicines => _medicines.isNotEmpty;

  // Get prescription required medicines
  List<Medicine> get prescriptionRequiredMedicines {
    return _medicines
        .where((medicine) => medicine.prescriptionRequired && medicine.isActive)
        .toList();
  }

  // Get recently added medicines
  List<Medicine> get recentlyAddedMedicines {
    return _medicines.where((medicine) => medicine.isActive).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Get medicines that need restocking (out of stock or low stock)
  List<Medicine> get medicinesNeedingRestock {
    return _medicines
        .where((medicine) =>
            (medicine.isOutOfStock || medicine.isLowStock) && medicine.isActive)
        .toList();
  }

  // Update local medicine data (useful when using streams)
  void updateMedicinesList(List<Medicine> medicines) {
    _medicines = medicines;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Dispose method
  @override
  void dispose() {
    super.dispose();
  }
}
