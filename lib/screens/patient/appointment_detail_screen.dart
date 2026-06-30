// lib/screens/patient/appointment_detail_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/appointment_model.dart';
import 'package:medicore/services/appointment_service.dart';
import 'package:medicore/services/review_service.dart';
import 'package:medicore/config/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  late String _appointmentId;
  Appointment? _appointment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Delay until after first frame so ModalRoute.of(context) is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointmentData();
    });
  }

  Future<void> _loadAppointmentData() async {
    try {
      final arguments = ModalRoute.of(context)!.settings.arguments;

      if (arguments is String) {
        _appointmentId = arguments;
      } else if (arguments is Map<String, dynamic>) {
        _appointmentId = arguments['appointmentId'];
      } else {
        throw Exception('Invalid arguments passed to appointment detail');
      }

      final appointment =
          await _appointmentService.getAppointmentById(_appointmentId);

      if (appointment != null) {
        setState(() {
          _appointment = appointment;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Appointment not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load appointment details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment() async {
    try {
      await _appointmentService.cancelAppointment(_appointmentId);

      // Refresh the appointment data
      final updatedAppointment =
          await _appointmentService.getAppointmentById(_appointmentId);
      setState(() {
        _appointment = updatedAppointment;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rescheduleAppointment() async {
    // Navigate to booking screen with doctor details
    if (_appointment != null) {
      Navigator.pushNamed(
        context,
        Routes.appointmentBooking,
        arguments: _appointment!.doctorId,
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'confirmed' => Colors.green,
      'pending' => Colors.orange,
      'completed' => Colors.blue,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
  }

  Widget _buildDetailCard(String title, String value, {IconData? icon}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      side: BorderSide.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAppointmentData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_appointment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Appointment Details')),
        body: const Center(child: Text('Appointment not found')),
      );
    }

    final appointment = _appointment!;
    final bool isUpcoming = appointment.isUpcoming;
    final bool canCancel = isUpcoming && !appointment.isCancelled;
    final bool canReschedule = isUpcoming && !appointment.isCancelled;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        actions: [
          if (canReschedule)
            IconButton(
              icon: const Icon(Icons.schedule),
              onPressed: _rescheduleAppointment,
              tooltip: 'Reschedule',
            ),
          // Quick access for doctor to create a prescription
          if (FirebaseAuth.instance.currentUser?.uid == appointment.doctorId)
            IconButton(
              icon: const Icon(Icons.note_add_outlined),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.createPrescription,
                  arguments: {'patientId': appointment.patientId},
                );
              },
              tooltip: 'Create Prescription',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Section
              Card(
                color: _getStatusColor(appointment.status).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildStatusChip(appointment.status),
                      const Spacer(),
                      Text(
                        appointment.formattedFee,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Doctor Information
              const Text(
                'Doctor Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailCard(
                'Doctor Name',
                appointment.doctorName,
                icon: Icons.person,
              ),
              _buildDetailCard(
                'Specialty',
                appointment.doctorSpecialty,
                icon: Icons.medical_services,
              ),

              const SizedBox(height: 16),

              // Appointment Details
              const Text(
                'Appointment Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailCard(
                'Date',
                _formatDate(appointment.appointmentDate),
                icon: Icons.calendar_today,
              ),
              _buildDetailCard(
                'Time',
                '${appointment.timeSlot} (${_formatTime(appointment.appointmentDate)})',
                icon: Icons.access_time,
              ),
              _buildDetailCard(
                'Duration',
                '30 minutes',
                icon: Icons.timer,
              ),

              const SizedBox(height: 16),

              // Medical Information
              const Text(
                'Medical Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailCard(
                'Reason for Visit',
                appointment.reason,
                icon: Icons.medical_information,
              ),

              if (appointment.notes != null &&
                  appointment.notes!.isNotEmpty) ...[
                _buildDetailCard(
                  'Doctor Notes',
                  appointment.notes!,
                  icon: Icons.note,
                ),
              ],

              if (appointment.diagnosis != null &&
                  appointment.diagnosis!.isNotEmpty) ...[
                _buildDetailCard(
                  'Diagnosis',
                  appointment.diagnosis!,
                  icon: Icons.healing,
                ),
              ],

              if (appointment.prescription != null &&
                  appointment.prescription!.isNotEmpty) ...[
                _buildDetailCard(
                  'Prescription',
                  appointment.prescription!,
                  icon: Icons.medication,
                ),
              ],

              if (appointment.followUpDate != null &&
                  appointment.followUpDate!.isNotEmpty) ...[
                _buildDetailCard(
                  'Follow-up Date',
                  appointment.followUpDate!,
                  icon: Icons.update,
                ),
              ],

              // Payment Status
              _buildDetailCard(
                'Payment Status',
                appointment.isPaid ? 'Paid' : 'Pending',
                icon:
                    appointment.isPaid ? Icons.payment : Icons.pending_actions,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rate Doctor button for completed appointments
              if (appointment.isCompleted &&
                  FirebaseAuth.instance.currentUser?.uid ==
                      appointment.patientId) ...[
                _DetailRateButton(appointment: appointment),
                const SizedBox(height: 8),
              ],
              if (canCancel)
                Row(
                  children: [
                    if (canReschedule)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rescheduleAppointment,
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.blue.shade300),
                          ),
                          child: const Text('Reschedule'),
                        ),
                      ),
                    if (canReschedule) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _showCancelConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancel Appointment',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Appointment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelAppointment();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
  }
}

// ─── Rate Doctor button for detail screen ────────────────────────────────────

class _DetailRateButton extends StatefulWidget {
  final Appointment appointment;
  const _DetailRateButton({required this.appointment});

  @override
  State<_DetailRateButton> createState() => _DetailRateButtonState();
}

class _DetailRateButtonState extends State<_DetailRateButton> {
  bool _checked = false;
  bool _reviewed = false;

  @override
  void initState() {
    super.initState();
    ReviewService.getExistingReview(
      patientId: widget.appointment.patientId,
      appointmentId: widget.appointment.id,
    ).then((r) {
      if (mounted) setState(() { _checked = true; _reviewed = r != null; });
    });
  }

  void _open() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewBottomSheet(
        appointment: widget.appointment,
        onSubmitted: () => setState(() => _reviewed = true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const SizedBox.shrink();
    if (_reviewed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded,
                color: Colors.green.shade600, size: 18),
            const SizedBox(width: 8),
            Text('Review submitted',
                style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _open,
        icon: const Icon(Icons.star_rounded, color: Colors.white),
        label: const Text('Rate Doctor'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF59E0B),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ─── Shared review bottom sheet ───────────────────────────────────────────────

class _ReviewBottomSheet extends StatefulWidget {
  final Appointment appointment;
  final VoidCallback onSubmitted;
  const _ReviewBottomSheet(
      {required this.appointment, required this.onSubmitted});

  @override
  State<_ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<_ReviewBottomSheet> {
  double _rating = 5;
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await ReviewService.submitReview(
        doctorId: widget.appointment.doctorId,
        patientId: widget.appointment.patientId,
        patientName: user?.displayName ?? 'Patient',
        appointmentId: widget.appointment.id,
        rating: _rating,
        comment: _ctrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Review submitted! Thank you.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rate your experience',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Dr. ${widget.appointment.doctorName}',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _rating = star.toDouble()),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _rating >= 5
                  ? 'Excellent!'
                  : _rating >= 4
                      ? 'Very Good'
                      : _rating >= 3
                          ? 'Good'
                          : _rating >= 2
                              ? 'Fair'
                              : 'Poor',
              style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            VoiceTextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Write your experience (optional)...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.grey.shade200),
                ),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _submit,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
