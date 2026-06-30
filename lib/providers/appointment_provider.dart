// lib/providers/appointment_provider.dart
// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/appointment_model.dart';
import 'package:medicore/services/appointment_service.dart';

class AppointmentProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load appointments for a specific user (patient)
  Future<void> loadUserAppointments(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .orderBy('appointmentDate', descending: false)
          .get();

      _appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load appointments: $e';
      print('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load ALL appointments (for admin)
  Future<void> loadAllAppointments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .orderBy('appointmentDate', descending: false)
          .get();

      _appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load appointments: $e';
      print('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load appointments by status (for admin filtering)
  Future<void> loadAppointmentsByStatus(String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('status', isEqualTo: status)
          .orderBy('appointmentDate', descending: false)
          .get();

      _appointments = querySnapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load appointments: $e';
      print('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Book new appointment
  Future<bool> bookAppointment({
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required DateTime appointmentDate,
    required String timeSlot,
    required String reason,
    required double consultationFee,
    String? notes,
  }) async {
    try {
      // Delegate to AppointmentService to enforce atomic slot locking
      final service = AppointmentService();
      await service.bookAppointment(
        patientId: patientId,
        patientName: patientName,
        doctorId: doctorId,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        reason: reason,
        consultationFee: consultationFee,
        notes: notes,
        isPaid: false,
      );

      // Reload appointments for the specific user
      await loadUserAppointments(patientId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to book appointment: $e';
      print('Error booking appointment: $e');
      notifyListeners();
      return false;
    }
  }

  // Cancel appointment (enforces 30-minute window from booking time)
  Future<bool> cancelAppointment(String appointmentId, String patientId) async {
    try {
      // Use AppointmentService so slot guards are released correctly
      final service = AppointmentService();
      await service.cancelAppointment(appointmentId);

      await loadUserAppointments(patientId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to cancel appointment: $e';
      print('Error cancelling appointment: $e');
      notifyListeners();
      return false;
    }
  }

  // Permanently delete an appointment (allowed typically for cancelled/completed)
  Future<bool> deleteAppointment(String appointmentId, String patientId) async {
    try {
      final service = AppointmentService();
      await service.deleteAppointment(appointmentId);

      await loadUserAppointments(patientId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete appointment: $e';
      print('Error deleting appointment: $e');
      notifyListeners();
      return false;
    }
  }

  // Update appointment status (for admin)
  Future<bool> updateAppointmentStatus({
    required String appointmentId,
    required String newStatus,
    String? patientId, // Optional: if you want to reload user appointments
  }) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      // Update local state
      final index =
          _appointments.indexWhere((appt) => appt.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      // Reload appropriate data
      if (patientId != null) {
        await loadUserAppointments(patientId);
      } else {
        await loadAllAppointments();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update appointment: $e';
      print('Error updating appointment: $e');
      notifyListeners();
      return false;
    }
  }

  // Complete appointment with prescription and diagnosis
  Future<bool> completeAppointment({
    required String appointmentId,
    required String prescription,
    required String diagnosis,
    String? followUpDate,
    String? patientId,
  }) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'completed',
        'prescription': prescription,
        'diagnosis': diagnosis,
        'followUpDate': followUpDate,
        'updatedAt': Timestamp.now(),
      });

      // Update local state
      final index =
          _appointments.indexWhere((appt) => appt.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          status: 'completed',
          prescription: prescription,
          diagnosis: diagnosis,
          followUpDate: followUpDate,
          updatedAt: DateTime.now(),
        );
      }

      if (patientId != null) {
        await loadUserAppointments(patientId);
      } else {
        await loadAllAppointments();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to complete appointment: $e';
      print('Error completing appointment: $e');
      notifyListeners();
      return false;
    }
  }

  // Mark appointment as paid
  Future<bool> markAsPaid(String appointmentId, {String? patientId}) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'isPaid': true,
        'updatedAt': Timestamp.now(),
      });

      // Update local state
      final index =
          _appointments.indexWhere((appt) => appt.id == appointmentId);
      if (index != -1) {
        _appointments[index] = _appointments[index].copyWith(
          isPaid: true,
          updatedAt: DateTime.now(),
        );
      }

      if (patientId != null) {
        await loadUserAppointments(patientId);
      } else {
        await loadAllAppointments();
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to mark as paid: $e';
      print('Error marking as paid: $e');
      notifyListeners();
      return false;
    }
  }

  // Get appointment by ID
  Appointment? getAppointmentById(String appointmentId) {
    try {
      return _appointments.firstWhere((appt) => appt.id == appointmentId);
    } catch (e) {
      return null;
    }
  }

  // Filter methods
  List<Appointment> get upcomingAppointments {
    return _appointments
        .where((appointment) => appointment.isUpcoming)
        .toList();
  }

  List<Appointment> get pastAppointments {
    return _appointments.where((appointment) => appointment.isPast).toList();
  }

  List<Appointment> get pendingAppointments {
    return _appointments.where((appointment) => appointment.isPending).toList();
  }

  List<Appointment> get confirmedAppointments {
    return _appointments
        .where((appointment) => appointment.isConfirmed)
        .toList();
  }

  List<Appointment> get completedAppointments {
    return _appointments
        .where((appointment) => appointment.isCompleted)
        .toList();
  }

  List<Appointment> get cancelledAppointments {
    return _appointments
        .where((appointment) => appointment.isCancelled)
        .toList();
  }

  List<Appointment> get todayAppointments {
    return _appointments.where((appointment) => appointment.isToday).toList();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear appointments
  void clearAppointments() {
    _appointments.clear();
    notifyListeners();
  }
}
