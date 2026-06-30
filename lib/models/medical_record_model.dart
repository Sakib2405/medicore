import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecordModel {
  final String id;
  final String userId;
  final String title;
  final String type;
  final String doctor;
  final String description;
  final DateTime date;
  final String? fileUrl;
  final DateTime createdAt;

  MedicalRecordModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.doctor,
    required this.description,
    required this.date,
    this.fileUrl,
    required this.createdAt,
  });

  factory MedicalRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MedicalRecordModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      type: data['type'] ?? 'Other',
      doctor: data['doctor'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileUrl: data['fileUrl'],
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'type': type,
        'doctor': doctor,
        'description': description,
        'date': Timestamp.fromDate(date),
        'fileUrl': fileUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
