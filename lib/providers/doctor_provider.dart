// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:medicore/models/doctor_model.dart';
import 'package:medicore/services/doctor_service.dart';

class DoctorProvider with ChangeNotifier {
  final DoctorService _doctorService = DoctorService();
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 20;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedSpecialty = 'All';
  String _selectedAvailability = 'All';

  List<Doctor> get doctors => _doctors;
  List<Doctor> get filteredDoctors => _filteredDoctors;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedSpecialty => _selectedSpecialty;
  String get selectedAvailability => _selectedAvailability;

  // Get unique specialties for filter dropdown
  List<String> get specialties {
    final specialties = _doctors.map((doc) => doc.specialty).toSet().toList();
    specialties.insert(0, 'All');
    return specialties;
  }

  // Stream for real-time updates (first page)
  Stream<List<Doctor>> get doctorsStream {
    return _doctorService.getDoctorsStream(limit: _pageSize);
  }

  void updateDoctorsFromStream(List<Doctor> docs) {
    _doctors = docs;
    _hasMore = docs.length >= _pageSize;
    _applyFilters();
    notifyListeners();
  }

  Future<void> loadMoreDoctors() async {
    if (_isLoadingMore || !_hasMore || _doctors.isEmpty) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final lastDocSnap = await _doctorService.getDoctorDocAt(_doctors.length - 1);
      if (lastDocSnap == null) {
        _hasMore = false;
        return;
      }
      final more = await _doctorService.getMoreDoctors(lastDocSnap, _pageSize);
      if (more.isEmpty) {
        _hasMore = false;
      } else {
        _doctors = [..._doctors, ...more];
        _hasMore = more.length >= _pageSize;
        _applyFilters();
      }
    } catch (_) {
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Set search query and filter doctors
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Set selected specialty filter
  void setSelectedSpecialty(String specialty) {
    _selectedSpecialty = specialty;
    _applyFilters();
    notifyListeners();
  }

  // Set availability filter
  void setSelectedAvailability(String availability) {
    _selectedAvailability = availability;
    _applyFilters();
    notifyListeners();
  }

  // Apply all filters
  void _applyFilters() {
    List<Doctor> filtered = List.from(_doctors);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((doctor) =>
              doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              doctor.specialty
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              (doctor.clinicName
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false) ||
              (doctor.bio?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false))
          .toList();
    }

    // Apply specialty filter
    if (_selectedSpecialty != 'All') {
      filtered = filtered
          .where((doctor) => doctor.specialty == _selectedSpecialty)
          .toList();
    }

    // Apply availability filter
    if (_selectedAvailability != 'All') {
      final isAvailable = _selectedAvailability == 'Available';
      filtered = filtered
          .where((doctor) => doctor.isAvailable == isAvailable)
          .toList();
    }

    _filteredDoctors = filtered;
  }

  // Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedSpecialty = 'All';
    _selectedAvailability = 'All';
    _filteredDoctors = List.from(_doctors);
    notifyListeners();
  }

  // Load doctors with better error handling and data validation
  Future<void> loadDoctors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .orderBy('name')
          .get();

      _doctors = querySnapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              return Doctor(
                uid: doc.id,
                name: data['name']?.toString().trim() ?? 'Unknown Doctor',
                email: data['email']?.toString().trim() ?? '',
                specialty: data['specialty']?.toString().trim() ??
                    'General Practitioner',
                isAvailable: data['isAvailable'] ?? true,
                rating: _parseDouble(data['rating']) ?? 0.0,
                totalRatings: _parseInt(data['totalRatings']) ?? 0,
                phone: data['phone']?.toString().trim(),
                experienceYears: _parseInt(data['experienceYears']),
                clinicName: data['clinicName']?.toString().trim(),
                clinicAddress: data['clinicAddress']?.toString().trim(),
                bio: data['bio']?.toString().trim(),
                imageUrl: data['imageUrl']?.toString().trim(),
                consultationFee: _parseDouble(data['consultationFee']),
                languages: _parseLanguages(data['languages']),
                education: _parseEducation(data['education']),
                certifications: _parseCertifications(data['certifications']),
                workingHours: _parseWorkingHours(data['workingHours']),
                isPremium: data['isPremium'] ?? false,
                isVerified: data['isVerified'] ?? false,
                createdAt: data['createdAt'] != null
                    ? (data['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
                updatedAt: data['updatedAt'] != null
                    ? (data['updatedAt'] as Timestamp).toDate()
                    : DateTime.now(),
                verificationStatus: data['verificationStatus']?.toString() ??
                    (data['isVerified'] == true ? 'verified' : 'pending'),
              );
            } catch (e) {
              print('Error parsing doctor data for doc ${doc.id}: $e');
              // Return a default doctor with the available data
              return Doctor(
                uid: doc.id,
                name: 'Doctor',
                email: '',
                specialty: 'General Practitioner',
                isAvailable: true,
                rating: 0.0,
                totalRatings: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            }
          })
          .where((doctor) => doctor.name != 'Doctor')
          .toList(); // Filter out invalid doctors

      // Initialize filtered doctors
      _filteredDoctors = List.from(_doctors);

      print('Successfully loaded ${_doctors.length} doctors');
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to load doctors. Please try again.';
      print('Error loading doctors: $e');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper methods for data parsing
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  List<String> _parseLanguages(dynamic value) {
    if (value == null) return ['English'];
    if (value is List) return value.cast<String>();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return ['English'];
  }

  List<String> _parseEducation(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  List<String> _parseCertifications(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    if (value is String) return value.split(',').map((e) => e.trim()).toList();
    return [];
  }

  Map<String, String> _parseWorkingHours(dynamic value) {
    if (value is Map) {
      return value
          .map((key, value) => MapEntry(key.toString(), value.toString()));
    }
    return {
      'Monday': '9:00 AM - 5:00 PM',
      'Tuesday': '9:00 AM - 5:00 PM',
      'Wednesday': '9:00 AM - 5:00 PM',
      'Thursday': '9:00 AM - 5:00 PM',
      'Friday': '9:00 AM - 5:00 PM',
      'Saturday': '9:00 AM - 1:00 PM',
      'Sunday': 'Closed',
    };
  }

  // Add doctor with improved validation
  Future<bool> addDoctor({
    required String name,
    required String email,
    required String password,
    required String specialty,
    String? phone,
    String? experience,
    required String clinic,
    String? clinicAddress,
    String? bio,
    double? consultationFee,
    bool isPremium = false,
    List<String>? languages,
    List<String>? education,
    List<String>? certifications,
    Map<String, String>? workingHours,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate required fields
      if (name.isEmpty ||
          email.isEmpty ||
          specialty.isEmpty ||
          password.isEmpty) {
        _errorMessage = 'Please fill all required fields';
        return false;
      }

      // Check if doctor with same email already exists
      final existingDoctor = await FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: email.trim())
          .get();

      if (existingDoctor.docs.isNotEmpty) {
        _errorMessage = 'A doctor with this email already exists';
        return false;
      }

      final docRef = FirebaseFirestore.instance.collection('doctors').doc();

      final doctor = Doctor(
        uid: docRef.id,
        name: name.trim(),
        email: email.trim(),
        specialty: specialty.trim(),
        phone: phone?.trim(),
        experienceYears: _parseInt(experience),
        clinicName: clinic.trim(),
        clinicAddress: clinicAddress?.trim(),
        bio: bio?.trim(),
        consultationFee: consultationFee,
        isPremium: isPremium,
        languages: languages ?? ['English'],
        education: education ?? [],
        certifications: certifications ?? [],
        workingHours: workingHours ?? _parseWorkingHours(null),
        imageUrl: imageUrl,
        isAvailable: true,
        rating: 0.0,
        totalRatings: 0,
        isVerified: true,
        verificationStatus: 'verified',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(doctor.toMap());

      // Also create user document
      await FirebaseFirestore.instance.collection('users').doc(doctor.uid).set({
        'uid': doctor.uid,
        'email': doctor.email,
        'name': doctor.name,
        'role': 'doctor',
        'specialty': doctor.specialty,
        'isAvailable': doctor.isAvailable,
        'isPremium': doctor.isPremium,
        'isVerified': doctor.isVerified,
        'verificationStatus': doctor.verificationStatus,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Add to local list and apply filters
      _doctors.add(doctor);
      _applyFilters();

      print('Successfully added doctor: ${doctor.name}');
      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to add doctor. Please try again.';
      print('Error adding doctor: $e');
      print('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Update doctor with individual fields
  Future<bool> updateDoctor({
    required String uid,
    required String name,
    required String email,
    required String specialty,
    String? phone,
    String? experience,
    String? clinic,
    String? clinicAddress,
    String? bio,
    double? consultationFee,
    bool? isPremium,
    List<String>? languages,
    List<String>? education,
    List<String>? certifications,
    Map<String, String>? workingHours,
    String? imageUrl,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate required fields
      if (name.isEmpty || email.isEmpty || specialty.isEmpty) {
        _errorMessage = 'Please fill all required fields';
        return false;
      }

      // Check if another doctor with same email exists
      final existingDoctor = await FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: email.trim())
          .where('uid', isNotEqualTo: uid)
          .get();

      if (existingDoctor.docs.isNotEmpty) {
        _errorMessage = 'Another doctor with this email already exists';
        return false;
      }

      // Get current doctor data
      final currentDoctor = _doctors.firstWhere((d) => d.uid == uid);

      final updatedDoctor = currentDoctor.copyWith(
        name: name.trim(),
        email: email.trim(),
        specialty: specialty.trim(),
        phone: phone?.trim(),
        experienceYears: _parseInt(experience),
        clinicName: clinic?.trim(),
        clinicAddress: clinicAddress?.trim(),
        bio: bio?.trim(),
        consultationFee: consultationFee,
        isPremium: isPremium ?? currentDoctor.isPremium,
        languages: languages ?? currentDoctor.languages,
        education: education ?? currentDoctor.education,
        certifications: certifications ?? currentDoctor.certifications,
        workingHours: workingHours ?? currentDoctor.workingHours,
        imageUrl: imageUrl ?? currentDoctor.imageUrl,
        updatedAt: DateTime.now(),
        isVerified: currentDoctor.isVerified,
        verificationStatus: currentDoctor.verificationStatus,
      );

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .update(updatedDoctor.toMap());

      // Also update users collection
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': updatedDoctor.name,
        'email': updatedDoctor.email,
        'specialty': updatedDoctor.specialty,
        'isAvailable': updatedDoctor.isAvailable,
        'isPremium': updatedDoctor.isPremium,
        'isVerified': updatedDoctor.isVerified,
        'verificationStatus': updatedDoctor.verificationStatus,
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _doctors.indexWhere((d) => d.uid == uid);
      if (index != -1) {
        _doctors[index] = updatedDoctor;
        _applyFilters();
      }

      print('Successfully updated doctor: $name');
      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to update doctor. Please try again.';
      print('Error updating doctor: $e');
      print('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveDoctor(String doctorId) async {
    return _updateDoctorVerificationStatus(
      doctorId: doctorId,
      isVerified: true,
      verificationStatus: 'verified',
    );
  }

  Future<bool> rejectDoctor(String doctorId) async {
    return _updateDoctorVerificationStatus(
      doctorId: doctorId,
      isVerified: false,
      verificationStatus: 'rejected',
    );
  }

  Future<bool> _updateDoctorVerificationStatus({
    required String doctorId,
    required bool isVerified,
    required String verificationStatus,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'isVerified': isVerified,
        'verificationStatus': verificationStatus,
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .set(payload, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(doctorId).set(
            payload,
            SetOptions(merge: true),
          );

      final index = _doctors.indexWhere((doctor) => doctor.uid == doctorId);
      if (index != -1) {
        _doctors[index] = _doctors[index].copyWith(
          isVerified: isVerified,
          verificationStatus: verificationStatus,
        );
        _applyFilters();
      }

      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to update doctor verification status.';
      print('Error updating doctor verification status: $e');
      print('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // NEW: Update doctor status (active/inactive)
  Future<bool> updateDoctorStatus(String doctorId, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .update({
        'isAvailable': isActive,
        'updatedAt': Timestamp.now(),
      });

      // Also update users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .update({
        'isAvailable': isActive,
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _doctors.indexWhere((d) => d.uid == doctorId);
      if (index != -1) {
        _doctors[index] = _doctors[index].copyWith(isAvailable: isActive);
        _applyFilters();
      }

      print('Successfully updated status for doctor: $doctorId to $isActive');
      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to update doctor status. Please try again.';
      print('Error updating doctor status: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Delete doctor with confirmation and error handling
  Future<bool> deleteDoctor(String doctorId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if doctor exists
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (!doctorDoc.exists) {
        _errorMessage = 'Doctor not found';
        return false;
      }

      // Delete from doctors collection
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .delete();

      // Also delete from users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .delete();

      // Remove from local lists
      _doctors.removeWhere((doctor) => doctor.uid == doctorId);
      _applyFilters();

      print('Successfully deleted doctor: $doctorId');
      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to delete doctor. Please try again.';
      print('Error deleting doctor: $e');
      print('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update doctor with comprehensive data
  Future<bool> updateDoctorFull(Doctor doctor) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate required fields
      if (doctor.name.isEmpty ||
          doctor.email.isEmpty ||
          doctor.specialty.isEmpty) {
        _errorMessage = 'Please fill all required fields';
        return false;
      }

      // Check if another doctor with same email exists
      final existingDoctor = await FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: doctor.email.trim())
          .where('uid', isNotEqualTo: doctor.uid)
          .get();

      if (existingDoctor.docs.isNotEmpty) {
        _errorMessage = 'Another doctor with this email already exists';
        return false;
      }

      final updatedDoctor = doctor.copyWith(updatedAt: DateTime.now());

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctor.uid)
          .update(updatedDoctor.toMap());

      // Also update users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doctor.uid)
          .update({
        'name': updatedDoctor.name,
        'email': updatedDoctor.email,
        'specialty': updatedDoctor.specialty,
        'isAvailable': updatedDoctor.isAvailable,
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _doctors.indexWhere((d) => d.uid == doctor.uid);
      if (index != -1) {
        _doctors[index] = updatedDoctor;
        _applyFilters();
      }

      print('Successfully updated doctor: ${doctor.name}');
      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to update doctor. Please try again.';
      print('Error updating doctor: $e');
      print('Stack trace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle doctor availability
  Future<bool> toggleAvailability(String doctorId, bool isAvailable) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.now(),
      });

      // Also update users collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(doctorId)
          .update({
        'isAvailable': isAvailable,
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _doctors.indexWhere((d) => d.uid == doctorId);
      if (index != -1) {
        _doctors[index] = _doctors[index].copyWith(isAvailable: isAvailable);
        _applyFilters();
      }

      print('Successfully updated availability for doctor: $doctorId');
      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to update availability. Please try again.';
      print('Error updating availability: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Update doctor rating
  Future<bool> updateRating(String doctorId, double newRating) async {
    try {
      final doctor = _doctors.firstWhere((d) => d.uid == doctorId);
      final currentTotalRatings = doctor.totalRatings;
      final currentRating = doctor.rating;

      // Calculate new average rating
      final newTotalRatings = currentTotalRatings + 1;
      final newAverageRating =
          ((currentRating * currentTotalRatings) + newRating) / newTotalRatings;

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .update({
        'rating': newAverageRating,
        'totalRatings': newTotalRatings,
        'updatedAt': Timestamp.now(),
      });

      // Update local list
      final index = _doctors.indexWhere((d) => d.uid == doctorId);
      if (index != -1) {
        _doctors[index] = _doctors[index].copyWith(
          rating: newAverageRating,
          totalRatings: newTotalRatings,
        );
        _applyFilters();
      }

      print('Successfully updated rating for doctor: $doctorId');
      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to update rating. Please try again.';
      print('Error updating rating: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Get doctor by ID
  Doctor? getDoctorById(String doctorId) {
    try {
      return _doctors.firstWhere((doctor) => doctor.uid == doctorId);
    } catch (e) {
      return null;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh doctors data
  Future<void> refreshDoctors() async {
    await loadDoctors();
  }

  // Get featured doctors (highly rated and available)
  List<Doctor> get featuredDoctors {
    return _doctors
        .where((doctor) => doctor.isAvailable && doctor.rating >= 4.0)
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  Null get upcomingAppointments => null;

  // Get doctors by specialty
  List<Doctor> getDoctorsBySpecialty(String specialty) {
    return _doctors.where((doctor) => doctor.specialty == specialty).toList();
  }

  // Search doctors with multiple criteria
  List<Doctor> searchDoctors(String query) {
    if (query.isEmpty) return _doctors;

    return _doctors
        .where((doctor) =>
            doctor.name.toLowerCase().contains(query.toLowerCase()) ||
            doctor.specialty.toLowerCase().contains(query.toLowerCase()) ||
            (doctor.clinicName?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (doctor.bio?.toLowerCase().contains(query.toLowerCase()) ??
                false) ||
            (doctor.education
                .any((edu) => edu.toLowerCase().contains(query.toLowerCase()))))
        .toList();
  }

  // Fetch a specific doctor by ID
  Future<Doctor?> fetchDoctorById(String doctorId) async {
    try {
      if (doctorId.trim().isEmpty) {
        return null;
      }
      final docSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .get();

      if (!docSnapshot.exists) return null;

      final data = docSnapshot.data();
      if (data == null) return null;

      return Doctor(
        uid: docSnapshot.id,
        name: data['name']?.toString().trim() ?? 'Unknown Doctor',
        email: data['email']?.toString().trim() ?? '',
        specialty:
            data['specialty']?.toString().trim() ?? 'General Practitioner',
        isAvailable: data['isAvailable'] ?? true,
        rating: _parseDouble(data['rating']) ?? 0.0,
        totalRatings: _parseInt(data['totalRatings']) ?? 0,
        phone: data['phone']?.toString().trim(),
        experienceYears: _parseInt(data['experienceYears']),
        clinicName: data['clinicName']?.toString().trim(),
        clinicAddress: data['clinicAddress']?.toString().trim(),
        bio: data['bio']?.toString().trim(),
        imageUrl: data['imageUrl']?.toString().trim(),
        consultationFee: _parseDouble(data['consultationFee']),
        languages: _parseLanguages(data['languages']),
        education: _parseEducation(data['education']),
        certifications: _parseCertifications(data['certifications']),
        workingHours: _parseWorkingHours(data['workingHours']),
        isPremium: data['isPremium'] ?? false,
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e) {
      print('Error fetching doctor by ID: $e');
      return null;
    }
  }

  void fetchDoctors() {}
}
