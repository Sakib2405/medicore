// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:medicore/config/google_signin_config.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:medicore/models/doctor_model.dart';
import 'package:medicore/models/user.dart';
import 'package:medicore/services/doctor_service.dart';
import 'dart:async';

class AuthService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DoctorService _doctorService = DoctorService();
  late final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth = FacebookAuth.instance;

  static const String _adminEmail = 'admin@gmail.com';
  static const String _adminPassword = '123456';

  AuthService() {
    // Initialize GoogleSignIn appropriately for web and non-web.
    if (kIsWeb && googleSignInClientId.isNotEmpty) {
      _googleSignIn = GoogleSignIn(
        clientId: googleSignInClientId,
        scopes: <String>['email', 'profile', 'openid'],
      );
    } else {
      _googleSignIn =
          GoogleSignIn(scopes: <String>['email', 'profile', 'openid']);
    }
  }

  Stream<User?> get userStream {
    return _auth.authStateChanges().asyncMap((auth.User? authUser) async {
      if (authUser == null) return null;

      try {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(authUser.uid).get();
        if (doc.exists) {
          return User.fromFirestore(doc);
        }
        return null;
      } catch (e) {
        print('Error in userStream: $e');
        return null;
      }
    });
  }

  // NEW: Stream for user profile updates
  Stream<User?> userProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
        (snapshot) => snapshot.exists ? User.fromFirestore(snapshot) : null);
  }

  Future<User?> getCurrentUser() async {
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) return null;

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(authUser.uid).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // NEW: Get current Firebase user
  auth.User? get currentFirebaseUser => _auth.currentUser;

  Future<User?> loginPatient(String email, String password) async {
    try {
      auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists && doc['role'] == 'patient') {
        return User.fromFirestore(doc);
      } else {
        await _auth.signOut();
        throw Exception("Access Denied: Not a patient account.");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> loginDoctor(String email, String password) async {
    try {
      auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists && doc['role'] == 'doctor') {
        return User.fromFirestore(doc);
      } else {
        await _auth.signOut();
        throw Exception("Access Denied: Not a doctor account.");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> loginAdmin(String email, String password) async {
    try {
      if (email == _adminEmail && password == _adminPassword) {
        // Sign in to Firebase Auth (create account if it doesn't exist yet)
        auth.UserCredential userCredential;
        try {
          userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on auth.FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' ||
              e.code == 'invalid-credential' ||
              e.code == 'INVALID_LOGIN_CREDENTIALS') {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } else {
            rethrow;
          }
        }

        final uid = userCredential.user!.uid;
        final adminDocRef = _firestore.collection('users').doc(uid);
        final adminDoc = await adminDocRef.get();

        if (!adminDoc.exists) {
          await adminDocRef.set({
            'uid': uid,
            'email': email,
            'name': 'Administrator',
            'role': 'admin',
            'phone': '',
            'isVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'authProvider': 'email',
          });
        } else if (adminDoc.data()?['role'] != 'admin') {
          await adminDocRef.update({
            'role': 'admin',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        final fresh = await adminDocRef.get();
        return User.fromFirestore(fresh);
      }

      auth.UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists && doc['role'] == 'admin') {
        return User.fromFirestore(doc);
      } else {
        await _auth.signOut();
        throw Exception("Access Denied: Not an admin account.");
      }
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Login with email and password (generic)
  Future<User?> loginWithEmailAndPassword(String email, String password) async {
    try {
      auth.UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        return User.fromFirestore(doc);
      } else {
        await _auth.signOut();
        throw Exception("User account not found.");
      }
    } catch (e) {
      rethrow;
    }
  }

  // IMPROVED: Google Sign In with better error handling
  Future<User?> signInWithGoogle() async {
    try {
      print('Starting Google Sign In process...');

      // Check if Google Sign In is available
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign In cancelled by user');
        throw Exception('Sign in cancelled by user');
      }

      print('Google user obtained: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Accept flows where either idToken OR accessToken is provided by Google
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        print(
            'GoogleSignIn returned no tokens: accessToken and idToken are both null');
        throw Exception('Failed to get authentication tokens from Google');
      }
      if (googleAuth.idToken == null) {
        print('Warning: idToken is null; proceeding with accessToken only');
      }

      final auth.OAuthCredential credential =
          auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in with Firebase...');
      auth.UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } on auth.FirebaseAuthException catch (e) {
        print(
            'FirebaseAuthException during signInWithCredential: code=${e.code} message=${e.message}');

        // Try recovery for common malformed/expired token errors
        final recoverable = {
          'invalid-credential',
          'user-token-expired',
          'invalid-verification-code',
          'invalid-id-token',
        };

        if (recoverable.contains(e.code)) {
          try {
            print('Attempting signInSilently() to refresh Google tokens...');
            final GoogleSignInAccount? silent =
                await _googleSignIn.signInSilently();
            if (silent != null) {
              final GoogleSignInAuthentication refreshed =
                  await silent.authentication;
              final auth.OAuthCredential refreshedCred =
                  auth.GoogleAuthProvider.credential(
                accessToken: refreshed.accessToken,
                idToken: refreshed.idToken,
              );
              print('Retrying signInWithCredential with refreshed tokens...');
              userCredential = await _auth.signInWithCredential(refreshedCred);
            } else {
              print(
                  'Silent sign-in returned null — signing out to clear state');
              await _googleSignIn.signOut();
              throw auth.FirebaseAuthException(
                  code: 'token-expired',
                  message:
                      'Authentication tokens expired or invalid. Please sign in again.');
            }
          } catch (retryErr) {
            print('Retry after signInSilently failed: $retryErr');
            await _googleSignIn.signOut();
            rethrow;
          }
        } else {
          await _googleSignIn.signOut();
          rethrow;
        }
      }
      final auth.UserCredential finalUserCredential = userCredential;
      final auth.User? user = finalUserCredential.user;

      if (user != null) {
        print('Firebase user signed in: ${user.uid}');

        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          print('Existing user found, returning user data');
          return User.fromFirestore(doc);
        } else {
          print('Creating new user document in Firestore');
          final newUser = User(
            id: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'User',
            role: 'patient',
            phone: user.phoneNumber ?? '',
            isVerified: user.emailVerified,
            photoUrl: user.photoURL,
            profileImage: user.photoURL,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            authProvider: 'google', // Track auth provider
          );

          await _firestore
              .collection('users')
              .doc(newUser.id)
              .set(newUser.toMap());
          print('New user created successfully');
          return newUser;
        }
      }
      print('No user returned from Firebase');
      return null;
    } catch (e) {
      final errLower = e.toString().toLowerCase();
      print('Google Sign In Error: $e');
      // Sign out from Google to clear any partial state
      await _googleSignIn.signOut();

      if (errLower.contains('popup_closed')) {
        throw Exception(
            'Google sign-in popup was closed or blocked. Allow popups and try again.');
      }
      if (errLower.contains('malformed') ||
          errLower.contains('invalid') ||
          errLower.contains('expired')) {
        throw Exception(
            'Authentication tokens appear malformed or expired. Please sign in again.');
      }

      rethrow;
    }
  }

  // NEW: Apple Sign In
  Future<User?> signInWithApple() async {
    try {
      // Note: Apple Sign In requires additional setup and platform-specific code
      // This is a placeholder implementation
      throw UnimplementedError('Apple Sign In not implemented yet');
    } catch (e) {
      print('Apple Sign In Error: $e');
      rethrow;
    }
  }

  // NEW: Twitter Sign In
  Future<User?> signInWithTwitter() async {
    try {
      // Note: Twitter Sign In requires additional setup
      // This is a placeholder implementation
      throw UnimplementedError('Twitter Sign In not implemented yet');
    } catch (e) {
      print('Twitter Sign In Error: $e');
      rethrow;
    }
  }

  // NEW: GitHub Sign In
  Future<User?> signInWithGitHub() async {
    try {
      // Note: GitHub Sign In requires additional setup
      // This is a placeholder implementation
      throw UnimplementedError('GitHub Sign In not implemented yet');
    } catch (e) {
      print('GitHub Sign In Error: $e');
      rethrow;
    }
  }

  // NEW: Sign in with email link (passwordless)
  Future<User?> signInWithEmailLink(String email, String emailLink) async {
    try {
      if (auth.FirebaseAuth.instance.isSignInWithEmailLink(emailLink)) {
        final auth.UserCredential userCredential =
            await _auth.signInWithEmailLink(
          email: email,
          emailLink: emailLink,
        );

        if (userCredential.user != null) {
          DocumentSnapshot doc = await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (doc.exists) {
            return User.fromFirestore(doc);
          } else {
            final newUser = User(
              id: userCredential.user!.uid,
              email: email,
              name: email.split('@').first,
              role: 'patient',
              phone: '',
              isVerified: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              authProvider: 'email_link',
            );

            await _firestore
                .collection('users')
                .doc(newUser.id)
                .set(newUser.toMap());
            return newUser;
          }
        }
      }
      throw Exception('Invalid email link');
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Send sign-in link to email
  Future<void> sendSignInLinkToEmail(String email,
      [auth.ActionCodeSettings? actionCodeSettings]) async {
    try {
      final settings = actionCodeSettings ??
          auth.ActionCodeSettings(
            url:
                'https://medicore.page.link/signin', // Replace with your app's URL
            handleCodeInApp: true,
            iOSBundleId:
                'com.example.medicore', // Replace with your iOS bundle ID
            androidPackageName:
                'com.example.medicore', // Replace with your Android package name
            androidInstallApp: true,
            androidMinimumVersion: '12',
          );

      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: settings,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Facebook Sign In
  Future<User?> signInWithFacebook() async {
    try {
      print('Starting Facebook Sign In process...');

      // Trigger Facebook login
      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      print('Facebook login result: ${result.status}');

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        print('Facebook access token obtained');

        // Create Firebase credential
        final auth.OAuthCredential credential =
            auth.FacebookAuthProvider.credential(accessToken.token);

        print('Signing in with Firebase using Facebook credential...');
        final auth.UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final auth.User? user = userCredential.user;

        if (user != null) {
          print('Firebase user signed in: ${user.uid}');

          // Get additional user data from Facebook
          final userData = await _facebookAuth.getUserData();
          print('Facebook user data: $userData');

          DocumentSnapshot doc =
              await _firestore.collection('users').doc(user.uid).get();

          if (doc.exists) {
            print('Existing user found, returning user data');
            return User.fromFirestore(doc);
          } else {
            print('Creating new user document in Firestore');
            final newUser = User(
              id: user.uid,
              email: user.email ?? userData['email'] ?? '',
              name: user.displayName ?? userData['name'] ?? 'User',
              role: 'patient',
              phone: user.phoneNumber ?? '',
              isVerified: user.emailVerified,
              photoUrl: user.photoURL ?? userData['picture']['data']['url'],
              profileImage: user.photoURL ?? userData['picture']['data']['url'],
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              authProvider: 'facebook', // Track auth provider
            );

            await _firestore
                .collection('users')
                .doc(newUser.id)
                .set(newUser.toMap());
            print('New Facebook user created successfully');
            return newUser;
          }
        }
      } else if (result.status == LoginStatus.cancelled) {
        throw Exception('Facebook login cancelled by user');
      } else {
        throw Exception('Facebook login failed: ${result.status}');
      }

      return null;
    } catch (e) {
      print('Facebook Sign In Error: $e');
      // Log out from Facebook if there's an error
      await _facebookAuth.logOut();
      rethrow;
    }
  }

  Future<String?> signInWithPhone(String phoneNumber) async {
    try {
      final completer = Completer<String?>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (auth.PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          completer.complete(null);
        },
        verificationFailed: (auth.FirebaseAuthException e) {
          completer.completeError(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          completer.complete(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          completer.complete(verificationId);
        },
      );

      return completer.future;
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Verify phone number for existing user
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (auth.PhoneAuthCredential credential) async {
          await _auth.currentUser?.linkWithCredential(credential);
        },
        verificationFailed: (auth.FirebaseAuthException e) {
          print('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Store verificationId for later use
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> verifyPhoneOtp(String verificationId, String smsCode) async {
    try {
      final auth.PhoneAuthCredential credential =
          auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final auth.UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final auth.User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot doc =
            await _firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          return User.fromFirestore(doc);
        } else {
          final newUser = User(
            id: user.uid,
            email: user.email ?? user.phoneNumber ?? '',
            name: user.displayName ?? 'User',
            role: 'patient',
            phone: user.phoneNumber ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            authProvider: 'phone',
          );

          await _firestore
              .collection('users')
              .doc(newUser.id)
              .set(newUser.toMap());
          return newUser;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signup(
      String email, String password, String name, String phone) async {
    try {
      auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final newUser = User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: 'patient',
        phone: phone,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        authProvider: 'email',
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());

      await userCredential.user!.sendEmailVerification();

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Enhanced signup with additional fields
  Future<User?> signupWithDetails({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? gender,
    int? age,
    Map<String, dynamic>? healthProfile,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      auth.UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        role: 'patient',
        phone: phone,
        gender: gender ?? '',
        healthProfile: healthProfile ?? <String, dynamic>{},
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        authProvider: 'email',
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());
      await userCredential.user!.sendEmailVerification();

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Signup with email verification
  Future<User?> signupWithVerification(
      String email, String password, String name, String phone) async {
    try {
      final user = await signup(email, password, name, phone);
      await sendEmailVerification();
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Better profile update method
  Future<User?> updateUserProfile(
      String uid, String name, String phone, String? photoUrl) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update both photoUrl and profileImage fields for consistency
      if (photoUrl != null) {
        updateData['profileImage'] = photoUrl;
        updateData['photoUrl'] = photoUrl;

        // Also update Firebase Auth profile photo
        final authUser = _auth.currentUser;
        if (authUser != null) {
          await authUser.updatePhotoURL(photoUrl);
        }
      }

      await _firestore.collection('users').doc(uid).update(updateData);

      // Return updated user
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return User.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Update user data with map
  Future<User?> updateUserData(
      String uid, Map<String, dynamic> updateData) async {
    try {
      final data = {
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).update(data);

      // Return updated user
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return User.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Update health profile
  Future<User?> updateHealthProfile(
      String uid, Map<String, dynamic> healthUpdates) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data();
      final Map<String, dynamic> currentHealthProfile =
          (data?['healthProfile'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};

      final updatedHealthProfile = {
        ...currentHealthProfile,
        ...healthUpdates,
      };

      await _firestore.collection('users').doc(uid).update({
        'healthProfile': updatedHealthProfile,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return User.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  // Separate method for updating only profile image
  Future<User?> updateProfileImage(String imageUrl) async {
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) throw Exception('No user logged in');

      // Update Firebase Auth
      await authUser.updatePhotoURL(imageUrl);

      // Update Firestore
      await _firestore.collection('users').doc(authUser.uid).update({
        'profileImage': imageUrl,
        'photoUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Return updated user
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(authUser.uid).get();
      return User.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Remove profile image
  Future<User?> removeProfileImage() async {
    try {
      final authUser = _auth.currentUser;
      if (authUser == null) throw Exception('No user logged in');

      // Update Firebase Auth
      await authUser.updatePhotoURL(null);

      // Update Firestore
      await _firestore.collection('users').doc(authUser.uid).update({
        'profileImage': FieldValue.delete(),
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Return updated user
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(authUser.uid).get();
      return User.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final auth.AuthCredential credential = auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Change password with reauthentication
  Future<bool> changePasswordWithReauth(
      String currentPassword, String newPassword) async {
    return changePassword(currentPassword, newPassword);
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Send password reset email with custom settings
  Future<void> sendPasswordResetEmail(String email,
      [auth.ActionCodeSettings? actionCodeSettings]) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Confirm password reset
  Future<void> confirmPasswordReset(String code, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Verify password reset code
  Future<String> verifyPasswordResetCode(String code) async {
    try {
      return await _auth.verifyPasswordResetCode(code);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Send email verification with custom settings
  Future<void> sendEmailVerificationWithSettings(
      [auth.ActionCodeSettings? actionCodeSettings]) async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification(actionCodeSettings);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Delete account with reauthentication
  Future<bool> deleteAccountWithReauth(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      final credential = auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // Sign out from all providers
      await _googleSignIn.signOut();
      await _facebookAuth.logOut();
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // NEW: Logout from all devices
  Future<void> logoutFromAllDevices() async {
    try {
      // This would typically involve revoking refresh tokens
      // Firebase doesn't have a direct method, so we sign out and clear data
      await logout();
    } catch (e) {
      rethrow;
    }
  }

  // IMPROVED: Doctor account creation - FIXED DateTime issue
  Future<auth.UserCredential?> createDoctorAccount({
    required String name,
    required String email,
    required String password,
    required String specialty,
    String? bio,
    String? clinicAddress,
    String? phone,
    Map<String, dynamic>? qualifications,
    Map<String, dynamic>? schedule,
  }) async {
    try {
      // Use the main Firebase app instead of creating a temporary one
      auth.UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Create User document
      final doctorUser = User(
        id: uid,
        email: email,
        name: name,
        role: 'doctor',
        phone: phone ?? '',
        specialization: specialty,
        isVerified: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        authProvider: 'email',
      );

      await _firestore.collection('users').doc(uid).set(doctorUser.toMap());

      // Create Doctor profile - FIXED: Added required updatedAt parameter
      Doctor newDoctor = Doctor(
        uid: uid,
        name: name,
        email: email,
        specialty: specialty,
        bio: bio ?? '',
        clinicAddress: clinicAddress ?? '',
        phone: phone,
        isAvailable: true,
        rating: 0.0,
        totalRatings: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), // Fixed: Added required updatedAt parameter
      );

      await _doctorService.createDoctorProfile(newDoctor);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Check if user exists by email
  Future<bool> checkUserExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Re-authenticate user (useful for sensitive operations)
  Future<bool> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;

      final credential = auth.EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  // NEW: Reauthenticate with credential
  Future<bool> reauthenticateWithCredential(
      auth.AuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      return false;
    }
  }

  // NEW: Get user by ID
  Future<User?> getUserById(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // NEW: Get multiple users by IDs
  Future<List<User>> getUsersByIds(List<String> uids) async {
    try {
      if (uids.isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: uids)
          .get();

      return querySnapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error getting users by IDs: $e');
      return [];
    }
  }

  // NEW: Update user role
  Future<bool> updateUserRole(String uid, String newRole) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // NEW: Check if email is verified
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }
    return false;
  }

  // NEW: Link Google account to existing user
  Future<bool> linkWithGoogle() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final auth.OAuthCredential credential =
          auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.linkWithCredential(credential);

      // Update user document with auth provider
      await _firestore.collection('users').doc(user.uid).update({
        'authProvider': 'google',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error linking Google account: $e');
      return false;
    }
  }

  // NEW: Link Facebook account to existing user
  Future<bool> linkWithFacebook() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final LoginResult result = await _facebookAuth.login();
      if (result.status != LoginStatus.success) return false;

      final AccessToken accessToken = result.accessToken!;
      final auth.AuthCredential credential =
          auth.FacebookAuthProvider.credential(accessToken.token);

      await user.linkWithCredential(credential);

      // Update user document with auth provider
      await _firestore.collection('users').doc(user.uid).update({
        'authProvider': 'facebook',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error linking Facebook account: $e');
      return false;
    }
  }

  // NEW: Unlink auth provider
  Future<bool> unlinkProvider(String providerId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.unlink(providerId);

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'authProvider': 'email', // Fallback to email
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error unlinking provider: $e');
      return false;
    }
  }

  // NEW: Get user session token
  Future<String?> getSessionToken([bool forceRefresh = false]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      return await user.getIdToken(forceRefresh);
    } catch (e) {
      print('Error getting session token: $e');
      return null;
    }
  }

  // NEW: Update user preferences
  Future<bool> updateUserPreferences(
      String uid, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating user preferences: $e');
      return false;
    }
  }

  // NEW: Get user statistics
  Future<Map<String, dynamic>> getUserStats(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        return {
          'appointmentCount': data['appointmentCount'] ?? 0,
          'orderCount': data['orderCount'] ?? 0,
          'medicalRecordCount': data['medicalRecordCount'] ?? 0,
          'profileCompletion': _calculateProfileCompletion(data),
        };
      }
      return {};
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  // NEW: Calculate profile completion percentage
  double _calculateProfileCompletion(Map<String, dynamic> userData) {
    int completedFields = 0;
    int totalFields = 5; // name, email, phone, profile image, health profile

    if (userData['name'] != null && (userData['name'] as String).isNotEmpty) {
      completedFields++;
    }
    if (userData['email'] != null && (userData['email'] as String).isNotEmpty) {
      completedFields++;
    }
    if (userData['phone'] != null && (userData['phone'] as String).isNotEmpty) {
      completedFields++;
    }
    if (userData['profileImage'] != null &&
        (userData['profileImage'] as String).isNotEmpty) {
      completedFields++;
    }
    if (userData['healthProfile'] != null &&
        (userData['healthProfile'] as Map).isNotEmpty) {
      completedFields++;
    }

    return completedFields / totalFields;
  }

  // NEW: Check if user needs reauthentication
  bool needsReauth() {
    final user = _auth.currentUser;
    if (user == null || user.metadata.lastSignInTime == null) return false;

    final lastSignIn = user.metadata.lastSignInTime!;
    return DateTime.now().difference(lastSignIn).inDays > 30;
  }

  // NEW: Reload user data
  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      print('Error reloading user: $e');
    }
  }

  // NEW: Get user creation date
  DateTime? getUserCreationDate() {
    final user = _auth.currentUser;
    return user?.metadata.creationTime;
  }

  // NEW: Get last sign-in date
  DateTime? getLastSignInDate() {
    final user = _auth.currentUser;
    return user?.metadata.lastSignInTime;
  }

  // NEW: Get user providers
  List<auth.UserInfo> getUserProviders() {
    final user = _auth.currentUser;
    return user?.providerData ?? [];
  }

  // NEW: Check if user has specific provider
  bool hasProvider(String providerId) {
    final providers = getUserProviders();
    return providers.any((provider) => provider.providerId == providerId);
  }
}
