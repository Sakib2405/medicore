// lib/models/doctor_model.dart
// ignore_for_file: no_leading_underscores_for_local_identifiers, curly_braces_in_flow_control_structures

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Doctor {
  final String uid;
  final String name;
  final String email;
  final String specialty;
  final String? phone;
  final int? experienceYears;
  final String? clinicName;
  final String? clinicAddress;
  final String? bio;
  final String? imageUrl;
  final bool isAvailable;
  final double rating;
  final int totalRatings;
  final DateTime createdAt;
  final DateTime updatedAt;

  // New fields
  final double? consultationFee;
  final List<String> languages;
  final List<String> education;
  final List<String> certifications;
  final Map<String, String> workingHours;
  final String? licenseNumber;
  final String? qualification;
  final List<String> services;
  final int appointmentDuration; // in minutes
  final bool isVerified;
  final bool isPremium;
  final String verificationStatus;

  Doctor({
    required this.uid,
    required this.name,
    required this.email,
    required this.specialty,
    this.phone,
    this.experienceYears,
    this.clinicName,
    this.clinicAddress,
    this.bio,
    this.imageUrl,
    this.isAvailable = true,
    this.rating = 0.0,
    this.totalRatings = 0,
    required this.createdAt,
    required this.updatedAt,

    // New fields with default values
    this.consultationFee,
    this.languages = const ['English'],
    this.education = const [],
    this.certifications = const [],
    this.workingHours = const {
      'Monday': '9:00 AM - 5:00 PM',
      'Tuesday': '9:00 AM - 5:00 PM',
      'Wednesday': '9:00 AM - 5:00 PM',
      'Thursday': '9:00 AM - 5:00 PM',
      'Friday': '9:00 AM - 5:00 PM',
      'Saturday': '9:00 AM - 1:00 PM',
      'Sunday': 'Closed',
    },
    this.licenseNumber,
    this.qualification,
    this.services = const [],
    this.appointmentDuration = 30,
    this.isVerified = false,
    this.isPremium = false,
    this.verificationStatus = 'pending',
  });

  // Copy with method for immutability
  Doctor copyWith({
    String? uid,
    String? name,
    String? email,
    String? specialty,
    String? phone,
    int? experienceYears,
    String? clinicName,
    String? clinicAddress,
    String? bio,
    String? imageUrl,
    bool? isAvailable,
    double? rating,
    int? totalRatings,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? consultationFee,
    List<String>? languages,
    List<String>? education,
    List<String>? certifications,
    Map<String, String>? workingHours,
    String? licenseNumber,
    String? qualification,
    List<String>? services,
    int? appointmentDuration,
    bool? isVerified,
    bool? isPremium,
    String? verificationStatus,
  }) {
    return Doctor(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      specialty: specialty ?? this.specialty,
      phone: phone ?? this.phone,
      experienceYears: experienceYears ?? this.experienceYears,
      clinicName: clinicName ?? this.clinicName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      consultationFee: consultationFee ?? this.consultationFee,
      languages: languages ?? this.languages,
      education: education ?? this.education,
      certifications: certifications ?? this.certifications,
      workingHours: workingHours ?? this.workingHours,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      qualification: qualification ?? this.qualification,
      services: services ?? this.services,
      appointmentDuration: appointmentDuration ?? this.appointmentDuration,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name.trim(),
      'email': email.trim(),
      'specialty': specialty.trim(),
      'phone': phone?.trim(),
      'experienceYears': experienceYears,
      'clinicName': clinicName?.trim(),
      'clinicAddress': clinicAddress?.trim(),
      'bio': bio?.trim(),
      'imageUrl': imageUrl?.trim(),
      'isAvailable': isAvailable,
      'rating': rating,
      'totalRatings': totalRatings,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),

      // New fields
      'consultationFee': consultationFee,
      'languages': languages,
      'education': education,
      'certifications': certifications,
      'workingHours': workingHours,
      'licenseNumber': licenseNumber?.trim(),
      'qualification': qualification?.trim(),
      'services': services,
      'appointmentDuration': appointmentDuration,
      'isVerified': isVerified,
      'isPremium': isPremium,
      'verificationStatus': verificationStatus,
    };
  }

  // Create Doctor from Firestore Document with enhanced parsing
  factory Doctor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Helper function to safely parse dates
    DateTime _parseDate(dynamic timestamp, DateTime fallback) {
      if (timestamp == null) return fallback;
      if (timestamp is Timestamp) return timestamp.toDate();
      if (timestamp is DateTime) return timestamp;
      return fallback;
    }

    return Doctor(
      uid: doc.id,
      name: data['name']?.toString().trim() ?? 'Unknown Doctor',
      email: data['email']?.toString().trim() ?? '',
      specialty: data['specialty']?.toString().trim() ?? 'General Practitioner',
      phone: data['phone']?.toString().trim(),
      experienceYears: _parseInt(data['experienceYears']),
      clinicName: data['clinicName']?.toString().trim(),
      clinicAddress: data['clinicAddress']?.toString().trim(),
      bio: data['bio']?.toString().trim(),
      imageUrl: data['imageUrl']?.toString().trim(),
      isAvailable: data['isAvailable'] ?? true,
      rating: _parseDouble(data['rating']) ?? 0.0,
      totalRatings: _parseInt(data['totalRatings']) ?? 0,
      createdAt: _parseDate(data['createdAt'], DateTime.now()),
      updatedAt: _parseDate(data['updatedAt'], DateTime.now()),

      // New fields with parsing
      consultationFee: _parseDouble(data['consultationFee']),
      languages: _parseStringList(data['languages']) ?? ['English'],
      education: _parseStringList(data['education']) ?? [],
      certifications: _parseStringList(data['certifications']) ?? [],
      workingHours: _parseWorkingHours(data['workingHours']),
      licenseNumber: data['licenseNumber']?.toString().trim(),
      qualification: data['qualification']?.toString().trim(),
      services: _parseStringList(data['services']) ?? [],
      appointmentDuration: _parseInt(data['appointmentDuration']) ?? 30,
      isVerified: data['isVerified'] ?? false,
      isPremium: data['isPremium'] ?? false,
      verificationStatus: data['verificationStatus']?.toString() ??
          (data['isVerified'] == true ? 'verified' : 'pending'),
    );
  }

  // Helper parsing methods
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.whereType<String>().map((e) => e.trim()).toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return null;
  }

  static Map<String, String> _parseWorkingHours(dynamic value) {
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

  // For backward compatibility
  Map<String, dynamic> toJson() => toMap();
  factory Doctor.fromSnapshot(DocumentSnapshot doc) =>
      Doctor.fromFirestore(doc);

  // Utility methods
  String get displayName => 'ডা. $name';

  String get experienceText {
    if (experienceYears == null) return 'অভিজ্ঞতা উল্লেখ করা হয়নি';
    return '$experienceYears ${experienceYears == 1 ? 'বছর' : 'বছর'} অভিজ্ঞতা';
  }

  String get ratingText {
    if (totalRatings == 0) return 'এখনও কোন রেটিং নেই';
    return '${rating.toStringAsFixed(1)} ⭐ ($totalRatings ${totalRatings == 1 ? 'রিভিউ' : 'রিভিউ'})';
  }

  String get availabilityText => isAvailable ? 'উপলব্ধ' : 'অনুপলব্ধ';

  bool get isPendingVerification => verificationStatus == 'pending';

  bool get isRejected => verificationStatus == 'rejected';

  String get verificationStatusDisplay {
    switch (verificationStatus) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending Approval';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

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

  // FIXED: Consultation fee in Bangladeshi Taka without decimal
  String get consultationFeeText {
    if (consultationFee == null) return '৳0';
    return '৳${consultationFee!.toStringAsFixed(0)}';
  }

  // For cases where decimal is needed
  String get consultationFeeTextWithDecimal {
    if (consultationFee == null) return '৳0.00';
    return '৳${consultationFee!.toStringAsFixed(2)}';
  }

  // Simple version without text
  String get consultationFeeSimple {
    if (consultationFee == null) return '৳0';
    return '৳${consultationFee!.toStringAsFixed(0)}';
  }

  String get languagesText => languages.join(', ');

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  bool get isHighlyRated => rating >= 4.5 && totalRatings >= 10;

  bool get isExperienced => (experienceYears ?? 0) >= 5;

  // Get today's working hours
  String get todayWorkingHours {
    final today = DateTime.now().weekday;
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final todayName = days[today - 1];
    return workingHours[todayName] ?? 'Closed';
  }

  // Check if doctor is working now (simplified version)
  bool get isWorkingNow {
    final hours = todayWorkingHours;
    if (hours == 'Closed') return false;

    // For a real implementation, you would parse the time ranges
    // This is a simplified check that assumes working hours include current time
    final now = DateTime.now();
    final hour = now.hour;

    // Basic check - assume working hours are between 9 AM and 5 PM
    return hour >= 9 && hour < 17;
  }

  // Get specialization (alias for specialty for backward compatibility)
  String get specialization => specialty;

  // Get profile image (alias for imageUrl for backward compatibility)
  String? get profileImage => imageUrl;

  // New method to get formatted services (first 2 services)
  String get servicesPreview {
    if (services.isEmpty) return 'কোন সার্ভিস তালিকাভুক্ত নেই';
    if (services.length == 1) return services.first;
    return '${services.take(2).join(', ')}${services.length > 2 ? '...' : ''}';
  }

  // New method to get short bio preview
  String get bioPreview {
    if (bio == null || bio!.isEmpty) return 'কোন বায়ো উপলব্ধ নেই';
    if (bio!.length <= 100) return bio!;
    return '${bio!.substring(0, 100)}...';
  }

  // New method to get experience level
  String get experienceLevel {
    if (experienceYears == null) return 'সাধারণ চিকিৎসক';
    if (experienceYears! < 3) return 'জুনিয়র';
    if (experienceYears! < 8) return 'মিড-লেভেল';
    return 'সিনিয়র';
  }

  // New method to get rating category
  String get ratingCategory {
    if (totalRatings == 0) return 'কোন রেটিং নেই';
    if (rating >= 4.5) return 'অসাধারণ';
    if (rating >= 4.0) return 'খুব ভালো';
    if (rating >= 3.0) return 'ভালো';
    return 'গড়';
  }

  // Equality check
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Doctor && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'Doctor(uid: $uid, name: $name, specialty: $specialty, rating: $rating, isAvailable: $isAvailable)';
  }

  // Empty doctor factory constructor
  factory Doctor.empty() {
    final now = DateTime.now();
    return Doctor(
      uid: '',
      name: '',
      email: '',
      specialty: '',
      createdAt: now,
      updatedAt: now,
    );
  }

  // Check if doctor is empty
  bool get isEmpty => uid.isEmpty;

  // Check if doctor is not empty
  bool get isNotEmpty => uid.isNotEmpty;

  // New method to get next available appointment time
  String get nextAvailableTime {
    if (!isAvailable) return 'আজ উপলব্ধ নেই';

    final now = DateTime.now();
    final currentHour = now.hour;

    // Simple logic for next available slot
    if (currentHour < 9) return 'সকাল ৯:০০';
    if (currentHour < 12)
      return '${currentHour + 1}:00 ${currentHour + 1 < 12 ? 'AM' : 'PM'}';
    if (currentHour < 14) return 'বিকাল ২:০০';
    if (currentHour < 17) return '${currentHour + 1}:00 PM';

    return 'আগামীকাল সকাল ৯:০০';
  }

  // New method to get doctor's expertise level
  String get expertiseLevel {
    if (experienceYears == null) return 'সাধারণ চিকিৎসক';
    if (experienceYears! >= 10) return 'বিশেষজ্ঞ $specialty';
    if (experienceYears! >= 5) return 'সিনিয়র $specialty';
    return specialty;
  }

  // New method to get consultation fee with service type
  String getConsultationFeeText(String serviceType) {
    if (consultationFee == null) return 'ফ্রি';

    final baseFee = consultationFee!;
    double serviceFee = baseFee;

    // Adjust fee based on service type (example logic)
    switch (serviceType.toLowerCase()) {
      case 'surgery':
      case 'surgical consultation':
        serviceFee = baseFee * 1.5;
        break;
      case 'emergency':
      case 'urgent care':
        serviceFee = baseFee * 2.0;
        break;
      case 'follow-up':
      case 'routine checkup':
        serviceFee = baseFee * 0.8;
        break;
    }

    return '৳${serviceFee.toStringAsFixed(0)}';
  }

  // New method to get formatted working hours for display
  Map<String, String> get formattedWorkingHours {
    final banglaDays = {
      'Monday': 'সোমবার',
      'Tuesday': 'মঙ্গলবার',
      'Wednesday': 'বুধবার',
      'Thursday': 'বৃহস্পতিবার',
      'Friday': 'শুক্রবার',
      'Saturday': 'শনিবার',
      'Sunday': 'রবিবার'
    };

    return workingHours
        .map((key, value) => MapEntry(banglaDays[key] ?? key, value));
  }

  // New method to check if doctor offers specific service
  bool offersService(String service) {
    return services.any((s) => s.toLowerCase().contains(service.toLowerCase()));
  }

  // New method to get available time slots
  List<String> get availableTimeSlots {
    if (!isAvailable) return [];

    return [
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM',
      '04:00 PM',
      '04:30 PM'
    ];
  }

  // New method to get doctor's contact info for display
  String get contactInfo {
    final parts = <String>[];
    if (phone != null) parts.add('ফোন: $phone');
    if (email.isNotEmpty) parts.add('ইমেইল: $email');
    if (clinicAddress != null) parts.add('ঠিকানা: $clinicAddress');

    return parts.join('\n');
  }

  // New method to get doctor's qualifications summary
  String get qualificationsSummary {
    final parts = <String>[];
    if (qualification != null) parts.add(qualification!);
    if (education.isNotEmpty) parts.addAll(education.take(2));
    if (certifications.isNotEmpty) parts.addAll(certifications.take(2));

    return parts.join(' • ');
  }
}
