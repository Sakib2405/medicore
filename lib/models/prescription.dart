import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String doctorId;
  final String? doctorName;
  final String patientId;
  final List<Map<String, dynamic>> medicines;
  final String notes;
  final Timestamp createdAt;
  final String? pdfUrl;

  Prescription({
    required this.id,
    required this.doctorId,
    this.doctorName,
    required this.patientId,
    required this.medicines,
    required this.notes,
    required this.createdAt,
    this.pdfUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'patientId': patientId,
      'medicines': medicines,
      'notes': notes,
      'createdAt': createdAt,
      'pdfUrl': pdfUrl,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map) {
    return Prescription(
      id: map['id'] as String,
      doctorId: map['doctorId'] as String,
      doctorName: map['doctorName'] as String?,
      patientId: map['patientId'] as String,
      medicines: (map['medicines'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      notes: map['notes'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      pdfUrl: map['pdfUrl'] as String?,
    );
  }
}
