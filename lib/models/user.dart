// models/user.dart
// ignore_for_file: no_leading_underscores_for_local_identifiers, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final String phone;
  final bool isVerified;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String authProvider;

  // Additional fields from UserModel
  final DateTime dateOfBirth;
  final String gender;
  final String? profileImage;
  final String? address;
  final bool isActive;
  final DateTime? lastLogin;
  final Map<String, dynamic>? healthProfile;
  final Map<String, dynamic>? professionalInfo;
  final String? specialization;
  final String? licenseNumber;
  final String verificationStatus;
  final List<String> documents;

  // Doctor-specific fields
  final double? rating;
  final int? experienceYears;
  final int? reviewCount;
  final String? clinicAddress;
  final double? consultationFee;
  final String? clinicName;
  final int? totalPatients;
  final int? appointmentCount;

  // Patient-specific fields
  final int? orderCount;
  final int? medicalRecordCount;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.phone,
    this.isVerified = false,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.authProvider = 'email',
    // Additional fields with defaults
    DateTime? dateOfBirth,
    this.gender = 'prefer-not-to-say',
    this.profileImage,
    this.address,
    this.isActive = true,
    this.lastLogin,
    this.healthProfile,
    this.professionalInfo,
    this.specialization,
    this.licenseNumber,
    this.verificationStatus = 'pending',
    this.documents = const [],
    // Doctor-specific fields
    this.rating,
    this.experienceYears,
    this.reviewCount,
    this.clinicAddress,
    this.consultationFee,
    this.clinicName,
    this.totalPatients,
    this.appointmentCount,
    // Patient-specific fields
    this.orderCount = 0,
    this.medicalRecordCount = 0,
  }) : dateOfBirth = dateOfBirth ??
            DateTime(2000); // Default to year 2000 instead of current date

  factory User.fromFirestore(DocumentSnapshot doc) {
    try {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return User.fromMap(data, id: doc.id);
    } catch (e) {
      print('Error parsing user from Firestore: $e');
      // Return a default user with the document ID
      return User(
        id: doc.id,
        email: '',
        name: 'Unknown User',
        role: 'patient',
        phone: '',
        authProvider: 'email',
      );
    }
  }

  factory User.fromMap(Map<String, dynamic> data, {String? id}) {
    // Helper function to safely parse dates
    DateTime? _parseDate(dynamic date) {
      if (date == null) return null;
      if (date is Timestamp) return date.toDate();
      if (date is DateTime) return date;
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    // Helper function to safely parse numbers
    double? _parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    int? _parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return User(
      id: id ?? data['id'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? 'Unknown User',
      role: data['role'] ?? 'patient',
      phone: data['phone'] ?? '',
      isVerified: data['isVerified'] ?? false,
      photoUrl: data['photoUrl'],
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      authProvider: data['authProvider'] ?? 'email',
      // Additional fields
      dateOfBirth: _parseDate(data['dateOfBirth']) ?? DateTime(2000),
      gender: data['gender'] ?? 'prefer-not-to-say',
      profileImage: data['profileImage'] ?? data['photoUrl'],
      address: data['address'],
      isActive: data['isActive'] ?? true,
      lastLogin: _parseDate(data['lastLogin']),
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
      // Doctor-specific fields
      rating: _parseDouble(data['rating']),
      experienceYears: _parseInt(data['experienceYears']),
      reviewCount: _parseInt(data['reviewCount']),
      clinicAddress: data['clinicAddress'],
      consultationFee: _parseDouble(data['consultationFee']),
      clinicName: data['clinicName'],
      totalPatients: _parseInt(data['totalPatients']),
      appointmentCount: _parseInt(data['appointmentCount']),
      // Patient-specific fields
      orderCount: _parseInt(data['orderCount']) ?? 0,
      medicalRecordCount: _parseInt(data['medicalRecordCount']) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'isVerified': isVerified,
      'photoUrl': photoUrl,
      'authProvider': authProvider,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      // Additional fields
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'profileImage': profileImage,
      'address': address,
      'isActive': isActive,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'healthProfile': healthProfile,
      'professionalInfo': professionalInfo,
      'specialization': specialization,
      'licenseNumber': licenseNumber,
      'verificationStatus': verificationStatus,
      'documents': documents,
      // Doctor-specific fields
      'rating': rating,
      'experienceYears': experienceYears,
      'reviewCount': reviewCount,
      'clinicAddress': clinicAddress,
      'consultationFee': consultationFee,
      'clinicName': clinicName,
      'totalPatients': totalPatients,
      'appointmentCount': appointmentCount,
      // Patient-specific fields
      'orderCount': orderCount,
      'medicalRecordCount': medicalRecordCount,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Only include fields that are not null
    if (name.isNotEmpty) {
      map['name'] = name;
    }
    if (email.isNotEmpty) {
      map['email'] = email;
    }
    if (phone.isNotEmpty) {
      map['phone'] = phone;
    }
    if (role.isNotEmpty) {
      map['role'] = role;
    }

    map['isVerified'] = isVerified;
    map['isActive'] = isActive;
    map['verificationStatus'] = verificationStatus;
    map['gender'] = gender;

    if (photoUrl != null) {
      map['photoUrl'] = photoUrl;
    }
    if (profileImage != null) {
      map['profileImage'] = profileImage;
    }
    if (address != null) {
      map['address'] = address;
    }
    if (specialization != null) {
      map['specialization'] = specialization;
    }
    if (licenseNumber != null) {
      map['licenseNumber'] = licenseNumber;
    }
    if (clinicName != null) {
      map['clinicName'] = clinicName;
    }
    if (clinicAddress != null) {
      map['clinicAddress'] = clinicAddress;
    }
    if (consultationFee != null) {
      map['consultationFee'] = consultationFee;
    }
    if (experienceYears != null) {
      map['experienceYears'] = experienceYears;
    }
    if (rating != null) {
      map['rating'] = rating;
    }
    if (reviewCount != null) {
      map['reviewCount'] = reviewCount;
    }
    if (totalPatients != null) {
      map['totalPatients'] = totalPatients;
    }
    if (appointmentCount != null) {
      map['appointmentCount'] = appointmentCount;
    }
    if (orderCount != null) {
      map['orderCount'] = orderCount;
    }
    if (medicalRecordCount != null) {
      map['medicalRecordCount'] = medicalRecordCount;
    }

    return map;
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? phone,
    bool? isVerified,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? authProvider,
    // Additional fields
    DateTime? dateOfBirth,
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
    // Doctor-specific fields
    double? rating,
    int? experienceYears,
    int? reviewCount,
    String? clinicAddress,
    double? consultationFee,
    String? clinicName,
    int? totalPatients,
    int? appointmentCount,
    // Patient-specific fields
    int? orderCount,
    int? medicalRecordCount,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      authProvider: authProvider ?? this.authProvider,
      // Additional fields
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
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
      // Doctor-specific fields
      rating: rating ?? this.rating,
      experienceYears: experienceYears ?? this.experienceYears,
      reviewCount: reviewCount ?? this.reviewCount,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      consultationFee: consultationFee ?? this.consultationFee,
      clinicName: clinicName ?? this.clinicName,
      totalPatients: totalPatients ?? this.totalPatients,
      appointmentCount: appointmentCount ?? this.appointmentCount,
      // Patient-specific fields
      orderCount: orderCount ?? this.orderCount,
      medicalRecordCount: medicalRecordCount ?? this.medicalRecordCount,
    );
  }

  // Helper getters for convenience
  String get displayPhoto => profileImage ?? photoUrl ?? '';

  bool get isDoctor => role == 'doctor';

  bool get isPatient => role == 'patient';

  bool get isAdmin => role == 'admin';

  // Get display name with role
  String get displayName {
    if (isDoctor) {
      return 'Dr. $name';
    }
    return name;
  }

  // Get role display text
  String get roleDisplay {
    switch (role) {
      case 'doctor':
        return 'Doctor';
      case 'admin':
        return 'Administrator';
      case 'patient':
        return 'Patient';
      default:
        return 'User';
    }
  }

  // Get status display text
  String get statusDisplay {
    if (!isActive) return 'Inactive';
    if (verificationStatus == 'pending') return 'Pending Verification';
    if (verificationStatus == 'rejected') return 'Verification Rejected';
    if (!isVerified) return 'Unverified';
    return 'Active';
  }

  // Get status color
  Color get statusColor {
    if (!isActive) return Colors.red;
    if (verificationStatus == 'pending') return Colors.orange;
    if (verificationStatus == 'rejected') return Colors.red;
    if (!isVerified) return Colors.orange;
    return Colors.green;
  }

  // Get age from date of birth
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  // Check if user is fully verified
  bool get isUserVerified => verificationStatus == 'verified' && isVerified;

  // Get formatted consultation fee for doctors
  String get formattedConsultationFee {
    if (consultationFee == null) return 'Not set';
    return '৳${consultationFee!.toStringAsFixed(2)}';
  }

  // Get experience display text
  String get experienceDisplay {
    if (experienceYears == null) return 'Not specified';
    return '$experienceYears ${experienceYears == 1 ? 'year' : 'years'} experience';
  }

  // Get rating display with fallback
  String get ratingDisplay {
    if (rating == null) return 'No ratings';
    return rating!.toStringAsFixed(1);
  }

  // Get review count display
  String get reviewCountDisplay {
    if (reviewCount == null) return 'No reviews';
    return '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}';
  }

  // Get order count display
  String get orderCountDisplay =>
      '$orderCount ${orderCount == 1 ? 'order' : 'orders'}';

  // Get medical record count display
  String get medicalRecordCountDisplay =>
      '$medicalRecordCount ${medicalRecordCount == 1 ? 'record' : 'records'}';

  // Check if profile is complete
  bool get hasCompleteProfile =>
      name.isNotEmpty &&
      email.isNotEmpty &&
      phone.isNotEmpty &&
      dateOfBirth != DateTime(2000);

  // Check if doctor profile is complete
  bool get hasCompleteDoctorProfile =>
      hasCompleteProfile &&
      specialization != null &&
      specialization!.isNotEmpty &&
      licenseNumber != null &&
      licenseNumber!.isNotEmpty &&
      consultationFee != null;

  // Get formatted date of birth
  String get formattedDateOfBirth {
    return '${dateOfBirth.day}/${dateOfBirth.month}/${dateOfBirth.year}';
  }

  // Get formatted join date
  String get formattedJoinDate {
    if (createdAt == null) {
      return 'Unknown';
    }
    return '${createdAt!.day}/${createdAt!.month}/${createdAt!.year}';
  }

  // Get last login display
  String get lastLoginDisplay {
    if (lastLogin == null) {
      return 'Never';
    }
    final now = DateTime.now();
    final difference = now.difference(lastLogin!);
    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    }
    return '${(difference.inDays / 30).floor()}mo ago';
  }

  // Get verification status display
  String get verificationStatusDisplay {
    switch (verificationStatus) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  // Get verification status color
  Color get verificationStatusColor {
    switch (verificationStatus) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Check if user can be verified (has complete profile)
  bool get canBeVerified {
    if (isDoctor) {
      return hasCompleteDoctorProfile;
    }
    return hasCompleteProfile;
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role, phone: $phone, isVerified: $isVerified, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
