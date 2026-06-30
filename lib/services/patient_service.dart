// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/user.dart' as app_model;
import 'package:medicore/models/patient.dart';

class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generatePatientId(String sourceId) {
    final normalized = sourceId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final suffix = normalized.length >= 6
        ? normalized.substring(0, 6).toUpperCase()
        : normalized.padRight(6, '0').toUpperCase();
    return 'MED-PAT-$suffix';
  }

  Future<Patient> syncPatientFromUser(app_model.User user) async {
    if (_useMockData) {
      final existing = _mockPatients.values.where((patient) {
        return patient.id == user.id ||
            patient.email.toLowerCase() == user.email.toLowerCase();
      }).toList();

      if (existing.isNotEmpty) {
        return existing.first;
      }

      final patient = Patient(
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        dateOfBirth: user.dateOfBirth,
        patientId: _generatePatientId(user.id),
        authProvider: user.authProvider,
        role: 'patient',
        isVerified: user.isVerified,
        photoUrl: user.photoUrl,
        createdAt: user.createdAt ?? DateTime.now(),
        updatedAt: user.updatedAt ?? DateTime.now(),
        gender: user.gender,
        profileImage: user.profileImage,
        address: user.address,
      );

      _mockPatients[user.id] = patient;
      return patient;
    }

    final docRef = _firestore.collection('patients').doc(user.id);
    final doc = await docRef.get();

    if (doc.exists) {
      return Patient.fromFirestore(doc);
    }

    final patient = Patient(
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      dateOfBirth: user.dateOfBirth,
      patientId: _generatePatientId(user.id),
      authProvider: user.authProvider,
      role: 'patient',
      isVerified: user.isVerified,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt ?? DateTime.now(),
      updatedAt: user.updatedAt ?? DateTime.now(),
      gender: user.gender,
      profileImage: user.profileImage,
      address: user.address,
    );

    await docRef.set(patient.toMap());
    return patient;
  }

  // Mock database for development (remove when switching to Firebase)
  final Map<String, Patient> _mockPatients = {
    'p1': Patient(
      id: 'p1',
      email: 'patient@example.com',
      name: 'Patient Name',
      phone: '123-456-7890',
      dateOfBirth: DateTime(1990, 5, 15),
      patientId: 'MED-PAT-P10001',
      authProvider: '',
    ),
  };

  // Use this flag to switch between mock and Firebase
  final bool _useMockData = true; // Set to false when ready for Firebase

  Future<Patient> getPatientDetails(String patientId) async {
    if (_useMockData) {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 600));
      if (_mockPatients.containsKey(patientId)) {
        return _mockPatients[patientId]!;
      }
      throw Exception('Patient not found');
    } else {
      // Firebase implementation
      try {
        final doc =
            await _firestore.collection('patients').doc(patientId).get();
        if (doc.exists) {
          return Patient.fromFirestore(doc);
        }
        throw Exception('Patient not found in database');
      } catch (e) {
        throw Exception('Failed to fetch patient: $e');
      }
    }
  }

  Future<Patient> updatePatientDetails(Patient patient) async {
    if (_useMockData) {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
      _mockPatients[patient.id] = patient;
      return patient;
    } else {
      // Firebase implementation
      try {
        await _firestore
            .collection('patients')
            .doc(patient.id)
            .update(patient.toMap());
        return patient;
      } catch (e) {
        throw Exception('Failed to update patient: $e');
      }
    }
  }

  // Additional methods with both mock and Firebase implementations

  Future<List<Patient>> getAllPatients() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      return _mockPatients.values.toList();
    } else {
      try {
        final querySnapshot = await _firestore.collection('patients').get();
        return querySnapshot.docs
            .map((doc) => Patient.fromFirestore(doc))
            .toList();
      } catch (e) {
        throw Exception('Failed to fetch patients: $e');
      }
    }
  }

  Future<void> deletePatient(String patientId) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (_mockPatients.containsKey(patientId)) {
        _mockPatients.remove(patientId);
      } else {
        throw Exception('Patient not found');
      }
    } else {
      try {
        await _firestore.collection('patients').doc(patientId).delete();
      } catch (e) {
        throw Exception('Failed to delete patient: $e');
      }
    }
  }

  Future<Patient> createPatient({
    required String email,
    required String name,
    required String phone,
    required DateTime dateOfBirth,
    String? gender,
    String? address,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 700));
      final newId = 'p${_mockPatients.length + 1}';
      final newPatient = Patient(
        id: newId,
        email: email,
        name: name,
        phone: phone,
        dateOfBirth: dateOfBirth,
        patientId: _generatePatientId(newId),
        gender: gender ?? 'prefer-not-to-say',
        address: address,
        createdAt: DateTime.now(),
        authProvider: '',
      );
      _mockPatients[newId] = newPatient;
      return newPatient;
    } else {
      try {
        final docRef = _firestore.collection('patients').doc();
        final newPatient = Patient(
          id: docRef.id,
          email: email,
          name: name,
          phone: phone,
          dateOfBirth: dateOfBirth,
          patientId: _generatePatientId(docRef.id),
          gender: gender ?? 'prefer-not-to-say',
          address: address,
          createdAt: DateTime.now(),
          authProvider: '',
        );
        await docRef.set(newPatient.toMap());
        return newPatient;
      } catch (e) {
        throw Exception('Failed to create patient: $e');
      }
    }
  }

  Future<List<Patient>> searchPatients(String query) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      final lowercaseQuery = query.toLowerCase();
      return _mockPatients.values.where((patient) {
        return patient.name.toLowerCase().contains(lowercaseQuery) ||
            patient.email.toLowerCase().contains(lowercaseQuery) ||
            patient.phone.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } else {
      try {
        final querySnapshot = await _firestore
            .collection('patients')
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThan: query + 'z')
            .get();

        return querySnapshot.docs
            .map((doc) => Patient.fromFirestore(doc))
            .toList();
      } catch (e) {
        throw Exception('Failed to search patients: $e');
      }
    }
  }

  Future<Patient?> getPatientByEmail(String email) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        return _mockPatients.values.firstWhere(
          (patient) => patient.email.toLowerCase() == email.toLowerCase(),
        );
      } catch (e) {
        return null;
      }
    } else {
      try {
        final querySnapshot = await _firestore
            .collection('patients')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return Patient.fromFirestore(querySnapshot.docs.first);
        }
        return null;
      } catch (e) {
        throw Exception('Failed to find patient by email: $e');
      }
    }
  }

  Future<Patient> updateHealthProfile({
    required String patientId,
    required Map<String, dynamic> healthData,
  }) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!_mockPatients.containsKey(patientId)) {
        throw Exception('Patient not found');
      }
      final patient = _mockPatients[patientId]!;
      final updatedPatient = patient.copyWith(
        healthProfile: {...patient.healthProfile ?? {}, ...healthData},
      );
      _mockPatients[patientId] = updatedPatient;
      return updatedPatient;
    } else {
      try {
        await _firestore.collection('patients').doc(patientId).update({
          'healthProfile': healthData,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final doc =
            await _firestore.collection('patients').doc(patientId).get();
        return Patient.fromFirestore(doc);
      } catch (e) {
        throw Exception('Failed to update health profile: $e');
      }
    }
  }

  Future<List<Patient>> getPatientsWithIncompleteProfiles() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockPatients.values
          .where((patient) => !patient.hasCompleteProfile)
          .toList();
    } else {
      try {
        // This would need a more complex query in real Firebase
        final allPatients = await getAllPatients();
        return allPatients
            .where((patient) => !patient.hasCompleteProfile)
            .toList();
      } catch (e) {
        throw Exception('Failed to get incomplete profiles: $e');
      }
    }
  }

  Future<Map<String, dynamic>> getPatientStats() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800));
      final totalPatients = _mockPatients.length;
      final completeProfiles =
          _mockPatients.values.where((p) => p.hasCompleteProfile).length;
      final incompleteProfiles = totalPatients - completeProfiles;

      return {
        'totalPatients': totalPatients,
        'completeProfiles': completeProfiles,
        'incompleteProfiles': incompleteProfiles,
        'completionRate':
            totalPatients > 0 ? (completeProfiles / totalPatients) * 100 : 0,
      };
    } else {
      try {
        final querySnapshot = await _firestore.collection('patients').get();
        final totalPatients = querySnapshot.docs.length;
        final completeProfiles = querySnapshot.docs.where((doc) {
          final patient = Patient.fromFirestore(doc);
          return patient.hasCompleteProfile;
        }).length;
        final incompleteProfiles = totalPatients - completeProfiles;

        return {
          'totalPatients': totalPatients,
          'completeProfiles': completeProfiles,
          'incompleteProfiles': incompleteProfiles,
          'completionRate':
              totalPatients > 0 ? (completeProfiles / totalPatients) * 100 : 0,
        };
      } catch (e) {
        throw Exception('Failed to get patient statistics: $e');
      }
    }
  }
}
