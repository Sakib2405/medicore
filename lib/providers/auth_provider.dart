// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medicore/models/user.dart' as app_model; // Added alias
import 'package:medicore/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  app_model.User? _currentUser; // Using alias
  bool _isLoading = false;
  String? _error;
  StreamSubscription<app_model.User?>? _userSubscription; // Using alias
  StreamSubscription<User?>? _firebaseUserSubscription;

  app_model.User? get currentUser => _currentUser; // Using alias
  User? get currentFirebaseUser => _authService.currentFirebaseUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  String get userRole => _currentUser?.role ?? 'patient';

  AuthProvider() {
    _listenToUserChanges();
    _initializeCurrentUser();
    _listenToFirebaseAuthChanges();
  }

  void _listenToUserChanges() {
    _userSubscription = _authService.userStream.listen((app_model.User? user) {
      // Using alias
      _currentUser = user;
      notifyListeners();
    });
  }

  void _listenToFirebaseAuthChanges() {
    _firebaseUserSubscription =
        _firebaseAuth.authStateChanges().listen((User? user) {
      if (user == null) {
        _currentUser = null;
      } else {
        _refreshCurrentUser();
      }
      notifyListeners();
    });
  }

  Future<void> _initializeCurrentUser() async {
    try {
      _setLoading(true);
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // FIXED: Google Sign In
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      print('Starting Google Sign In...');
      _currentUser = await _authService.signInWithGoogle();
      print('Google Sign In completed. User: $_currentUser');
      return _currentUser != null;
    } catch (e) {
      print('Google Sign In Error: $e');
      _setError('Google Sign In failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // FIXED: Facebook Sign In
  Future<bool> signInWithFacebook() async {
    _setLoading(true);
    _setError(null);
    try {
      print('Starting Facebook Sign In...');
      _currentUser = await _authService.signInWithFacebook();
      print('Facebook Sign In completed. User: $_currentUser');
      return _currentUser != null;
    } catch (e) {
      print('Facebook Sign In Error: $e');
      _setError('Facebook Sign In failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Apple Sign In
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _setError(null);
    try {
      print('Starting Apple Sign In...');
      _currentUser = await _authService.signInWithApple();
      print('Apple Sign In completed. User: $_currentUser');
      return _currentUser != null;
    } catch (e) {
      print('Apple Sign In Error: $e');
      _setError('Apple Sign In failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Twitter Sign In
  Future<bool> signInWithTwitter() async {
    _setLoading(true);
    _setError(null);
    try {
      print('Starting Twitter Sign In...');
      _setError('Twitter Sign In is not yet implemented');
      return false;
    } catch (e) {
      print('Twitter Sign In Error: $e');
      _setError('Twitter Sign In failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: GitHub Sign In
  Future<bool> signInWithGitHub() async {
    _setLoading(true);
    _setError(null);
    try {
      print('Starting GitHub Sign In...');
      final provider = GithubAuthProvider();
      provider.addScope('read:user');
      provider.setCustomParameters({'allow_signup': 'false'});

      final userCredential = await _firebaseAuth.signInWithProvider(provider);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        _setError('GitHub Sign In failed: no user returned');
        return false;
      }

      final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        await userDocRef.set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'name': firebaseUser.displayName ?? '',
          'phone': firebaseUser.phoneNumber ?? '',
          'photoUrl': firebaseUser.photoURL,
          'profileImage': firebaseUser.photoURL,
          'role': 'patient',
          'isVerified': firebaseUser.emailVerified,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userDocRef.update({
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final freshUserDoc = await userDocRef.get();
      final data = freshUserDoc.data();
      if (data != null) {
        _currentUser = app_model.User.fromMap(data, id: freshUserDoc.id);
      }

      print('GitHub Sign In completed. User: $_currentUser');
      notifyListeners();
      return _currentUser != null;
    } catch (e) {
      print('GitHub Sign In Error: $e');
      _setError('GitHub Sign In failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginPatient(String email, String password) async {
    return _login(_authService.loginPatient(email, password));
  }

  Future<bool> loginDoctor(String email, String password) async {
    return _login(_authService.loginDoctor(email, password));
  }

  Future<bool> loginAdmin(String email, String password) async {
    return _login(_authService.loginAdmin(email, password));
  }

  // NEW: Login with email link (passwordless)
  Future<bool> signInWithEmailLink(String email, String emailLink) async {
    return _login(_authService.signInWithEmailLink(email, emailLink));
  }

  // NEW: Send sign-in link to email
  Future<bool> sendSignInLinkToEmail(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.sendSignInLinkToEmail(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> loginWithPhone(String phoneNumber) async {
    _setLoading(true);
    _setError(null);
    try {
      final verificationId = await _authService.signInWithPhone(phoneNumber);
      return verificationId;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyPhoneOtp(String verificationId, String smsCode) async {
    return _login(_authService.verifyPhoneOtp(verificationId, smsCode));
  }

  // NEW: Verify phone number for existing user
  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.verifyPhoneNumber(phoneNumber);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _login(Future<app_model.User?> loginFuture) async {
    // Using alias
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await loginFuture;
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signup(
      String email, String password, String name, String phone) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.signup(email, password, name, phone);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Enhanced signup with additional fields
  Future<bool> signupWithDetails({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? gender,
    int? age,
    Map<String, dynamic>? healthProfile,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.signupWithDetails(
        email: email,
        password: password,
        name: name,
        phone: phone,
        gender: gender,
        age: age,
        healthProfile: healthProfile,
      );
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Signup with email verification
  Future<bool> signupWithVerification(
      String email, String password, String name, String phone) async {
    _setLoading(true);
    _setError(null);
    try {
      _currentUser = await _authService.signupWithVerification(
          email, password, name, phone);
      return _currentUser != null;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Enhanced profile update method with Map support
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _setLoading(true);
    _setError(null);
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) {
        _setError('No user logged in');
        return false;
      }

      print('Updating profile for user: ${currentFirebaseUser.uid}');
      print('Updates: $updates');

      // Prepare update data
      final updateData = {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(currentFirebaseUser.uid)
          .update(updateData);
      print('Updated Firestore user document');

      // Update local state by calling _refreshCurrentUser to fetch the latest data
      await _refreshCurrentUser();

      await _syncDoctorProfileDocument();

      // Optional: Update local state immediately if _refreshCurrentUser is not needed,
      // but relying on _refreshCurrentUser is more robust.
      // if (_currentUser != null) {
      //   _currentUser = _currentUser!.copyWith(
      //     name: updates['name'] ?? _currentUser!.name,
      //     phone: updates['phone'] ?? _currentUser!.phone,
      //     gender: updates['gender'] ?? _currentUser!.gender,
      //     age: updates['age'] ?? _currentUser!.age,
      //   );
      // }

      notifyListeners();
      print('Profile update completed successfully');
      return true;
    } catch (e) {
      print('Error in updateProfile: $e');
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Update health profile
  Future<bool> updateHealthProfile(Map<String, dynamic> healthUpdates) async {
    _setLoading(true);
    _setError(null);
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) {
        _setError('No user logged in');
        return false;
      }

      print('Updating health profile for user: ${currentFirebaseUser.uid}');
      print('Health updates: $healthUpdates');

      // Get current health profile
      final userDoc = await _firestore
          .collection('users')
          .doc(currentFirebaseUser.uid)
          .get();
      final data = userDoc.data();
      final Map<String, dynamic> currentHealthProfile =
          (data?['healthProfile'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};

      // Merge updates with current health profile
      final Map<String, dynamic> updatedHealthProfile = {
        ...currentHealthProfile,
        ...healthUpdates,
      };

      // Update in Firestore
      await _firestore.collection('users').doc(currentFirebaseUser.uid).update({
        'healthProfile': updatedHealthProfile,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Updated health profile in Firestore');

      // Update local state by calling _refreshCurrentUser to fetch the latest data
      await _refreshCurrentUser();

      notifyListeners();
      print('Health profile update completed successfully');
      return true;
    } catch (e) {
      print('Error in updateHealthProfile: $e');
      _setError('Failed to update health profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Update email address
  Future<bool> updateEmail(String newEmail) async {
    _setLoading(true);
    _setError(null);
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) {
        _setError('No user logged in');
        return false;
      }

      print('Updating email for user: ${currentFirebaseUser.uid}');
      print('New email: $newEmail');

      // Update in Firebase Auth
      await currentFirebaseUser.verifyBeforeUpdateEmail(newEmail);
      print('Email update verification sent');

      // Update in Firestore
      await _firestore.collection('users').doc(currentFirebaseUser.uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Updated email in Firestore');

      // Update local state
      await _refreshCurrentUser();

      await _syncDoctorProfileDocument();

      notifyListeners();
      print('Email update process initiated successfully');
      return true;
    } catch (e) {
      print('Error in updateEmail: $e');
      _setError('Failed to update email: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // UPDATED: Enhanced profile image update method
  Future<bool> updateProfileImage(String imageUrl) async {
    _setLoading(true);
    _setError(null);
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) {
        _setError('No user logged in');
        return false;
      }

      print(
          'Starting profile image update for user: ${currentFirebaseUser.uid}');
      print('New image URL: $imageUrl');

      // Update in Firebase Auth
      await currentFirebaseUser.updatePhotoURL(imageUrl);
      print('Updated Firebase Auth photo URL');

      // Update in Firestore
      await _firestore.collection('users').doc(currentFirebaseUser.uid).update({
        'photoUrl': imageUrl,
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Updated Firestore user document');

      // Update local state
      await _refreshCurrentUser();

      await _syncDoctorProfileDocument();

      notifyListeners();
      print('Profile image update completed successfully');
      return true;
    } catch (e) {
      print('Error in updateProfileImage: $e');
      _setError('Failed to update profile image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Remove profile image
  Future<bool> removeProfileImage() async {
    _setLoading(true);
    _setError(null);
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) {
        _setError('No user logged in');
        return false;
      }

      // Update in Firebase Auth
      await currentFirebaseUser.updatePhotoURL(null);
      print('Removed Firebase Auth photo URL');

      // Update in Firestore
      await _firestore.collection('users').doc(currentFirebaseUser.uid).update({
        'photoUrl': FieldValue.delete(),
        'profileImage': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Removed profile image from Firestore');

      // Update local state
      await _refreshCurrentUser();

      await _syncDoctorProfileDocument();

      notifyListeners();
      print('Profile image removed successfully');
      return true;
    } catch (e) {
      print('Error in removeProfileImage: $e');
      _setError('Failed to remove profile image: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Direct Firestore update method for additional user fields
  Future<bool> updateUserData(Map<String, dynamic> updateData) async {
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) return false;

      await _firestore.collection('users').doc(currentFirebaseUser.uid).update({
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh local user data
      await _refreshCurrentUser();

      await _syncDoctorProfileDocument();
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  Future<void> _syncDoctorProfileDocument() async {
    try {
      final currentUser = _currentUser;
      final currentFirebaseUser = _firebaseAuth.currentUser;

      if (currentUser == null ||
          currentFirebaseUser == null ||
          !currentUser.isDoctor) {
        return;
      }

      await _firestore.collection('doctors').doc(currentFirebaseUser.uid).set({
        'uid': currentUser.id,
        'name': currentUser.name,
        'email': currentUser.email,
        'specialty': currentUser.specialization ?? '',
        'phone': currentUser.phone,
        'experienceYears': currentUser.experienceYears,
        'clinicName': currentUser.clinicName,
        'clinicAddress': currentUser.clinicAddress,
        'bio': currentUser.professionalInfo?['bio']?.toString(),
        'workingHours': currentUser.professionalInfo?['workingHours'],
        'imageUrl': currentUser.displayPhoto.isNotEmpty
            ? currentUser.displayPhoto
            : null,
        'isAvailable': currentUser.isActive,
        'rating': currentUser.rating,
        'totalRatings': currentUser.reviewCount ?? 0,
        'consultationFee': currentUser.consultationFee,
        'licenseNumber': currentUser.licenseNumber,
        'isVerified': currentUser.isUserVerified,
        'verificationStatus': currentUser.verificationStatus,
        'createdAt': currentUser.createdAt != null
            ? Timestamp.fromDate(currentUser.createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Failed to sync doctor profile document: $e');
    }
  }

  // NEW: Refresh current user data from Firestore
  Future<void> _refreshCurrentUser() async {
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentFirebaseUser.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            _currentUser = app_model.User.fromMap(
              userData,
              id: userDoc.id,
            ); // Using alias
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error refreshing current user: $e');
    }
  }

  // NEW: Force refresh current user
  Future<void> refreshUser() async {
    await _refreshCurrentUser();
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    _setLoading(true);
    _setError(null);
    try {
      final success =
          await _authService.changePassword(currentPassword, newPassword);
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Change password with reauthentication
  Future<bool> changePasswordWithReauth(
      String currentPassword, String newPassword) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _authService.changePasswordWithReauth(
          currentPassword, newPassword);
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Send password reset email with custom settings
  Future<bool> sendPasswordResetEmail(String email,
      [ActionCodeSettings? actionCodeSettings]) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.sendPasswordResetEmail(email, actionCodeSettings);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Confirm password reset
  Future<bool> confirmPasswordReset(String code, String newPassword) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.confirmPasswordReset(code, newPassword);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Check if password reset code is valid
  Future<bool> verifyPasswordResetCode(String code) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.verifyPasswordResetCode(code);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyEmail() async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Send email verification with custom settings
  Future<bool> sendEmailVerification(
      [ActionCodeSettings? actionCodeSettings]) async {
    _setLoading(true);
    _setError(null);
    try {
      await _authService.sendEmailVerification();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> checkEmailVerification() async {
    try {
      final isVerified = await _authService.checkEmailVerification();
      if (isVerified && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(isVerified: true);
        notifyListeners();
      }
      return isVerified;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // NEW: Reload user to check email verification status
  Future<void> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      await _refreshCurrentUser();
    } catch (e) {
      print('Error reloading user: $e');
    }
  }

  // FIX: Renamed from logout() to signOut()
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.logout();
      _currentUser = null;
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // NEW: Logout from all devices
  Future<void> logoutFromAllDevices() async {
    try {
      _setLoading(true);
      await _authService.logoutFromAllDevices();
      _currentUser = null;
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _authService.deleteUserAccount();
      if (success) {
        _currentUser = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // NEW: Delete account with reauthentication
  Future<bool> deleteAccountWithReauth(String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _authService.deleteAccountWithReauth(password);
      if (success) {
        _currentUser = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> checkCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // NEW: Get user by ID
  Future<app_model.User?> getUserById(String userId) async {
    // Using alias
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return app_model.User.fromMap(userDoc.data()!,
            id: userDoc.id); // Using alias
      }
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // NEW: Get multiple users by IDs
  Future<List<app_model.User>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final users = <app_model.User>[];
      for (final userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          users.add(app_model.User.fromMap(userDoc.data()!, id: userDoc.id));
        }
      }
      return users;
    } catch (e) {
      print('Error getting users by IDs: $e');
      return [];
    }
  }

  // NEW: Update user statistics
  Future<bool> updateUserStats({
    int? appointmentCount,
    int? orderCount,
    int? medicalRecordCount,
  }) async {
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) return false;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (appointmentCount != null) {
        updateData['appointmentCount'] = appointmentCount;
      }
      if (orderCount != null) {
        updateData['orderCount'] = orderCount;
      }
      if (medicalRecordCount != null) {
        updateData['medicalRecordCount'] = medicalRecordCount;
      }

      await _firestore
          .collection('users')
          .doc(currentFirebaseUser.uid)
          .update(updateData);

      // Update local state
      await _refreshCurrentUser();

      return true;
    } catch (e) {
      print('Error updating user stats: $e');
      return false;
    }
  }

  // NEW: Increment user statistics
  Future<bool> incrementUserStats({
    int appointmentIncrement = 0,
    int orderIncrement = 0,
    int medicalRecordIncrement = 0,
  }) async {
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) return false;

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (appointmentIncrement != 0) {
        updateData['appointmentCount'] =
            FieldValue.increment(appointmentIncrement);
      }
      if (orderIncrement != 0) {
        updateData['orderCount'] = FieldValue.increment(orderIncrement);
      }
      if (medicalRecordIncrement != 0) {
        updateData['medicalRecordCount'] =
            FieldValue.increment(medicalRecordIncrement);
      }

      await _firestore
          .collection('users')
          .doc(currentFirebaseUser.uid)
          .update(updateData);

      // Update local state
      await _refreshCurrentUser();

      return true;
    } catch (e) {
      print('Error incrementing user stats: $e');
      return false;
    }
  }

  // NEW: Get current user ID
  String? get currentUserId {
    return _firebaseAuth.currentUser?.uid;
  }

  // NEW: Check if user is authenticated
  bool get isAuthenticated {
    return _firebaseAuth.currentUser != null && _currentUser != null;
  }

  // NEW: Stream for real-time user updates
  Stream<app_model.User?> get userStream {
    final currentUserId = _firebaseAuth.currentUser?.uid;
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return app_model.User.fromMap(snapshot.data()!, id: snapshot.id);
      }
      return null;
    });
  }

  // NEW: Stream for user list updates
  Stream<List<app_model.User>> getUsersStream(List<String> userIds) {
    if (userIds.isEmpty) return Stream.value([]);

    return _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: userIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => app_model.User.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  // NEW: Update user role
  Future<bool> updateUserRole(String newRole) async {
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) return false;

      await _firestore.collection('users').doc(currentFirebaseUser.uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local state
      await _refreshCurrentUser();

      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // NEW: Check if user has specific role
  bool hasRole(String role) {
    return _currentUser?.role == role;
  }

  // NEW: Check if user has any of the specified roles
  bool hasAnyRole(List<String> roles) {
    return roles.contains(_currentUser?.role);
  }

  // NEW: Get user display name
  String get displayName {
    return _currentUser?.name ??
        _firebaseAuth.currentUser?.displayName ??
        'User';
  }

  // NEW: Get user email
  String get userEmail {
    return _currentUser?.email ?? _firebaseAuth.currentUser?.email ?? '';
  }

  // NEW: Get user phone number
  String get userPhone {
    return _currentUser?.phone ?? '';
  }

  // NEW: Get user profile image URL
  String get profileImageUrl {
    return _currentUser?.photoUrl ??
        _currentUser?.profileImage ??
        _firebaseAuth.currentUser?.photoURL ??
        '';
  }

  // NEW: Check if user profile is complete
  bool get isProfileComplete {
    if (_currentUser == null) return false;

    return _currentUser!.name.isNotEmpty &&
        _currentUser!.email.isNotEmpty &&
        _currentUser!.phone.isNotEmpty;
  }

  // NEW: Get profile completion percentage
  double get profileCompletionPercentage {
    if (_currentUser == null) return 0.0;

    int completedFields = 0;
    int totalFields = 4; // name, email, phone, profile image

    if (_currentUser!.name.isNotEmpty) completedFields++;
    if (_currentUser!.email.isNotEmpty) completedFields++;
    if (_currentUser!.phone.isNotEmpty) completedFields++;
    if (profileImageUrl.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  // NEW: Get user creation date
  DateTime? get userCreationDate {
    return _currentUser?.createdAt;
  }

  // NEW: Get user age in years
  int? get userAge {
    return _currentUser?.age;
  }

  // NEW: Get user gender
  String? get userGender {
    return _currentUser?.gender;
  }

  // NEW: Check if user is verified
  bool get isEmailVerified {
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  // NEW: Check if user is anonymous
  bool get isAnonymous {
    return _firebaseAuth.currentUser?.isAnonymous ?? false;
  }

  // NEW: Get user metadata
  UserMetadata? get userMetadata {
    return _firebaseAuth.currentUser?.metadata;
  }

  // NEW: Get user creation time
  DateTime? get accountCreationTime {
    return _firebaseAuth.currentUser?.metadata.creationTime;
  }

  // NEW: Get last sign-in time
  DateTime? get lastSignInTime {
    return _firebaseAuth.currentUser?.metadata.lastSignInTime;
  }

  // NEW: Get user provider data
  List<UserInfo> get userProviders {
    return _firebaseAuth.currentUser?.providerData ?? [];
  }

  // NEW: Check if user has specific provider
  bool hasProvider(String providerId) {
    return userProviders.any((provider) => provider.providerId == providerId);
  }

  // NEW: Link with other auth providers
  Future<bool> linkWithGoogle() async {
    try {
      await _authService.linkWithGoogle();
      await _refreshCurrentUser();
      return true;
    } catch (e) {
      _setError('Failed to link Google account: $e');
      return false;
    }
  }

  Future<bool> linkWithFacebook() async {
    try {
      await _authService.linkWithFacebook();
      await _refreshCurrentUser();
      return true;
    } catch (e) {
      _setError('Failed to link Facebook account: $e');
      return false;
    }
  }

  // NEW: Unlink auth provider
  Future<bool> unlinkProvider(String providerId) async {
    try {
      await _authService.unlinkProvider(providerId);
      await _refreshCurrentUser();
      return true;
    } catch (e) {
      _setError('Failed to unlink provider: $e');
      return false;
    }
  }

  // NEW: Reauthenticate user
  Future<bool> reauthenticate(String password) async {
    try {
      await _authService.reauthenticate(password);
      return true;
    } catch (e) {
      _setError('Reauthentication failed: $e');
      return false;
    }
  }

  // NEW: Reauthenticate with credential
  Future<bool> reauthenticateWithCredential(AuthCredential credential) async {
    try {
      await _authService.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      _setError('Reauthentication failed: $e');
      return false;
    }
  }

  // NEW: Get user session token
  Future<String?> getSessionToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken();
    } catch (e) {
      print('Error getting session token: $e');
      return null;
    }
  }

  // NEW: Get user session token with force refresh
  Future<String?> getFreshSessionToken() async {
    try {
      return await _firebaseAuth.currentUser?.getIdToken(true);
    } catch (e) {
      print('Error getting fresh session token: $e');
      return null;
    }
  }

  // NEW: Check if user needs to reauthenticate
  bool get needsReauth {
    final lastSignIn = lastSignInTime;
    if (lastSignIn == null) return false;

    // Consider reauth needed if last sign-in was more than 30 days ago
    return DateTime.now().difference(lastSignIn).inDays > 30;
  }

  // NEW: Get user preferences
  Map<String, dynamic>? get userPreferences {
    // Rely on _currentUser to have the full data, or retrieve it directly if needed.
    // For now, assume it's part of the User model's dynamic fields if present.
    // Since the provided app_model.User isn't visible, we'll try to retrieve the raw data.
    if (currentUserId == null) return null;
    // We can't synchronously get the preferences, so return null, or add a method.
    // For simplicity with the existing model, let's keep it minimal or add a fetcher.
    return null;
  }

  // NEW: Update user preferences
  Future<bool> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser == null) return false;

      await _firestore.collection('users').doc(currentFirebaseUser.uid).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Refresh local state
      await _refreshCurrentUser();

      return true;
    } catch (e) {
      print('Error updating user preferences: $e');
      return false;
    }
  }

  // NEW: Get user activity status
  bool get isUserActive {
    // Consider user active if they've signed in within the last 7 days
    final lastSignIn = lastSignInTime;
    if (lastSignIn == null) return false;
    return DateTime.now().difference(lastSignIn).inDays <= 7;
  }

  // NEW: Get user membership duration in days
  int get membershipDurationInDays {
    final creationTime = accountCreationTime;
    if (creationTime == null) return 0;
    return DateTime.now().difference(creationTime).inDays;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _firebaseUserSubscription?.cancel();
    super.dispose();
  }
}
