import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/doctor_model.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createDoctorProfile(Doctor doctor) async {
    try {
      await _firestore
          .collection('doctors')
          .doc(doctor.uid)
          .set(doctor.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Doctor>> getDoctorsStream({int limit = 20}) {
    return _firestore
        .collection('doctors')
        .orderBy('name')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Doctor.fromFirestore(d)).toList());
  }

  Future<List<Doctor>> getMoreDoctors(
      DocumentSnapshot lastDoc, int limit) async {
    final snap = await _firestore
        .collection('doctors')
        .orderBy('name')
        .startAfterDocument(lastDoc)
        .limit(limit)
        .get();
    return snap.docs.map((d) => Doctor.fromFirestore(d)).toList();
  }

  Future<DocumentSnapshot?> getDoctorDocAt(int index) async {
    final snap = await _firestore
        .collection('doctors')
        .orderBy('name')
        .limit(index + 1)
        .get();
    if (snap.docs.length > index) return snap.docs[index];
    return null;
  }

  Stream<Doctor?> streamDoctorById(String doctorId) {
    if (doctorId.trim().isEmpty) {
      return Stream.value(null);
    }
    return _firestore.collection('doctors').doc(doctorId).snapshots().map(
          (doc) => doc.exists ? Doctor.fromFirestore(doc) : null,
        );
  }

  Future<Doctor?> getDoctorById(String doctorId) async {
    try {
      if (doctorId.trim().isEmpty) {
        return null;
      }
      final doc = await _firestore.collection('doctors').doc(doctorId).get();
      return doc.exists ? Doctor.fromFirestore(doc) : null;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Doctor>> getAllDoctors() async {
    try {
      final querySnapshot =
          await _firestore.collection('doctors').orderBy('name').get();
      return querySnapshot.docs
          .map((doc) => Doctor.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateDoctor(Doctor doctor) async {
    try {
      await _firestore
          .collection('doctors')
          .doc(doctor.uid)
          .update(doctor.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAvailability(String doctorId, bool isAvailable) async {
    await _firestore.collection('doctors').doc(doctorId).update({
      'isAvailable': isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDoctor(String doctorId) async {
    try {
      await _firestore.collection('doctors').doc(doctorId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
