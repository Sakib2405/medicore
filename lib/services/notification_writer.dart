import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationWriter {
  static final _fs = FirebaseFirestore.instance;

  static Future<void> write({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? payload,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _fs
          .collection('notifications')
          .doc(userId)
          .collection('user_notifications')
          .add({
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'payload': payload ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notification failure must not break the main flow
    }
  }
}
