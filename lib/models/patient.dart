// models/patient.dart
// ignore_for_file: overridden_fields

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/user.dart';

class Patient extends User {
  @override
  final DateTime dateOfBirth;

  /// Unique patient ID (e.g., MED-PAT-001)
  final String patientId;

  /// List of doctor IDs the patient is connected with
  final List<String> connectedDoctorIds;

  Patient({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    required this.dateOfBirth,
    required this.patientId,
    this.connectedDoctorIds = const [],
    super.role = 'patient',
    super.isVerified = false,
    super.photoUrl,
    super.createdAt,
    super.updatedAt,
    required super.authProvider,
    super.gender = 'prefer-not-to-say',
    super.profileImage,
    super.address,
    super.isActive = true,
    super.lastLogin,
    super.healthProfile,
    super.professionalInfo,
    super.specialization,
    super.licenseNumber,
    super.verificationStatus = 'pending',
    super.documents = const [],
    super.rating,
    super.experienceYears,
    super.reviewCount,
    super.clinicAddress,
    super.consultationFee,
    super.clinicName,
    super.totalPatients,
    super.appointmentCount,
    super.orderCount = 0,
    super.medicalRecordCount = 0,
  });

  @override
  Map<String, dynamic> toMap() {
    final data = super.toMap();

    // Ensure dateOfBirth is properly set
    data['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
    data['role'] = 'patient'; // Ensure role is always 'patient'
    data['patientId'] = patientId;
    data['connectedDoctorIds'] = connectedDoctorIds;

    return data;
  }

  factory Patient.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse dateOfBirth with proper error handling
    DateTime dob;
    if (data['dateOfBirth'] != null && data['dateOfBirth'] is Timestamp) {
      dob = (data['dateOfBirth'] as Timestamp).toDate();
    } else if (data['dateOfBirth'] != null && data['dateOfBirth'] is String) {
      dob = DateTime.tryParse(data['dateOfBirth']) ?? DateTime.now();
    } else {
      dob = DateTime.now();
    }

    return Patient(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      dateOfBirth: dob,
      patientId: data['patientId'] ??
          'MED-PAT-${doc.id.substring(0, 6).toUpperCase()}',
      connectedDoctorIds: List<String>.from(data['connectedDoctorIds'] ?? []),
      authProvider: data['authProvider'] ?? 'email',
      role: data['role'] ?? 'patient',
      isVerified: data['isVerified'] ?? false,
      photoUrl: data['photoUrl'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      gender: data['gender'] ?? 'prefer-not-to-say',
      profileImage: data['profileImage'],
      address: data['address'],
      isActive: data['isActive'] ?? true,
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
      healthProfile: data['healthProfile'] != null
          ? Map<String, dynamic>.from(data['healthProfile'])
          : null,
      professionalInfo: data['professionalInfo'] != null
          ? Map<String, dynamic>.from(data['professionalInfo'])
          : null,
      specialization: data['specialization'],
      licenseNumber: data['licenseNumber'],
      verificationStatus: data['verificationStatus'] ?? 'pending',
      documents: List<String>.from(data['documents'] ?? []),
      rating: data['rating'] != null
          ? double.parse(data['rating'].toString())
          : null,
      experienceYears: data['experienceYears'] != null
          ? int.parse(data['experienceYears'].toString())
          : null,
      reviewCount: data['reviewCount'] != null
          ? int.parse(data['reviewCount'].toString())
          : null,
      clinicAddress: data['clinicAddress'],
      consultationFee: data['consultationFee'] != null
          ? double.parse(data['consultationFee'].toString())
          : null,
      clinicName: data['clinicName'],
      totalPatients: data['totalPatients'] != null
          ? int.parse(data['totalPatients'].toString())
          : null,
      appointmentCount: data['appointmentCount'] != null
          ? int.parse(data['appointmentCount'].toString())
          : null,
      orderCount: data['orderCount'] != null
          ? int.parse(data['orderCount'].toString())
          : 0,
      medicalRecordCount: data['medicalRecordCount'] != null
          ? int.parse(data['medicalRecordCount'].toString())
          : 0,
    );
  }

  // CopyWith method for Patient
  @override
  Patient copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    DateTime? dateOfBirth,
    String? patientId,
    List<String>? connectedDoctorIds,
    String? role,
    bool? isVerified,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authProvider,
    String? gender,
    String? profileImage,
    String? address,
    bool? isActive,
    DateTime? lastLogin,
    Map<String, dynamic>? healthProfile,
    Map<String, dynamic>? professionalInfo,
    String? specialization,
    String? licenseNumber,
    String? verificationStatus,
    List<String>? documents,
    double? rating,
    int? experienceYears,
    int? reviewCount,
    String? clinicAddress,
    double? consultationFee,
    String? clinicName,
    int? totalPatients,
    int? appointmentCount,
    int? medicalRecordCount,
    int? orderCount,
  }) {
    return Patient(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      patientId: patientId ?? this.patientId,
      connectedDoctorIds: connectedDoctorIds ?? this.connectedDoctorIds,
      authProvider: authProvider ?? this.authProvider,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gender: gender ?? this.gender,
      profileImage: profileImage ?? this.profileImage,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      healthProfile: healthProfile ?? this.healthProfile,
      professionalInfo: professionalInfo ?? this.professionalInfo,
      specialization: specialization ?? this.specialization,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      documents: documents ?? this.documents,
      rating: rating ?? this.rating,
      experienceYears: experienceYears ?? this.experienceYears,
      reviewCount: reviewCount ?? this.reviewCount,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      consultationFee: consultationFee ?? this.consultationFee,
      clinicName: clinicName ?? this.clinicName,
      totalPatients: totalPatients ?? this.totalPatients,
      appointmentCount: appointmentCount ?? this.appointmentCount,
      orderCount: orderCount ?? this.orderCount,
      medicalRecordCount: medicalRecordCount ?? this.medicalRecordCount,
    );
  }

  // Factory method to create Patient from User
  factory Patient.fromUser(User user, DateTime dateOfBirth) {
    return Patient(
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      dateOfBirth: dateOfBirth,
      patientId: 'MED-PAT-${user.id.substring(0, 6).toUpperCase()}',
      authProvider: user.authProvider,
      role: user.role,
      isVerified: user.isVerified,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      gender: user.gender,
      profileImage: user.profileImage,
      address: user.address,
      isActive: user.isActive,
      lastLogin: user.lastLogin,
      healthProfile: user.healthProfile,
      professionalInfo: user.professionalInfo,
      specialization: user.specialization,
      licenseNumber: user.licenseNumber,
      verificationStatus: user.verificationStatus,
      documents: user.documents,
      rating: user.rating,
      experienceYears: user.experienceYears,
      reviewCount: user.reviewCount,
      clinicAddress: user.clinicAddress,
      consultationFee: user.consultationFee,
      clinicName: user.clinicName,
      totalPatients: user.totalPatients,
      appointmentCount: user.appointmentCount,
      orderCount: user.orderCount,
      medicalRecordCount: user.medicalRecordCount,
    );
  }

  // Helper methods specific to Patient
  @override
  bool get hasCompleteProfile =>
      name.isNotEmpty &&
      email.isNotEmpty &&
      phone.isNotEmpty &&
      dateOfBirth != DateTime(0) &&
      dateOfBirth != DateTime.now();

  @override
  String get formattedDateOfBirth {
    return '${dateOfBirth.day}/${dateOfBirth.month}/${dateOfBirth.year}';
  }

  // Get age group for medical purposes
  String get ageGroup {
    final age = this.age;
    if (age < 1) return 'Infant';
    if (age < 3) return 'Toddler';
    if (age < 13) return 'Child';
    if (age < 20) return 'Teenager';
    if (age < 40) return 'Young Adult';
    if (age < 60) return 'Middle Aged';
    return 'Senior';
  }

  // Check if patient is eligible for specific medical services
  bool get isEligibleForVaccination {
    final age = this.age;
    return age >= 0 && age <= 100; // Basic eligibility check
  }

  // Get patient summary for medical records
  String get medicalSummary {
    final List<String> parts = [];

    parts.add('$age years old');
    parts.add(gender);

    if (healthProfile != null && healthProfile!.isNotEmpty) {
      if (healthProfile!.containsKey('bloodGroup')) {
        parts.add('Blood Group: ${healthProfile!['bloodGroup']}');
      }
      if (healthProfile!.containsKey('allergies') &&
          healthProfile!['allergies'] is List) {
        final allergies = (healthProfile!['allergies'] as List).length;
        if (allergies > 0) {
          parts.add('$allergies allergy${allergies > 1 ? 'ies' : ''}');
        }
      }
    }

    return parts.join(' • ');
  }

  /// Add a doctor to the patient's connected doctors list
  Patient addConnectedDoctor(String doctorId) {
    if (!connectedDoctorIds.contains(doctorId)) {
      return copyWith(
        connectedDoctorIds: [...connectedDoctorIds, doctorId],
      );
    }
    return this;
  }

  /// Remove a doctor from the patient's connected doctors list
  Patient removeConnectedDoctor(String doctorId) {
    return copyWith(
      connectedDoctorIds:
          connectedDoctorIds.where((id) => id != doctorId).toList(),
    );
  }

  /// Check if a doctor is connected to this patient
  bool isDoctorConnected(String doctorId) {
    return connectedDoctorIds.contains(doctorId);
  }

  /// Get the number of connected doctors
  int get connectedDoctorsCount => connectedDoctorIds.length;

  @override
  String toString() {
    return 'Patient(id: $id, name: $name, email: $email, phone: $phone, dateOfBirth: $formattedDateOfBirth, age: $age)';
  }

  // Convert to User (for cases where Patient-specific features aren't needed)
  User toUser() {
    return User(
      id: id,
      email: email,
      name: name,
      role: role,
      phone: phone,
      isVerified: isVerified,
      photoUrl: photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authProvider: authProvider,
      dateOfBirth: dateOfBirth,
      gender: gender,
      profileImage: profileImage,
      address: address,
      isActive: isActive,
      lastLogin: lastLogin,
      healthProfile: healthProfile,
      professionalInfo: professionalInfo,
      specialization: specialization,
      licenseNumber: licenseNumber,
      verificationStatus: verificationStatus,
      documents: documents,
      rating: rating,
      experienceYears: experienceYears,
      reviewCount: reviewCount,
      clinicAddress: clinicAddress,
      consultationFee: consultationFee,
      clinicName: clinicName,
      totalPatients: totalPatients,
      appointmentCount: appointmentCount,
      orderCount: orderCount,
      medicalRecordCount: medicalRecordCount,
    );
  }
}
