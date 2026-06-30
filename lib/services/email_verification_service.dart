import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class EmailVerificationService {
  static final EmailVerificationService _instance =
      EmailVerificationService._internal();

  factory EmailVerificationService() {
    return _instance;
  }

  EmailVerificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _verificationCollection = 'email_verifications';
  static const int _codeLength = 6;
  static const int _codeExpiryMinutes = 15;

  /// Generate a random 6-digit verification code
  String _generateCode() {
    final random = Random();
    return List.generate(_codeLength, (_) => random.nextInt(10)).join();
  }

  /// Send verification code to email
  /// In production, integrate with email service (Firebase, SendGrid, Mailgun, etc.)
  Future<String> sendVerificationCode(String email) async {
    try {
      final code = _generateCode();
      final expiryTime =
          DateTime.now().add(Duration(minutes: _codeExpiryMinutes));

      // Store verification code in Firestore
      await _firestore.collection(_verificationCollection).doc(email).set({
        'code': code,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiryTime,
        'attempts': 0,
        'verified': false,
      });

      // TODO: In production, integrate with email service
      // Options: Firebase Cloud Functions, SendGrid, Mailgun, AWS SES
      // This will send the code via email instead of returning it

      return code; // Return for debugging/testing only
    } catch (e) {
      throw Exception('Failed to send verification code: $e');
    }
  }

  /// Verify the code entered by user
  Future<bool> verifyCode(String email, String code) async {
    try {
      final docRef =
          _firestore.collection(_verificationCollection).doc(email);
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Verification code expired or not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      final attempts = (data['attempts'] as int?) ?? 0;

      // Check if code is expired
      if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        throw Exception('Verification code expired');
      }

      // Check if too many attempts
      if (attempts >= 5) {
        throw Exception('Too many failed attempts. Please request a new code.');
      }

      // Verify code
      if (storedCode != code) {
        // Increment attempts
        await docRef.update({
          'attempts': attempts + 1,
        });
        throw Exception('Invalid verification code');
      }

      // Mark as verified
      await docRef.update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      throw Exception('Code verification failed: $e');
    }
  }

  /// Check if email is already verified
  Future<bool> isEmailVerified(String email) async {
    try {
      final doc = await _firestore
          .collection(_verificationCollection)
          .doc(email)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      return data['verified'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Resend verification code
  Future<String> resendCode(String email) async {
    try {
      // Delete old code
      await _firestore.collection(_verificationCollection).doc(email).delete();

      // Send new code
      return await sendVerificationCode(email);
    } catch (e) {
      throw Exception('Failed to resend verification code: $e');
    }
  }

  /// Clean up expired codes (call periodically)
  Future<void> cleanupExpiredCodes() async {
    try {
      final now = DateTime.now();
      final expiredDocs = await _firestore
          .collection(_verificationCollection)
          .where('expiresAt', isLessThan: now)
          .get();

      for (final doc in expiredDocs.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      // Error cleaning up expired codes
    }
  }
}
