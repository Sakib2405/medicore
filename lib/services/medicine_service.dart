// lib/services/medicine_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/medicine_model.dart';

class MedicineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all active medicines
  Future<List<Medicine>> getAllMedicines() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch medicines: $e');
    }
  }

  // Get medicine by ID
  Future<Medicine?> getMedicineById(String medicineId) async {
    try {
      final doc =
          await _firestore.collection('medicines').doc(medicineId).get();

      if (doc.exists) {
        return Medicine.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch medicine: $e');
    }
  }

  // Get medicines by category
  Future<List<Medicine>> getMedicinesByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch medicines by category: $e');
    }
  }

  // Get medicines by brand
  Future<List<Medicine>> getMedicinesByBrand(String brand) async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('brand', isEqualTo: brand)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch medicines by brand: $e');
    }
  }

  // Search medicines by name, brand, or tags
  Future<List<Medicine>> searchMedicines(String query) async {
    try {
      if (query.isEmpty) {
        return getAllMedicines();
      }

      final lowercaseQuery = query.toLowerCase();

      final snapshot = await _firestore
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Medicine.fromFirestore(doc))
          .where((medicine) =>
              medicine.name.toLowerCase().contains(lowercaseQuery) ||
              medicine.brand.toLowerCase().contains(lowercaseQuery) ||
              medicine.tags
                  .any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ||
              (medicine.manufacturer?.toLowerCase().contains(lowercaseQuery) ??
                  false))
          .toList();
    } catch (e) {
      throw Exception('Failed to search medicines: $e');
    }
  }

  // Get medicines in stock
  Future<List<Medicine>> getMedicinesInStock() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('stockQuantity', isGreaterThan: 0)
          .where('isActive', isEqualTo: true)
          .orderBy('stockQuantity', descending: true)
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch medicines in stock: $e');
    }
  }

  // Get discounted medicines
  Future<List<Medicine>> getDiscountedMedicines() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('discount', isGreaterThan: 0)
          .where('isActive', isEqualTo: true)
          .where('stockQuantity', isGreaterThan: 0)
          .orderBy('discount', descending: true)
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch discounted medicines: $e');
    }
  }

  // Get medicines requiring prescription
  Future<List<Medicine>> getPrescriptionMedicines() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('prescriptionRequired', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('stockQuantity', isGreaterThan: 0)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch prescription medicines: $e');
    }
  }

  // Get medicines not requiring prescription
  Future<List<Medicine>> getOverTheCounterMedicines() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('prescriptionRequired', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .where('stockQuantity', isGreaterThan: 0)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch over-the-counter medicines: $e');
    }
  }

  // Get low stock medicines
  Future<List<Medicine>> getLowStockMedicines() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('stockQuantity', isLessThan: 10)
          .where('stockQuantity', isGreaterThan: 0)
          .where('isActive', isEqualTo: true)
          .orderBy('stockQuantity')
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch low stock medicines: $e');
    }
  }

  // Get out of stock medicines
  Future<List<Medicine>> getOutOfStockMedicines() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('stockQuantity', isEqualTo: 0)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch out of stock medicines: $e');
    }
  }

  // Get medicines by price range
  Future<List<Medicine>> getMedicinesByPriceRange(
      double minPrice, double maxPrice) async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('discountPrice', isGreaterThanOrEqualTo: minPrice)
          .where('discountPrice', isLessThanOrEqualTo: maxPrice)
          .where('isActive', isEqualTo: true)
          .where('stockQuantity', isGreaterThan: 0)
          .orderBy('discountPrice')
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch medicines by price range: $e');
    }
  }

  // Get featured medicines
  Future<List<Medicine>> getFeaturedMedicines() async {
    try {
      // You can add a 'featured' field to your medicine model
      final snapshot = await _firestore
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .where('stockQuantity', isGreaterThan: 0)
          .orderBy('discount', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured medicines: $e');
    }
  }

  // Add new medicine (for admin)
  Future<void> addMedicine(Medicine medicine) async {
    try {
      await _firestore
          .collection('medicines')
          .doc(medicine.id)
          .set(medicine.toMap());
    } catch (e) {
      throw Exception('Failed to add medicine: $e');
    }
  }

  // Update medicine (for admin)
  Future<void> updateMedicine(
      String medicineId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('medicines').doc(medicineId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update medicine: $e');
    }
  }

  // Update medicine stock
  Future<void> updateMedicineStock(String medicineId, int newStock) async {
    try {
      await _firestore.collection('medicines').doc(medicineId).update({
        'stockQuantity': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update medicine stock: $e');
    }
  }

  // Update medicine price and discount
  Future<void> updateMedicinePricing(
      String medicineId, double price, int discount) async {
    try {
      final discountPrice = price - (price * discount / 100);

      await _firestore.collection('medicines').doc(medicineId).update({
        'price': price,
        'discount': discount,
        'discountPrice': discountPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update medicine pricing: $e');
    }
  }

  // Toggle medicine active status
  Future<void> toggleMedicineStatus(String medicineId, bool isActive) async {
    try {
      await _firestore.collection('medicines').doc(medicineId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle medicine status: $e');
    }
  }

  // Delete medicine (for admin)
  Future<void> deleteMedicine(String medicineId) async {
    try {
      await _firestore.collection('medicines').doc(medicineId).delete();
    } catch (e) {
      throw Exception('Failed to delete medicine: $e');
    }
  }

  // Get medicine categories
  Future<List<String>> getMedicineCategories() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .get();

      final categories = snapshot.docs
          .map((doc) => doc.data()['category'] as String? ?? '')
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList();

      return categories;
    } catch (e) {
      throw Exception('Failed to fetch medicine categories: $e');
    }
  }

  // Get medicine brands
  Future<List<String>> getMedicineBrands() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .orderBy('brand')
          .get();

      final brands = snapshot.docs
          .map((doc) => doc.data()['brand'] as String? ?? '')
          .where((brand) => brand.isNotEmpty)
          .toSet()
          .toList();

      return brands;
    } catch (e) {
      throw Exception('Failed to fetch medicine brands: $e');
    }
  }

  // Get medicine manufacturers
  Future<List<String>> getMedicineManufacturers() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .orderBy('manufacturer')
          .get();

      final manufacturers = snapshot.docs
          .map((doc) => doc.data()['manufacturer'] as String? ?? '')
          .where((manufacturer) => manufacturer.isNotEmpty)
          .toSet()
          .toList();

      return manufacturers;
    } catch (e) {
      throw Exception('Failed to fetch medicine manufacturers: $e');
    }
  }

  // Stream for real-time medicine updates
  Stream<List<Medicine>> getMedicinesStream() {
    return _firestore
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Stream for medicines in stock
  Stream<List<Medicine>> getMedicinesInStockStream() {
    return _firestore
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .where('stockQuantity', isGreaterThan: 0)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Stream for discounted medicines
  Stream<List<Medicine>> getDiscountedMedicinesStream() {
    return _firestore
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .where('discount', isGreaterThan: 0)
        .where('stockQuantity', isGreaterThan: 0)
        .orderBy('discount', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Get medicine count
  Future<int?> getMedicineCount() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .count()
          .get();

      return snapshot.count;
    } catch (e) {
      throw Exception('Failed to get medicine count: $e');
    }
  }

  // Get total stock value
  Future<double> getTotalStockValue() async {
    try {
      final snapshot = await _firestore
          .collection('medicines')
          .where('isActive', isEqualTo: true)
          .where('stockQuantity', isGreaterThan: 0)
          .get();

      double totalValue = 0;
      for (final doc in snapshot.docs) {
        final medicine = Medicine.fromFirestore(doc);
        totalValue += medicine.discountPrice * medicine.stockQuantity;
      }

      return totalValue;
    } catch (e) {
      throw Exception('Failed to calculate total stock value: $e');
    }
  }

  // Bulk update medicines (for admin)
  Future<void> bulkUpdateMedicines(
      List<String> medicineIds, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();

      for (final medicineId in medicineIds) {
        final docRef = _firestore.collection('medicines').doc(medicineId);
        batch.update(docRef, {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to bulk update medicines: $e');
    }
  }

  // Reduce stock after purchase
  Future<void> reduceStock(String medicineId, int quantity) async {
    try {
      final medicine = await getMedicineById(medicineId);
      if (medicine != null) {
        final newStock = medicine.stockQuantity - quantity;
        if (newStock >= 0) {
          await updateMedicineStock(medicineId, newStock);
        } else {
          throw Exception('Insufficient stock for ${medicine.name}');
        }
      }
    } catch (e) {
      throw Exception('Failed to reduce stock: $e');
    }
  }

  // Check if medicine is available in required quantity
  Future<bool> checkAvailability(
      String medicineId, int requiredQuantity) async {
    try {
      final medicine = await getMedicineById(medicineId);
      return medicine != null &&
          medicine.isActive &&
          medicine.stockQuantity >= requiredQuantity;
    } catch (e) {
      return false;
    }
  }
}
