// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:medicore/models/user.dart' as app_model;
import 'package:medicore/models/patient.dart';
import 'package:medicore/services/patient_service.dart';
// Ensure that the PatientService class exists in the imported file.

class PatientProvider extends ChangeNotifier {
  final PatientService _patientService = PatientService();
  Patient? _currentPatient;
  List<Patient> _allPatients = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Patient? get currentPatient => _currentPatient;
  List<Patient> get allPatients => _allPatients;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCurrentPatient => _currentPatient != null;

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Fetch patient details by ID
  Future<void> fetchPatientDetails(String patientId) async {
    _setLoading(true);
    _setError('');
    try {
      _currentPatient = await _patientService.getPatientDetails(patientId);
    } catch (e) {
      _setError('Failed to fetch patient details: $e');
      print(e);
    } finally {
      _setLoading(false);
    }
  }

  // Sync the current logged-in auth user to a patient record.
  Future<bool> syncCurrentPatientFromUser(app_model.User? user) async {
    if (user == null) {
      clearCurrentPatient();
      return false;
    }

    _setLoading(true);
    _setError('');
    try {
      final syncedPatient = await _patientService.syncPatientFromUser(user);
      _currentPatient = syncedPatient;

      final index = _allPatients.indexWhere((p) => p.id == syncedPatient.id);
      if (index == -1) {
        _allPatients.add(syncedPatient);
      } else {
        _allPatients[index] = syncedPatient;
      }

      return true;
    } catch (e) {
      _setError('Failed to sync patient profile: $e');
      print(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update patient details
  Future<bool> updatePatientDetails(Patient patient) async {
    _setLoading(true);
    _setError('');
    try {
      _currentPatient = await _patientService.updatePatientDetails(patient);
      return true;
    } catch (e) {
      _setError('Failed to update patient details: $e');
      print(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Fetch all patients
  Future<void> fetchAllPatients() async {
    _setLoading(true);
    _setError('');
    try {
      _allPatients = await _patientService.getAllPatients();
    } catch (e) {
      _setError('Failed to fetch patients: $e');
      print(e);
    } finally {
      _setLoading(false);
    }
  }

  // Create new patient
  Future<bool> createPatient({
    required String email,
    required String name,
    required String phone,
    required DateTime dateOfBirth,
    String? gender,
    String? address,
  }) async {
    _setLoading(true);
    _setError('');
    try {
      final newPatient = await _patientService.createPatient(
        email: email,
        name: name,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        address: address,
      );
      _allPatients.add(newPatient);
      return true;
    } catch (e) {
      _setError('Failed to create patient: $e');
      print(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete patient
  Future<bool> deletePatient(String patientId) async {
    _setLoading(true);
    _setError('');
    try {
      await _patientService.deletePatient(patientId);
      _allPatients.removeWhere((patient) => patient.id == patientId);
      if (_currentPatient?.id == patientId) {
        _currentPatient = null;
      }
      return true;
    } catch (e) {
      _setError('Failed to delete patient: $e');
      print(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Search patients
  Future<List<Patient>> searchPatients(String query) async {
    _setError('');
    try {
      return await _patientService.searchPatients(query);
    } catch (e) {
      _setError('Failed to search patients: $e');
      print(e);
      return [];
    }
  }

  // Get patient by email
  Future<Patient?> getPatientByEmail(String email) async {
    _setError('');
    try {
      return await _patientService.getPatientByEmail(email);
    } catch (e) {
      _setError('Failed to find patient: $e');
      print(e);
      return null;
    }
  }

  // Update health profile
  Future<bool> updateHealthProfile({
    required String patientId,
    required Map<String, dynamic> healthData,
  }) async {
    _setLoading(true);
    _setError('');
    try {
      final updatedPatient = await _patientService.updateHealthProfile(
        patientId: patientId,
        healthData: healthData,
      );

      // Update in current patient if it's the same
      if (_currentPatient?.id == patientId) {
        _currentPatient = updatedPatient;
      }

      // Update in all patients list
      final index = _allPatients.indexWhere((p) => p.id == patientId);
      if (index != -1) {
        _allPatients[index] = updatedPatient;
      }

      return true;
    } catch (e) {
      _setError('Failed to update health profile: $e');
      print(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get patients with incomplete profiles
  Future<List<Patient>> getIncompleteProfiles() async {
    _setError('');
    try {
      return await _patientService.getPatientsWithIncompleteProfiles();
    } catch (e) {
      _setError('Failed to get incomplete profiles: $e');
      print(e);
      return [];
    }
  }

  // Get patient statistics
  Future<Map<String, dynamic>?> getPatientStatistics() async {
    _setError('');
    try {
      return await _patientService.getPatientStats();
    } catch (e) {
      _setError('Failed to get statistics: $e');
      print(e);
      return null;
    }
  }

  // Set current patient
  void setCurrentPatient(Patient? patient) {
    _currentPatient = patient;
    notifyListeners();
  }

  // Clear current patient
  void clearCurrentPatient() {
    _currentPatient = null;
    notifyListeners();
  }

  // Refresh current patient data
  Future<void> refreshCurrentPatient() async {
    if (_currentPatient != null) {
      await fetchPatientDetails(_currentPatient!.id);
    }
  }

  // Check if patient profile is complete
  bool get isCurrentPatientProfileComplete {
    return _currentPatient?.hasCompleteProfile ?? false;
  }

  // Get patient age
  int? get currentPatientAge {
    return _currentPatient?.age;
  }

  // Get formatted date of birth
  String? get currentPatientFormattedDOB {
    return _currentPatient?.formattedDateOfBirth;
  }

  /// Add a doctor connection for the current patient
  Future<bool> connectDoctor(String doctorId) async {
    if (_currentPatient == null) {
      _setError('No current patient');
      return false;
    }

    try {
      final updatedPatient = _currentPatient!.addConnectedDoctor(doctorId);
      return await updatePatientDetails(updatedPatient);
    } catch (e) {
      _setError('Failed to connect doctor: $e');
      print(e);
      return false;
    }
  }

  /// Remove a doctor connection for the current patient
  Future<bool> disconnectDoctor(String doctorId) async {
    if (_currentPatient == null) {
      _setError('No current patient');
      return false;
    }

    try {
      final updatedPatient = _currentPatient!.removeConnectedDoctor(doctorId);
      return await updatePatientDetails(updatedPatient);
    } catch (e) {
      _setError('Failed to disconnect doctor: $e');
      print(e);
      return false;
    }
  }

  /// Check if a doctor is connected to the current patient
  bool isDoctorConnected(String doctorId) {
    return _currentPatient?.isDoctorConnected(doctorId) ?? false;
  }

  /// Get the list of connected doctor IDs for the current patient
  List<String> get connectedDoctorIds {
    return _currentPatient?.connectedDoctorIds ?? [];
  }

  /// Get the count of connected doctors
  int get connectedDoctorsCount {
    return _currentPatient?.connectedDoctorsCount ?? 0;
  }

  /// Get the patient ID of the current patient
  String? get currentPatientId {
    final patientId = _currentPatient?.patientId;
    if (patientId != null && patientId.isNotEmpty) {
      return patientId;
    }
    return _currentPatient?.id;
  }
}
