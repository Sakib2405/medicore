import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String appointmentId;
  final double rating; // 1.0 – 5.0
  final String comment;
  final Timestamp createdAt;

  Review({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.patientName,
    required this.appointmentId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map) => Review(
        id: map['id'] as String,
        doctorId: map['doctorId'] as String,
        patientId: map['patientId'] as String,
        patientName: map['patientName'] as String? ?? 'Patient',
        appointmentId: map['appointmentId'] as String? ?? '',
        rating: (map['rating'] as num).toDouble(),
        comment: map['comment'] as String? ?? '',
        createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'doctorId': doctorId,
        'patientId': patientId,
        'patientName': patientName,
        'appointmentId': appointmentId,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt,
      };
}
