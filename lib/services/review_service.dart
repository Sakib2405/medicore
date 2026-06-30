import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/review_model.dart';

class ReviewService {
  static final _db = FirebaseFirestore.instance;

  /// Stream all reviews for a doctor, newest first.
  static Stream<List<Review>> streamDoctorReviews(String doctorId) {
    return _db
        .collection('reviews')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Review.fromMap(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Check if this patient already submitted a review for this appointment.
  static Future<Review?> getExistingReview({
    required String patientId,
    required String appointmentId,
  }) async {
    final snap = await _db
        .collection('reviews')
        .where('patientId', isEqualTo: patientId)
        .where('appointmentId', isEqualTo: appointmentId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Review.fromMap(snap.docs.first.data());
  }

  /// Submit a new review and update the doctor's aggregate rating.
  static Future<void> submitReview({
    required String doctorId,
    required String patientId,
    required String patientName,
    required String appointmentId,
    required double rating,
    required String comment,
  }) async {
    final id = const Uuid().v4();
    final review = Review(
      id: id,
      doctorId: doctorId,
      patientId: patientId,
      patientName: patientName,
      appointmentId: appointmentId,
      rating: rating,
      comment: comment,
      createdAt: Timestamp.now(),
    );

    final batch = _db.batch();

    // Save review doc
    batch.set(_db.collection('reviews').doc(id), review.toMap());

    // Update doctor aggregate rating atomically
    batch.update(_db.collection('doctors').doc(doctorId), {
      'rating': FieldValue.increment(rating),
      'totalRatings': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Helper: compute display average from Firestore doctor fields.
  static double computeAverage(double ratingSum, int totalRatings) {
    if (totalRatings == 0) return 0;
    return ratingSum / totalRatings;
  }
}
