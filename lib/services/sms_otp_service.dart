import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SmsOtpService {
  static final SmsOtpService _instance = SmsOtpService._internal();

  factory SmsOtpService() {
    return _instance;
  }

  SmsOtpService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _otpCollection = 'phone_verifications';

  /// Send OTP to phone number
  /// Uses Firebase Phone Authentication
  Future<void> sendOtpToPhone(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(FirebaseAuthException) onError,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-complete on Android
          try {
            await _auth.signInWithCredential(credential);
          } catch (e) {
            // Auto sign-in error handled silently
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          // Save verification ID to use later
          _firestore.collection(_otpCollection).doc(phoneNumber).set({
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
            'createdAt': FieldValue.serverTimestamp(),
            'verified': false,
            'attempts': 0,
          });
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Code auto-retrieval timeout
        },
      );
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// Verify OTP code
  Future<UserCredential> verifyOtpCode(
    String verificationId,
    String otp,
    String phoneNumber,
  ) async {
    try {
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Update attempts in Firestore
      final docRef = _firestore.collection(_otpCollection).doc(phoneNumber);
      final doc = await docRef.get();
      final attempts = (doc.data()?['attempts'] as int?) ?? 0;

      if (attempts >= 5) {
        throw FirebaseAuthException(
          code: 'too-many-attempts',
          message: 'Too many failed attempts. Please request a new OTP.',
        );
      }

      // Try to sign in
      try {
        final userCredential =
            await _auth.signInWithCredential(phoneCredential);

        // Mark as verified
        await docRef.update({
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        return userCredential;
      } catch (e) {
        // Increment attempts
        await docRef.update({
          'attempts': attempts + 1,
        });
        throw FirebaseAuthException(
          code: 'invalid-verification-code',
          message: 'Invalid OTP code',
        );
      }
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  /// Resend OTP
  Future<void> resendOtp(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(FirebaseAuthException) onError,
  ) async {
    try {
      // Delete old record
      await _firestore.collection(_otpCollection).doc(phoneNumber).delete();

      // Send new OTP
      await sendOtpToPhone(phoneNumber, onCodeSent, onError);
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }
}
