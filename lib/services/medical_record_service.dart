import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/medical_record_model.dart';

class MedicalRecordService {
  final _col = FirebaseFirestore.instance.collection('medical_records');

  Stream<List<MedicalRecordModel>> watchRecords(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map(MedicalRecordModel.fromFirestore).toList());
  }

  Future<void> addRecord(MedicalRecordModel record) async {
    await _col.add(record.toMap());
  }

  Future<void> deleteRecord(String recordId) async {
    await _col.doc(recordId).delete();
  }
}
