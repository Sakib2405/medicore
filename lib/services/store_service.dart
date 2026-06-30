// services/store_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/medicine_model.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all medicines (real-time stream)
  Stream<List<Medicine>> getMedicines() {
    return _firestore
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Get all medicines including inactive (for admin)
  Stream<List<Medicine>> getAllMedicinesForAdmin() {
    return _firestore.collection('medicines').orderBy('name').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Get medicine by ID
  Future<Medicine?> getMedicineById(String id) async {
    try {
      final doc = await _firestore.collection('medicines').doc(id).get();
      if (doc.exists) {
        return Medicine.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting medicine: $e');
      return null;
    }
  }

  // Add new medicine
  Future<void> addMedicine(Medicine medicine) async {
    try {
      final docRef = _firestore.collection('medicines').doc();
      final medicineWithId = medicine.copyWith(id: docRef.id);
      await docRef.set(medicineWithId.toMap());
    } catch (e) {
      print('Error adding medicine: $e');
      throw Exception('Failed to add medicine: $e');
    }
  }

  // Update medicine
  Future<void> updateMedicine(Medicine medicine) async {
    try {
      await _firestore
          .collection('medicines')
          .doc(medicine.id)
          .update(medicine.toMap());
    } catch (e) {
      print('Error updating medicine: $e');
      throw Exception('Failed to update medicine: $e');
    }
  }

  // Delete medicine (soft delete)
  Future<void> deleteMedicine(String medicineId) async {
    try {
      await _firestore.collection('medicines').doc(medicineId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting medicine: $e');
      throw Exception('Failed to delete medicine: $e');
    }
  }

  // Hard delete medicine (use with caution)
  Future<void> hardDeleteMedicine(String medicineId) async {
    try {
      await _firestore.collection('medicines').doc(medicineId).delete();
    } catch (e) {
      print('Error hard deleting medicine: $e');
      throw Exception('Failed to delete medicine: $e');
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
      print('Error updating medicine stock: $e');
      throw Exception('Failed to update medicine stock: $e');
    }
  }

  // Update medicine discount
  Future<void> updateMedicineDiscount(
      String medicineId, int discount, double discountPrice) async {
    try {
      await _firestore.collection('medicines').doc(medicineId).update({
        'discount': discount,
        'discountPrice': discountPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating medicine discount: $e');
      throw Exception('Failed to update medicine discount: $e');
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
      print('Error toggling medicine status: $e');
      throw Exception('Failed to toggle medicine status: $e');
    }
  }

  // Toggle prescription requirement
  Future<void> togglePrescriptionRequired(
      String medicineId, bool prescriptionRequired) async {
    try {
      await _firestore.collection('medicines').doc(medicineId).update({
        'prescriptionRequired': prescriptionRequired,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling prescription requirement: $e');
      throw Exception('Failed to toggle prescription requirement: $e');
    }
  }

  // Get low stock medicines
  Stream<List<Medicine>> getLowStockMedicines() {
    return _firestore
        .collection('medicines')
        .where('stockQuantity', isLessThan: 10)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Get out of stock medicines
  Stream<List<Medicine>> getOutOfStockMedicines() {
    return _firestore
        .collection('medicines')
        .where('stockQuantity', isEqualTo: 0)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Get featured medicines (with discount)
  Stream<List<Medicine>> getFeaturedMedicines() {
    return _firestore
        .collection('medicines')
        .where('discount', isGreaterThan: 0)
        .where('isActive', isEqualTo: true)
        .orderBy('discount', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Get medicines by category
  Stream<List<Medicine>> getMedicinesByCategory(String category) {
    return _firestore
        .collection('medicines')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Get prescription required medicines
  Stream<List<Medicine>> getPrescriptionRequiredMedicines() {
    return _firestore
        .collection('medicines')
        .where('prescriptionRequired', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Search medicines
  Stream<List<Medicine>> searchMedicines(String query) {
    if (query.isEmpty) {
      return getMedicines();
    }

    return _firestore
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final allMedicines =
          snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList();

      return allMedicines.where((medicine) {
        final searchQuery = query.toLowerCase();
        return medicine.name.toLowerCase().contains(searchQuery) ||
            medicine.brand.toLowerCase().contains(searchQuery) ||
            medicine.category.toLowerCase().contains(searchQuery) ||
            (medicine.manufacturer != null &&
                medicine.manufacturer!.toLowerCase().contains(searchQuery)) ||
            medicine.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
      }).toList();
    });
  }

  // Get all categories
  Stream<List<String>> getCategories() {
    return _firestore
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final categories = snapshot.docs
          .map((doc) => doc['category'] as String? ?? '')
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList();
      categories.sort();
      return categories;
    });
  }

  // Get medicines with pagination
  Stream<List<Medicine>> getMedicinesWithPagination(
      int limit, DocumentSnapshot? lastDocument) {
    var query = _firestore
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Medicine.fromFirestore(doc)).toList());
  }

  // Get medicines count
  Stream<int> getMedicinesCount() {
    return _firestore
        .collection('medicines')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Batch update medicines
  Future<void> batchUpdateMedicines(List<Medicine> medicines) async {
    final batch = _firestore.batch();

    for (final medicine in medicines) {
      final docRef = _firestore.collection('medicines').doc(medicine.id);
      batch.update(docRef, medicine.toMap());
    }

    try {
      await batch.commit();
    } catch (e) {
      print('Error batch updating medicines: $e');
      throw Exception('Failed to batch update medicines: $e');
    }
  }

  // Check if medicine name already exists
  Future<bool> doesMedicineNameExist(String name, {String? excludeId}) async {
    try {
      var query = _firestore
          .collection('medicines')
          .where('name', isEqualTo: name)
          .where('isActive', isEqualTo: true);

      final snapshot = await query.get();

      if (excludeId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking medicine name: $e');
      return false;
    }
  }
}
