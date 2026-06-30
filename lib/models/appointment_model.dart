// lib/models/appointment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String patientName;
  final DateTime appointmentDate;
  final String timeSlot;
  final String status; // pending, confirmed, completed, cancelled
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String reason;
  final double consultationFee;
  final String? prescription;
  final String? diagnosis;
  final String? followUpDate;
  final bool isPaid;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.patientName,
    required this.appointmentDate,
    required this.timeSlot,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.reason,
    required this.consultationFee,
    this.prescription,
    this.diagnosis,
    this.followUpDate,
    required this.isPaid,
  });

  // Factory constructor for Firestore
  factory Appointment.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Appointment(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      doctorId: data['doctorId'] as String? ?? '',
      doctorName: data['doctorName'] as String? ?? '',
      doctorSpecialty: data['doctorSpecialty'] as String? ?? '',
      patientName: data['patientName'] as String? ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp).toDate(),
      reason: data['reason'] as String? ?? '',
      consultationFee: (data['consultationFee'] as num?)?.toDouble() ?? 0.0,
      prescription: data['prescription'] as String?,
      diagnosis: data['diagnosis'] as String?,
      followUpDate: data['followUpDate'] as String?,
      isPaid: data['isPaid'] as bool? ?? false,
    );
  }

  // Factory constructor for JSON
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String? ?? '',
      doctorSpecialty: json['doctorSpecialty'] as String? ?? '',
      patientName: json['patientName'] as String? ?? '',
      appointmentDate: DateTime.parse(json['appointmentDate'] as String? ??
          json['appointmentTime'] as String),
      timeSlot: json['timeSlot'] as String? ?? '',
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      reason: json['reason'] as String,
      consultationFee: (json['consultationFee'] as num?)?.toDouble() ?? 0.0,
      prescription: json['prescription'] as String?,
      diagnosis: json['diagnosis'] as String?,
      followUpDate: json['followUpDate'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }

  // For Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'patientName': patientName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': timeSlot,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reason': reason,
      'consultationFee': consultationFee,
      'prescription': prescription,
      'diagnosis': diagnosis,
      'followUpDate': followUpDate,
      'isPaid': isPaid,
    };
  }

  // For JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'patientName': patientName,
      'appointmentDate': appointmentDate.toIso8601String(),
      'appointmentTime':
          appointmentDate.toIso8601String(), // Backward compatibility
      'timeSlot': timeSlot,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reason': reason,
      'consultationFee': consultationFee,
      'prescription': prescription,
      'diagnosis': diagnosis,
      'followUpDate': followUpDate,
      'isPaid': isPaid,
    };
  }

  // Copy with method for easy updates
  Appointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? patientName,
    DateTime? appointmentDate,
    String? timeSlot,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reason,
    double? consultationFee,
    String? prescription,
    String? diagnosis,
    String? followUpDate,
    bool? isPaid,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      patientName: patientName ?? this.patientName,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reason: reason ?? this.reason,
      consultationFee: consultationFee ?? this.consultationFee,
      prescription: prescription ?? this.prescription,
      diagnosis: diagnosis ?? this.diagnosis,
      followUpDate: followUpDate ?? this.followUpDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  // Utility methods
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  bool get isUpcoming =>
      appointmentDate.isAfter(DateTime.now()) && !isCancelled;
  bool get isPast => appointmentDate.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return appointmentDate.year == now.year &&
        appointmentDate.month == now.month &&
        appointmentDate.day == now.day;
  }

  // Get formatted consultation fee
  String get formattedFee => '৳${consultationFee.toStringAsFixed(2)}';

  // Check if appointment requires payment
  bool get requiresPayment => !isPaid && (isConfirmed || isCompleted);

  // Get appointment duration (assuming 30 minutes per slot)
  Duration get duration => const Duration(minutes: 30);

  // Get appointment end time
  DateTime get endTime => appointmentDate.add(duration);

  // Get formatted date for display
  String get formattedDate {
    return '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
  }

  // Get formatted time for display
  String get formattedTime {
    return '${appointmentDate.hour.toString().padLeft(2, '0')}:${appointmentDate.minute.toString().padLeft(2, '0')}';
  }

  // Get appointmentTime for backward compatibility
  DateTime get appointmentTime => appointmentDate;

  // Convert to string for debugging
  @override
  String toString() {
    return 'Appointment(id: $id, patientId: $patientId, doctorName: $doctorName, date: $appointmentDate, status: $status, reason: $reason, fee: $consultationFee)';
  }

  // Equality check
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appointment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
