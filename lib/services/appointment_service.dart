// lib/services/appointment_service.dart
import 'package:medicore/models/appointment_model.dart';
import 'package:medicore/services/push_notification_service.dart';
import 'package:medicore/services/notification_writer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _slotKey(String doctorId, DateTime dateTime) {
    // Use UTC millis to avoid timezone mismatches in keys
    return 'doctor_${doctorId}_${dateTime.toUtc().millisecondsSinceEpoch}';
  }

  String _patientSlotKey(String patientId, DateTime dateTime) {
    return 'patient_${patientId}_${dateTime.toUtc().millisecondsSinceEpoch}';
  }

  // Get appointments for a specific patient
  Future<List<Appointment>> getAppointmentsForPatient(String patientId) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .orderBy('appointmentDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch appointments: $e');
    }
  }

  // Get booked slot minutes (minutes since midnight) for a doctor on a date
  Future<Set<int>> getBookedSlotMinutesForDoctorOnDate({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('appointmentDate')
          .get();

      final booked = <int>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['appointmentDate'];
        DateTime? dt;
        if (ts is Timestamp) {
          dt = ts.toDate();
        } else if (ts is String) {
          dt = DateTime.tryParse(ts);
        }
        if (dt != null) {
          final local = dt.toLocal();
          booked.add(local.hour * 60 + local.minute);
        }
      }
      return booked;
    } catch (e) {
      throw Exception('Failed to fetch booked slots: $e');
    }
  }

  // Real-time stream of booked slot minutes for a doctor on a date
  Stream<Set<int>> watchBookedSlotsForDoctorOnDate({
    required String doctorId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('appointmentDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('appointmentDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .where('status', whereIn: ['pending', 'confirmed'])
        .snapshots()
        .map((snapshot) {
      final booked = <int>{};
      for (final doc in snapshot.docs) {
        final ts = doc.data()['appointmentDate'];
        DateTime? dt;
        if (ts is Timestamp) {
          dt = ts.toDate();
        } else if (ts is String) {
          dt = DateTime.tryParse(ts);
        }
        if (dt != null) {
          final local = dt.toLocal();
          booked.add(local.hour * 60 + local.minute);
        }
      }
      return booked;
    });
  }

  // Get all appointments (for admin)
  Future<List<Appointment>> getAllAppointments() async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .orderBy('appointmentDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all appointments: $e');
    }
  }

  // Book a new appointment - FIXED with proper parameters
  Future<Appointment> bookAppointment({
    required String patientId,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    required String patientName,
    required DateTime appointmentDate,
    required String timeSlot,
    required String reason,
    required double consultationFee,
    String? notes,
    String? prescription,
    String? diagnosis,
    String? followUpDate,
    bool isPaid = false,
  }) async {
    try {
      // Deterministic slot key ensures uniqueness per doctor & timeslot
      final slotDocId = _slotKey(doctorId, appointmentDate);
      final now = DateTime.now();

      final newAppointment =
          await _firestore.runTransaction<Appointment>((transaction) async {
        final slotRef = _firestore.collection('appointments').doc(slotDocId);
        final guardRef = _firestore.collection('slot_guards').doc(slotDocId);
        final pGuardRef = _firestore
            .collection('patient_slot_guards')
            .doc(_patientSlotKey(patientId, appointmentDate));

        // Check a lock/guard for this slot (prevents races across clients)
        final guardSnap = await transaction.get(guardRef);
        if (guardSnap.exists) {
          throw Exception(
              'এই সময়টি ইতিমধ্যে বুক করা হয়েছে। অন্য একটি সময় নির্বাচন করুন।');
        }

        // Patient-level guard to avoid same user double-booking same time
        final pGuardSnap = await transaction.get(pGuardRef);
        if (pGuardSnap.exists) {
          throw Exception(
              'এই সময়টি ইতিমধ্যে বুক করা হয়েছে। অন্য একটি সময় নির্বাচন করুন।');
        }

        final existing = await transaction.get(slotRef);
        if (existing.exists) {
          final data = existing.data() as Map<String, dynamic>;
          final status = (data['status'] as String?) ?? 'pending';
          // If the existing appointment at this slot is active, block booking
          if (status != 'cancelled') {
            throw Exception(
                'এই সময়টি ইতিমধ্যে বুক করা হয়েছে। অন্য একটি সময় নির্বাচন করুন।');
          }
        }

        final appointment = Appointment(
          id: slotDocId,
          patientId: patientId,
          doctorId: doctorId,
          doctorName: doctorName,
          doctorSpecialty: doctorSpecialty,
          patientName: patientName,
          appointmentDate: appointmentDate,
          timeSlot: timeSlot,
          status: 'pending',
          notes: notes,
          createdAt: now,
          updatedAt: now,
          reason: reason,
          consultationFee: consultationFee,
          prescription: prescription,
          diagnosis: diagnosis,
          followUpDate: followUpDate,
          isPaid: isPaid,
        );

        final map = appointment.toMap();
        map['slotKey'] = slotDocId; // Helpful for future queries/migrations
        // Create appointment and guard atomically
        transaction.set(slotRef, map);
        transaction.set(guardRef, {
          'appointmentId': slotDocId,
          'doctorId': doctorId,
          'appointmentDate': Timestamp.fromDate(appointmentDate),
          'createdAt': Timestamp.fromDate(now),
          'status': 'locked',
        });
        transaction.set(pGuardRef, {
          'appointmentId': slotDocId,
          'patientId': patientId,
          'appointmentDate': Timestamp.fromDate(appointmentDate),
          'createdAt': Timestamp.fromDate(now),
          'status': 'locked',
        });
        return appointment;
      });

      // Fire a local notification to inform the user immediately (outside transaction)
      try {
        await PushNotificationService.instance.showLocalNotification(
          title: 'Appointment booked',
          body:
              'Your appointment with Dr. $doctorName on ${appointmentDate.toLocal()} is pending confirmation.',
          payload: {
            'type': 'appointment',
            'appointmentId': newAppointment.id,
            'doctorId': doctorId,
          },
        );
      } catch (_) {}

      // Write in-app notifications for both patient and doctor
      await NotificationWriter.write(
        userId: patientId,
        title: 'Appointment Booked',
        body: 'Your appointment with Dr. $doctorName is pending confirmation.',
        type: 'appointment',
        payload: {'appointmentId': newAppointment.id, 'doctorId': doctorId},
      );
      await NotificationWriter.write(
        userId: doctorId,
        title: 'New Appointment Request',
        body: '$patientName has booked an appointment with you.',
        type: 'appointment',
        payload: {'appointmentId': newAppointment.id, 'patientId': patientId},
      );

      return newAppointment;
    } catch (e) {
      throw Exception('Failed to book appointment: $e');
    }
  }

  // Cancel an appointment (enforces 30-minute window from booking time)
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      // Fetch existing appointment for validation + notification context
      final doc =
          await _firestore.collection('appointments').doc(appointmentId).get();

      if (!doc.exists) {
        throw Exception('Appointment not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] as String?) ?? 'pending';
      final createdAtTs = data['createdAt'];
      final createdAt = createdAtTs is Timestamp
          ? createdAtTs.toDate()
          : DateTime.tryParse(createdAtTs?.toString() ?? '');

      // Disallow cancelling completed/cancelled
      if (status == 'completed' || status == 'cancelled') {
        throw Exception('Appointment cannot be cancelled in current status');
      }

      // Enforce 30-minute cancellation window from booking time
      if (createdAt != null) {
        final diff = DateTime.now().difference(createdAt);
        if (diff > const Duration(minutes: 30)) {
          throw Exception(
              'Appointment can only be cancelled within 30 minutes of booking');
        }
      }

      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
      });

      // Free the slot guards so others can book the slot again
      try {
        final appt = doc.exists ? Appointment.fromFirestore(doc) : null;
        if (appt != null) {
          final guardId = _slotKey(appt.doctorId, appt.appointmentDate);
          await _firestore.collection('slot_guards').doc(guardId).delete();
          final pGuardId =
              _patientSlotKey(appt.patientId, appt.appointmentDate);
          await _firestore
              .collection('patient_slot_guards')
              .doc(pGuardId)
              .delete();
        }
      } catch (_) {
        // Best-effort cleanup; ignore failures
      }

      // Best-effort local notification
      try {
        final appt = doc.exists ? Appointment.fromFirestore(doc) : null;
        if (appt != null) {
          await PushNotificationService.instance.showLocalNotification(
            title: 'অ্যাপয়েন্টমেন্ট বাতিল',
            body:
                'আপনার Dr. ${appt.doctorName} এর সাথে ${appt.appointmentDate.toLocal()} অ্যাপয়েন্টমেন্টটি বাতিল হয়েছে।',
            payload: {
              'type': 'appointment',
              'appointmentId': appointmentId,
              'doctorId': appt.doctorId,
            },
          );
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Confirm an appointment (for admin)
  Future<void> confirmAppointment(String appointmentId) async {
    try {
      final doc =
          await _firestore.collection('appointments').doc(appointmentId).get();
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'confirmed',
        'updatedAt': Timestamp.now(),
      });

      // Notify locally
      try {
        final appt = doc.exists ? Appointment.fromFirestore(doc) : null;
        if (appt != null) {
          await PushNotificationService.instance.showLocalNotification(
            title: 'অ্যাপয়েন্টমেন্ট নিশ্চিত',
            body:
                'Dr. ${appt.doctorName} এর সাথে ${appt.appointmentDate.toLocal()} অ্যাপয়েন্টমেন্টটি নিশ্চিত হয়েছে।',
            payload: {
              'type': 'appointment',
              'appointmentId': appointmentId,
              'doctorId': appt.doctorId,
            },
          );
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to confirm appointment: $e');
    }
  }

  // Complete an appointment with optional medical details
  Future<void> completeAppointment({
    required String appointmentId,
    String? prescription,
    String? diagnosis,
    String? followUpDate,
  }) async {
    try {
      // Read current for context
      final doc =
          await _firestore.collection('appointments').doc(appointmentId).get();

      final updateData = {
        'status': 'completed',
        'updatedAt': Timestamp.now(),
      };

      // Add optional fields only if provided
      if (prescription != null) updateData['prescription'] = prescription;
      if (diagnosis != null) updateData['diagnosis'] = diagnosis;
      if (followUpDate != null) updateData['followUpDate'] = followUpDate;

      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update(updateData);

      // Notify locally
      try {
        final appt = doc.exists ? Appointment.fromFirestore(doc) : null;
        if (appt != null) {
          await PushNotificationService.instance.showLocalNotification(
            title: 'অ্যাপয়েন্টমেন্ট সম্পন্ন',
            body:
                'Dr. ${appt.doctorName} এর সাথে ${appt.appointmentDate.toLocal()} অ্যাপয়েন্টমেন্ট সম্পন্ন হয়েছে। প্রেসক্রিপশন দেখুন।',
            payload: {
              'type': 'appointment',
              'appointmentId': appointmentId,
              'doctorId': appt.doctorId,
            },
          );
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to complete appointment: $e');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      final doc =
          await _firestore.collection('appointments').doc(appointmentId).get();
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      // Generic local notification for status change
      try {
        final appt = doc.exists ? Appointment.fromFirestore(doc) : null;
        if (appt != null) {
          String title = 'Appointment update';
          String body = 'Status changed to $status.';
          switch (status) {
            case 'confirmed':
              title = 'অ্যাপয়েন্টমেন্ট নিশ্চিত';
              body =
                  'Dr. ${appt.doctorName} এর সাথে ${appt.appointmentDate.toLocal()} অ্যাপয়েন্টমেন্টটি নিশ্চিত হয়েছে।';
              break;
            case 'cancelled':
              title = 'অ্যাপয়েন্টমেন্ট বাতিল';
              body =
                  'আপনার Dr. ${appt.doctorName} এর সাথে ${appt.appointmentDate.toLocal()} অ্যাপয়েন্টমেন্ট বাতিল হয়েছে।';
              break;
            case 'completed':
              title = 'অ্যাপয়েন্টমেন্ট সম্পন্ন';
              body =
                  'Dr. ${appt.doctorName} এর সাথে অ্যাপয়েন্টমেন্ট সম্পন্ন হয়েছে।';
              break;
            default:
              title = 'অ্যাপয়েন্টমেন্ট আপডেট';
              body = 'স্ট্যাটাস পরিবর্তন: $status';
          }
          await PushNotificationService.instance.showLocalNotification(
            title: title,
            body: body,
            payload: {
              'type': 'appointment',
              'appointmentId': appointmentId,
              'doctorId': appt.doctorId,
            },
          );
          // Write in-app notification to patient
          if (status == 'confirmed' ||
              status == 'completed' ||
              status == 'cancelled') {
            await NotificationWriter.write(
              userId: appt.patientId,
              title: title,
              body: body,
              type: 'appointment',
              payload: {'appointmentId': appointmentId},
            );
          }
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Update appointment notes
  Future<void> updateAppointmentNotes(
      String appointmentId, String notes) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'notes': notes,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update appointment notes: $e');
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String appointmentId, bool isPaid) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'isPaid': isPaid,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Get appointment by ID
  Future<Appointment?> getAppointmentById(String appointmentId) async {
    try {
      final doc =
          await _firestore.collection('appointments').doc(appointmentId).get();

      if (doc.exists) {
        return Appointment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch appointment: $e');
    }
  }

  // Get appointments by status
  Future<List<Appointment>> getAppointmentsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('status', isEqualTo: status)
          .orderBy('appointmentDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch appointments by status: $e');
    }
  }

  // Get today's appointments for a patient
  Future<List<Appointment>> getTodaysAppointments(String patientId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('appointmentDate')
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch today\'s appointments: $e');
    }
  }

  // Get upcoming appointments for a patient
  Future<List<Appointment>> getUpcomingAppointments(String patientId) async {
    try {
      final now = DateTime.now();

      final snapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('appointmentDate', isGreaterThan: Timestamp.fromDate(now))
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('appointmentDate')
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming appointments: $e');
    }
  }

  // Get appointments for a specific doctor
  Future<List<Appointment>> getAppointmentsForDoctor(String doctorId) async {
    try {
      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('appointmentDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch doctor appointments: $e');
    }
  }

  // Get today's appointments for a doctor
  Future<List<Appointment>> getTodaysAppointmentsForDoctor(
      String doctorId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('appointmentDate')
          .get();

      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch today\'s appointments for doctor: $e');
    }
  }

  // Stream for real-time appointment updates for patient
  Stream<List<Appointment>> getAppointmentsStream(String patientId) {
    return _firestore
        .collection('appointments')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
      list.sort(
          (a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return list;
    });
  }

  // Stream for real-time appointment updates for doctor
  Stream<List<Appointment>> getDoctorAppointmentsStream(String doctorId) {
    if (doctorId.trim().isEmpty) {
      return Stream.value(const <Appointment>[]);
    }
    // Client-side sort avoids needing a composite Firestore index on
    // doctorId + appointmentDate (which causes silent empty results when absent).
    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
      list.sort(
          (a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return list;
    });
  }

  // Stream for admin to monitor all appointments
  Stream<List<Appointment>> getAllAppointmentsStream() {
    return _firestore
        .collection('appointments')
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
  }

  // Stream appointments by status for admin
  Stream<List<Appointment>> getAppointmentsByStatusStream(String status) {
    return _firestore
        .collection('appointments')
        .where('status', isEqualTo: status)
        .orderBy('appointmentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Appointment.fromFirestore(doc))
            .toList());
  }

  // Delete appointment (use with caution)
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }

  // Restore a previously deleted appointment document.
  // Note: This does NOT recreate slot guards. Intended for restoring
  // cancelled/completed records used for history. Use cautiously.
  Future<void> restoreAppointment(Appointment appointment) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointment.id)
          .set(appointment.toMap());
    } catch (e) {
      throw Exception('Failed to restore appointment: $e');
    }
  }

  // Reschedule appointment
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    try {
      // Run transaction to atomically move the lock and update the appointment
      final now = DateTime.now();
      await _firestore.runTransaction((transaction) async {
        final apptRef =
            _firestore.collection('appointments').doc(appointmentId);
        final apptSnap = await transaction.get(apptRef);
        if (!apptSnap.exists) {
          throw Exception('Appointment not found');
        }
        final appt = Appointment.fromFirestore(apptSnap);

        final oldGuardRef = _firestore
            .collection('slot_guards')
            .doc(_slotKey(appt.doctorId, appt.appointmentDate));
        final newGuardId = _slotKey(appt.doctorId, newDate);
        final newGuardRef =
            _firestore.collection('slot_guards').doc(newGuardId);

        final oldPGuardRef = _firestore
            .collection('patient_slot_guards')
            .doc(_patientSlotKey(appt.patientId, appt.appointmentDate));
        final newPGuardId = _patientSlotKey(appt.patientId, newDate);
        final newPGuardRef =
            _firestore.collection('patient_slot_guards').doc(newPGuardId);

        // Ensure new slot not already locked/booked (doctor + patient)
        final newGuardSnap = await transaction.get(newGuardRef);
        if (newGuardSnap.exists) {
          throw Exception(
              'এই সময়টি ইতিমধ্যে বুক করা হয়েছে। অন্য একটি সময় নির্বাচন করুন।');
        }
        final newPGuardSnap = await transaction.get(newPGuardRef);
        if (newPGuardSnap.exists) {
          throw Exception(
              'এই সময়টি ইতিমধ্যে বুক করা হয়েছে। অন্য একটি সময় নির্বাচন করুন।');
        }

        // Create new guards, update appointment, delete old guards
        transaction.set(newGuardRef, {
          'appointmentId': appointmentId,
          'doctorId': appt.doctorId,
          'appointmentDate': Timestamp.fromDate(newDate),
          'createdAt': Timestamp.fromDate(now),
          'status': 'locked',
        });
        transaction.set(newPGuardRef, {
          'appointmentId': appointmentId,
          'patientId': appt.patientId,
          'appointmentDate': Timestamp.fromDate(newDate),
          'createdAt': Timestamp.fromDate(now),
          'status': 'locked',
        });

        transaction.update(apptRef, {
          'appointmentDate': Timestamp.fromDate(newDate),
          'timeSlot': newTimeSlot,
          'status': 'pending',
          'updatedAt': Timestamp.fromDate(now),
        });

        // Delete old guards if they exist
        final oldGuardSnap = await transaction.get(oldGuardRef);
        if (oldGuardSnap.exists) {
          transaction.delete(oldGuardRef);
        }
        final oldPGuardSnap = await transaction.get(oldPGuardRef);
        if (oldPGuardSnap.exists) {
          transaction.delete(oldPGuardRef);
        }
      });

      // Notify locally about reschedule (best-effort, outside transaction)
      try {
        final doc = await _firestore
            .collection('appointments')
            .doc(appointmentId)
            .get();
        final appt = doc.exists ? Appointment.fromFirestore(doc) : null;
        if (appt != null) {
          await PushNotificationService.instance.showLocalNotification(
            title: 'অ্যাপয়েন্টমেন্ট সময় পরিবর্তন',
            body:
                'Dr. ${appt.doctorName} এর সাথে অ্যাপয়েন্টমেন্ট পুনঃনির্ধারিত হয়েছে এবং নিশ্চিতকরণের জন্য অপেক্ষমাণ।',
            payload: {
              'type': 'appointment',
              'appointmentId': appointmentId,
              'doctorId': appt.doctorId,
            },
          );
        }
      } catch (_) {}
    } catch (e) {
      throw Exception('Failed to reschedule appointment: $e');
    }
  }

  // Search appointments by patient name (for admin)
  Future<List<Appointment>> searchAppointmentsByPatientName(
      String patientName) async {
    try {
      // Convert to lowercase for case-insensitive search
      final searchTerm = patientName.toLowerCase();

      final snapshot = await _firestore
          .collection('appointments')
          .orderBy('patientName')
          .get();

      // Filter locally for partial matching
      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .where((appointment) =>
              appointment.patientName.toLowerCase().contains(searchTerm))
          .toList();
    } catch (e) {
      throw Exception('Failed to search appointments: $e');
    }
  }

  // Update multiple appointment fields
  Future<void> updateAppointment({
    required String appointmentId,
    DateTime? appointmentDate,
    String? timeSlot,
    String? status,
    String? notes,
    String? prescription,
    String? diagnosis,
    String? followUpDate,
    bool? isPaid,
    double? consultationFee,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      // Add only the fields that are provided
      if (appointmentDate != null) {
        updateData['appointmentDate'] = Timestamp.fromDate(appointmentDate);
      }
      if (timeSlot != null) updateData['timeSlot'] = timeSlot;
      if (status != null) updateData['status'] = status;
      if (notes != null) updateData['notes'] = notes;
      if (prescription != null) updateData['prescription'] = prescription;
      if (diagnosis != null) updateData['diagnosis'] = diagnosis;
      if (followUpDate != null) updateData['followUpDate'] = followUpDate;
      if (isPaid != null) updateData['isPaid'] = isPaid;
      if (consultationFee != null) {
        updateData['consultationFee'] = consultationFee;
      }

      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  // Get appointments within date range
  Future<List<Appointment>> getAppointmentsInDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? doctorId,
    String? patientId,
  }) async {
    try {
      Query query = _firestore
          .collection('appointments')
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('appointmentDate');

      // Add optional filters
      if (doctorId != null) {
        query = query.where('doctorId', isEqualTo: doctorId);
      }
      if (patientId != null) {
        query = query.where('patientId', isEqualTo: patientId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch appointments in date range: $e');
    }
  }
}
