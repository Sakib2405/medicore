// services/user_service.dart
// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users (real-time stream)
  Stream<List<User>> getUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  // Get users by role
  Stream<List<User>> getUsersByRole(String role) {
    if (role == 'all') {
      return getUsers();
    }
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  // Search users
  Stream<List<User>> searchUsers(String query) {
    return _firestore
        .collection('users')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      final allUsers =
          snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();

      return allUsers.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()) ||
            user.phone.contains(query) ||
            user.role.toLowerCase().contains(query.toLowerCase()) ||
            (user.specialization != null &&
                user.specialization!
                    .toLowerCase()
                    .contains(query.toLowerCase()));
      }).toList();
    });
  }

  // Get user by ID
  Future<User?> getUserById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        return User.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Update user - comprehensive update method
  Future<void> updateUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update({
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'role': user.role,
        'gender': user.gender,
        'isActive': user.isActive,
        'isVerified': user.isVerified,
        'verificationStatus': user.verificationStatus,
        'address': user.address,
        'specialization': user.specialization,
        'licenseNumber': user.licenseNumber,
        'clinicName': user.clinicName,
        'clinicAddress': user.clinicAddress,
        'consultationFee': user.consultationFee,
        'experienceYears': user.experienceYears,
        'profileImage': user.profileImage,
        'photoUrl': user.photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (user.isDoctor) {
        await _firestore.collection('doctors').doc(user.id).set({
          'uid': user.id,
          'name': user.name,
          'email': user.email,
          'specialty': user.specialization ?? '',
          'phone': user.phone,
          'experienceYears': user.experienceYears,
          'clinicName': user.clinicName,
          'clinicAddress': user.clinicAddress,
          'bio': user.professionalInfo?['bio']?.toString(),
          'imageUrl': user.displayPhoto.isNotEmpty ? user.displayPhoto : null,
          'isAvailable': user.isActive,
          'rating': user.rating,
          'totalRatings': user.reviewCount ?? 0,
          'consultationFee': user.consultationFee,
          'licenseNumber': user.licenseNumber,
          'isVerified': user.isUserVerified,
          'verificationStatus': user.verificationStatus,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': user.createdAt != null
              ? Timestamp.fromDate(user.createdAt!)
              : FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user role: $e');
      throw Exception('Failed to update user role: $e');
    }
  }

  // Update user status
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user status: $e');
      throw Exception('Failed to update user status: $e');
    }
  }

  // Update user verification status
  Future<void> updateUserVerification(
      String userId, bool isVerified, String verificationStatus) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': isVerified,
        'verificationStatus': verificationStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('doctors').doc(userId).set({
        'isVerified': isVerified,
        'verificationStatus': verificationStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user verification: $e');
      throw Exception('Failed to update user verification: $e');
    }
  }

  // Verify user
  Future<void> verifyUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verificationStatus': 'verified',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('doctors').doc(userId).set({
        'isVerified': true,
        'verificationStatus': 'verified',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error verifying user: $e');
      throw Exception('Failed to verify user: $e');
    }
  }

  // Reject user verification
  Future<void> rejectUserVerification(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': false,
        'verificationStatus': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('doctors').doc(userId).set({
        'isVerified': false,
        'verificationStatus': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error rejecting user verification: $e');
      throw Exception('Failed to reject user verification: $e');
    }
  }

  // Delete user (soft delete)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Permanently delete user (use with caution)
  Future<void> permanentlyDeleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error permanently deleting user: $e');
      throw Exception('Failed to permanently delete user: $e');
    }
  }

  // Update user profile image
  Future<void> updateUserProfileImage(String userId, String imageUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImage': imageUrl,
        'photoUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('doctors').doc(userId).set({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user profile image: $e');
      throw Exception('Failed to update user profile image: $e');
    }
  }

  // Remove user profile image
  Future<void> removeUserProfileImage(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImage': null,
        'photoUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('doctors').doc(userId).set({
        'imageUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error removing user profile image: $e');
      throw Exception('Failed to remove user profile image: $e');
    }
  }

  // Update doctor-specific information
  Future<void> updateDoctorInfo({
    required String userId,
    required String specialization,
    required String licenseNumber,
    required String clinicName,
    required String clinicAddress,
    required double consultationFee,
    required int experienceYears,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'specialization': specialization,
        'licenseNumber': licenseNumber,
        'clinicName': clinicName,
        'clinicAddress': clinicAddress,
        'consultationFee': consultationFee,
        'experienceYears': experienceYears,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('doctors').doc(userId).set({
        'specialty': specialization,
        'licenseNumber': licenseNumber,
        'clinicName': clinicName,
        'clinicAddress': clinicAddress,
        'consultationFee': consultationFee,
        'experienceYears': experienceYears,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating doctor info: $e');
      throw Exception('Failed to update doctor information: $e');
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users =
          snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();

      return {
        'total': users.length,
        'patients': users.where((user) => user.isPatient).length,
        'doctors': users.where((user) => user.isDoctor).length,
        'admins': users.where((user) => user.isAdmin).length,
        'active': users.where((user) => user.isActive).length,
        'verified': users.where((user) => user.isUserVerified).length,
        'pending':
            users.where((user) => user.verificationStatus == 'pending').length,
        'rejected':
            users.where((user) => user.verificationStatus == 'rejected').length,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      return {
        'total': 0,
        'patients': 0,
        'doctors': 0,
        'admins': 0,
        'active': 0,
        'verified': 0,
        'pending': 0,
        'rejected': 0,
      };
    }
  }

  // Get recent users
  Stream<List<User>> getRecentUsers(int limit) {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  // Get users by verification status
  Stream<List<User>> getUsersByVerificationStatus(String status) {
    return _firestore
        .collection('users')
        .where('verificationStatus', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  // Get users by activity status
  Stream<List<User>> getUsersByActivityStatus(bool isActive) {
    return _firestore
        .collection('users')
        .where('isActive', isEqualTo: isActive)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => User.fromFirestore(doc)).toList());
  }

  // Get doctors with incomplete profiles
  Stream<List<User>> getDoctorsWithIncompleteProfiles() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .where((user) =>
              user.specialization == null ||
              user.licenseNumber == null ||
              user.consultationFee == null ||
              user.experienceYears == null)
          .toList();
    });
  }

  // Update last login time
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last login: $e');
      // Don't throw exception for this as it's not critical
    }
  }

  // Get user count by role
  Future<Map<String, int>> getUserCountByRole() async {
    try {
      final patientsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get();
      final doctorsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();
      final adminsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return {
        'patients': patientsQuery.size,
        'doctors': doctorsQuery.size,
        'admins': adminsQuery.size,
      };
    } catch (e) {
      print('Error getting user count by role: $e');
      return {
        'patients': 0,
        'doctors': 0,
        'admins': 0,
      };
    }
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email existence: $e');
      return false;
    }
  }

  // Check if phone exists
  Future<bool> checkPhoneExists(String phone) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone existence: $e');
      return false;
    }
  }
}
