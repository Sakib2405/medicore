import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/models/appointment_model.dart';
import 'package:medicore/models/doctor_model.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/services/appointment_service.dart';
import 'package:medicore/services/doctor_service.dart';
import 'package:medicore/services/prescription_service.dart';
import 'package:medicore/screens/prescriptions/prescription_pdf_viewer.dart';
import 'package:medicore/widgets/image_upload_dialog.dart';
import 'package:medicore/models/prescription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final DoctorService _doctorService = DoctorService();
  final TextEditingController _patientSearchController =
      TextEditingController();

  String _patientSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _patientSearchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _patientSearchQuery =
            _patientSearchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final currentUser = authProvider.currentUser;
      if (!mounted) return;
      if (currentUser?.isDoctor == true && !currentUser!.isUserVerified) {
        Navigator.pushReplacementNamed(
          context,
          Routes.doctorApprovalPending,
        );
      }
    });
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    super.dispose();
  }

  void _showAppointmentListSheet(
    BuildContext context, {
    required String title,
    required List<Appointment> appointments,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${appointments.length}',
                          style: const TextStyle(
                              color: Color(0xFF667eea),
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: appointments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No appointments',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: appointments.length,
                        itemBuilder: (_, i) {
                          final a = appointments[i];
                          final date = DateFormat('d MMM, EEE')
                              .format(a.appointmentDate);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(a.status)
                                  .withValues(alpha: 0.12),
                              child: Icon(Icons.person_rounded,
                                  color: _statusColor(a.status), size: 20),
                            ),
                            title: Text(
                              a.patientName.isNotEmpty
                                  ? a.patientName
                                  : 'Patient',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            subtitle: Text(
                              '$date  ·  ${a.formattedTime}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(a.status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                a.status,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _statusColor(a.status),
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _openAppointmentActions(a);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, Routes.login, (route) => false);
  }

  Future<void> _updateDoctorProfilePhoto(String newImageUrl) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final doctorId = _doctorId(authProvider);
      
      if (doctorId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor account not ready yet'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Update in Firestore doctors collection
      await _doctorService.updateDoctor(
        Doctor(
          uid: doctorId,
          name: authProvider.currentUser?.name ?? '',
          email: authProvider.currentUser?.email ?? '',
          specialty: '',
          imageUrl: newImageUrl,
          isAvailable: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      // Also update in users collection
      await authProvider.updateProfile({
        'displayPhoto': newImageUrl,
        'profileImage': newImageUrl,
        'photoUrl': newImageUrl,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPhotoUploadDialog(String? currentImageUrl) async {
    await ImageUploadDialogExtensions.showProfilePictureUpload(
      context: context,
      title: 'Update Profile Photo',
      currentImageUrl: currentImageUrl,
      onImageSelected: (imageUrl) {
        if (imageUrl.isNotEmpty) {
          _updateDoctorProfilePhoto(imageUrl);
        }
      },
    );
  }

  String _doctorId(AuthProvider authProvider) {
    final currentUser = authProvider.currentUser;
    if (currentUser?.id.isNotEmpty == true) {
      return currentUser!.id;
    }
    return authProvider.currentUserId ?? '';
  }

  Doctor _fallbackDoctorFromUser(AuthProvider authProvider) {
    final user = authProvider.currentUser!;
    return Doctor(
      uid: user.id,
      name: user.name,
      email: user.email,
      specialty: user.specialization ?? 'General Practitioner',
      phone: user.phone.isNotEmpty ? user.phone : null,
      experienceYears: user.experienceYears,
      clinicName: user.clinicName,
      clinicAddress: user.clinicAddress,
      bio: user.professionalInfo?['bio']?.toString(),
      imageUrl: user.displayPhoto.isNotEmpty ? user.displayPhoto : null,
      isAvailable: user.isActive,
      rating: user.rating ?? 0.0,
      totalRatings: user.reviewCount ?? 0,
      consultationFee: user.consultationFee,
      languages: const ['English'],
      education: const [],
      certifications: const [],
      services: const [],
      appointmentDuration: 30,
      isVerified: user.isUserVerified,
      isPremium: false,
      createdAt: user.createdAt ?? DateTime.now(),
      updatedAt: user.updatedAt ?? DateTime.now(),
      licenseNumber: user.licenseNumber,
    );
  }

  bool _needsProfileSetup(Doctor doctor) {
    return doctor.specialty.trim().isEmpty ||
        doctor.licenseNumber == null ||
        doctor.licenseNumber!.trim().isEmpty ||
        doctor.consultationFee == null ||
        (doctor.clinicName?.trim().isEmpty ?? true);
  }

  bool _matchesPatientSearch(Appointment appointment) {
    if (_patientSearchQuery.isEmpty) {
      return true;
    }

    final haystack = [
      appointment.patientName,
      appointment.patientId,
      appointment.reason,
      appointment.status,
    ].join(' ').toLowerCase();

    return haystack.contains(_patientSearchQuery);
  }

  Future<void> _openQuickPrescriptionSheet({String? patientId}) async {
    final patientController = TextEditingController(text: patientId ?? '');
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final medicineRows = <_MedicineRow>[_MedicineRow()];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: SafeArea(
                  top: false,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Quick Prescription',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fill the patient ID, add medicines, and upload instantly.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: patientController,
                            decoration: const InputDecoration(
                              labelText: 'Patient ID',
                              hintText: 'Enter patient document id',
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Patient ID is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Medicines',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setSheetState(() {
                                    medicineRows.add(_MedicineRow());
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add medicine'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...medicineRows.asMap().entries.map((entry) {
                            final index = entry.key;
                            final row = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: row.nameController,
                                            decoration: const InputDecoration(
                                              labelText: 'Medicine name',
                                              hintText: 'Napa 500',
                                            ),
                                            validator: (value) {
                                              if ((value ?? '')
                                                  .trim()
                                                  .isEmpty) {
                                                return 'Medicine name is required';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        if (medicineRows.length > 1) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: 'Remove medicine',
                                            onPressed: () {
                                              setSheetState(() {
                                                row.dispose();
                                                medicineRows.removeAt(index);
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: row.dosageController,
                                            decoration: const InputDecoration(
                                              labelText: 'Dosage',
                                              hintText: '1-0-1',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextFormField(
                                            controller: row.durationController,
                                            decoration: const InputDecoration(
                                              labelText: 'Duration',
                                              hintText: '3 days',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                          VoiceTextField(
                            controller: notesController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              hintText: 'Optional notes for the patient',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(sheetContext),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.cloud_upload_outlined),
                                  label: const Text('Upload'),
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }

                                    final authProvider =
                                        context.read<AuthProvider>();
                                    final doctorId = _doctorId(authProvider);
                                    final doctorName =
                                        authProvider.currentUser?.name ?? '';
                                    if (doctorId.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Doctor account not ready yet',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    final medicines = medicineRows
                                        .map((row) => {
                                              'name': row.nameController.text
                                                  .trim(),
                                              'dosage': row
                                                  .dosageController.text
                                                  .trim(),
                                              'duration': row
                                                  .durationController.text
                                                  .trim(),
                                            })
                                        .where((medicine) =>
                                            (medicine['name'] as String)
                                                .isNotEmpty)
                                        .toList();

                                    if (medicines.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Add at least one medicine'),
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.pop(sheetContext);

                                    // Generate preview data
                                    final prescription = Prescription(
                                      id: const Uuid().v4(),
                                      doctorId: doctorId,
                                      doctorName: doctorName,
                                      patientId:
                                          patientController.text.trim(),
                                      medicines: medicines,
                                      notes: notesController.text.trim(),
                                      createdAt: Timestamp.now(),
                                    );

                                    final nav = Navigator.of(context);
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    try {
                                      final previewBytes =
                                          await PrescriptionService
                                              .generatePdfBytes(prescription);
                                      if (!mounted) return;
                                      nav.push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PrescriptionPdfViewer(
                                            previewBytes: previewBytes,
                                            doctorId: doctorId,
                                            doctorName: doctorName,
                                            patientId: patientController.text
                                                .trim(),
                                            medicines: medicines,
                                            notes:
                                                notesController.text.trim(),
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Preview generation failed: $e'),
                                          backgroundColor:
                                              Colors.red.shade700,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAppointmentActions(Appointment appointment) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.of(sheetContext).padding.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  appointment.patientName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.reason.isNotEmpty
                      ? appointment.reason
                      : 'No reason provided',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label:
                      '${DateFormat('EEE, d MMM').format(appointment.appointmentDate)}  •  ${appointment.formattedTime}',
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: appointment.doctorSpecialty,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: appointment.consultationFee == 0
                      ? 'FREE (Waived by doctor)'
                      : appointment.formattedFee,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (appointment.isPending)
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _appointmentService.updateAppointmentStatus(
                            appointmentId: appointment.id,
                            status: 'confirmed',
                          );
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Confirm'),
                      ),
                    if (appointment.isConfirmed)
                      ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _appointmentService.updateAppointmentStatus(
                            appointmentId: appointment.id,
                            status: 'completed',
                          );
                        },
                        icon: const Icon(Icons.done_all),
                        label: const Text('Complete'),
                      ),
                    if (!appointment.isCancelled && !appointment.isCompleted)
                      OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _appointmentService.updateAppointmentStatus(
                            appointmentId: appointment.id,
                            status: 'cancelled',
                          );
                        },
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                    if (!appointment.isCancelled)
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _openQuickPrescriptionSheet(
                              patientId: appointment.patientId);
                        },
                        icon: const Icon(Icons.note_add_outlined),
                        label: const Text('Prescription'),
                      ),
                    if (!appointment.isCancelled)
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showFeeOverrideSheet(appointment);
                        },
                        icon: const Icon(Icons.discount_outlined),
                        label: const Text('Set Fee / Discount'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C3AED),
                          side: const BorderSide(color: Color(0xFFDDD6FE)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFeeOverrideSheet(Appointment appointment) {
    final originalFee = appointment.consultationFee;
    final customCtrl = TextEditingController(
      text: originalFee > 0 ? originalFee.toStringAsFixed(0) : '',
    );
    final noteCtrl = TextEditingController();
    double? previewFee = originalFee;
    bool isFree = originalFee == 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.discount_outlined,
                          color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Set Fee / Discount',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        Text(appointment.patientName,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Current fee display
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Current fee',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 13)),
                        Text(
                          originalFee == 0
                              ? 'FREE'
                              : '৳${originalFee.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Free treatment toggle
                  GestureDetector(
                    onTap: () {
                      setS(() {
                        isFree = !isFree;
                        if (isFree) {
                          previewFee = 0;
                          customCtrl.text = '0';
                        } else {
                          previewFee = null;
                          customCtrl.text = '';
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isFree
                            ? Colors.green.shade50
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isFree
                              ? Colors.green.shade300
                              : Colors.grey.shade200,
                          width: isFree ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          Icons.volunteer_activism_rounded,
                          color: isFree
                              ? Colors.green.shade600
                              : Colors.grey.shade500,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Free Treatment',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isFree
                                            ? Colors.green.shade700
                                            : Colors.black87)),
                                Text('Waive the consultation fee entirely',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                              ]),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFree
                                ? Colors.green.shade500
                                : Colors.grey.shade300,
                          ),
                          child: isFree
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 14)
                              : null,
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quick discount chips
                  if (!isFree) ...[
                    Text('Quick discount',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [10, 25, 50].map((pct) {
                        final discounted =
                            (originalFee * (1 - pct / 100));
                        return GestureDetector(
                          onTap: () {
                            setS(() {
                              previewFee = discounted;
                              customCtrl.text =
                                  discounted.toStringAsFixed(0);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color:
                                  (previewFee?.toStringAsFixed(0) ==
                                          discounted.toStringAsFixed(0))
                                      ? const Color(0xFF7C3AED)
                                          .withValues(alpha: 0.1)
                                      : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: (previewFee?.toStringAsFixed(0) ==
                                        discounted.toStringAsFixed(0))
                                    ? const Color(0xFF7C3AED)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              '$pct% off  →  ৳${discounted.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: (previewFee?.toStringAsFixed(0) ==
                                        discounted.toStringAsFixed(0))
                                    ? const Color(0xFF7C3AED)
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Custom fee input
                    TextFormField(
                      controller: customCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        setS(() => previewFee = parsed);
                      },
                      decoration: InputDecoration(
                        labelText: 'Custom fee (৳)',
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Note input
                  TextFormField(
                    controller: noteCtrl,
                    decoration: InputDecoration(
                      labelText: 'Reason / Note (optional)',
                      hintText: 'e.g., Senior citizen, charitable case…',
                      prefixIcon: const Icon(Icons.note_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preview + Apply button
                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('New fee',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12)),
                            Text(
                              isFree
                                  ? 'FREE'
                                  : previewFee != null
                                      ? '৳${previewFee!.toStringAsFixed(0)}'
                                      : '—',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: isFree
                                    ? Colors.green.shade600
                                    : const Color(0xFF7C3AED),
                              ),
                            ),
                          ]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: (isFree || previewFee != null)
                            ? () async {
                                final newFee =
                                    isFree ? 0.0 : previewFee!;
                                final note = noteCtrl.text.trim();
                                Navigator.pop(ctx);
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('appointments')
                                      .doc(appointment.id)
                                      .update({
                                    'consultationFee': newFee,
                                    if (note.isNotEmpty) 'feeNote': note,
                                    'originalConsultationFee': originalFee,
                                    'updatedAt':
                                        FieldValue.serverTimestamp(),
                                  });
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(newFee == 0
                                        ? 'Free treatment applied for ${appointment.patientName}'
                                        : 'Fee updated to ৳${newFee.toStringAsFixed(0)} for ${appointment.patientName}'),
                                    backgroundColor: Colors.green.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text('Failed to update fee: $e'),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            : null,
                        icon: Icon(isFree
                            ? Icons.volunteer_activism_rounded
                            : Icons.check_rounded),
                        label: Text(isFree ? 'Apply Free' : 'Apply Fee'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showPaymentHistorySheet(List<Appointment> appointments) {
    final sorted = [...appointments]
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded,
                          color: Color(0xFF7C3AED), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Payment History',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${sorted.length}',
                          style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: sorted.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No payment records',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 15)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: controller,
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final a = sorted[i];
                          final isFree = a.consultationFee == 0;
                          final dateStr = DateFormat('d MMM, EEE')
                              .format(a.appointmentDate);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isFree
                                    ? Colors.green.shade50
                                    : a.isPaid
                                        ? const Color(0xFF7C3AED)
                                            .withValues(alpha: 0.1)
                                        : Colors.orange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFree
                                    ? Icons.volunteer_activism_rounded
                                    : a.isPaid
                                        ? Icons.check_circle_rounded
                                        : Icons.hourglass_empty_rounded,
                                size: 18,
                                color: isFree
                                    ? Colors.green.shade600
                                    : a.isPaid
                                        ? const Color(0xFF7C3AED)
                                        : Colors.orange.shade700,
                              ),
                            ),
                            title: Text(
                              a.patientName.isNotEmpty
                                  ? a.patientName
                                  : 'Patient',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14),
                            ),
                            subtitle: Text(
                              '$dateStr  ·  ${a.status}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isFree
                                      ? 'FREE'
                                      : '৳${a.consultationFee.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: isFree
                                        ? Colors.green.shade600
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  a.isPaid ? 'Paid' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: a.isPaid
                                        ? Colors.green.shade600
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _openAppointmentActions(a);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          Consumer<AuthProvider>(
            builder: (_, auth, __) {
              final doctorId = _doctorId(auth);
              if (doctorId.isEmpty) return const SizedBox.shrink();
              return StreamBuilder<Doctor?>(
                stream: _doctorService.streamDoctorById(doctorId),
                builder: (_, snap) {
                  final isAvailable = snap.data?.isAvailable ?? true;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAvailable ? 'Available' : 'Away',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAvailable ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Switch(
                        value: isAvailable,
                        activeThumbColor: Colors.green,
                        onChanged: (val) async {
                          try {
                            await _doctorService.updateAvailability(
                                doctorId, val);
                          } catch (_) {}
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.pushNamed(context, Routes.notifications),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'New prescription',
            onPressed: () => _openQuickPrescriptionSheet(),
            icon: const Icon(Icons.note_add_outlined),
          ),
        ],
      ),
      drawer: _DoctorNavigationDrawer(onLogout: _logout),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuickPrescriptionSheet(),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Quick Rx'),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final currentUser = authProvider.currentUser;
            final doctorId = _doctorId(authProvider);

            if (currentUser == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!currentUser.isDoctor) {
              return _AccessDenied(
                onGoHome: () =>
                    Navigator.pushReplacementNamed(context, Routes.login),
              );
            }

            if (doctorId.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return StreamBuilder<Doctor?>(
              stream: _doctorService.streamDoctorById(doctorId),
              builder: (context, doctorSnapshot) {
                final doctor = doctorSnapshot.data ??
                    _fallbackDoctorFromUser(authProvider);

                return StreamBuilder<List<Appointment>>(
                  stream:
                      _appointmentService.getDoctorAppointmentsStream(doctorId),
                  builder: (context, appointmentSnapshot) {
                    final appointments =
                        appointmentSnapshot.data ?? const <Appointment>[];
                    final liveAppointments = appointments
                        .where((a) => !a.isCancelled)
                        .toList()
                      ..sort((a, b) =>
                          b.appointmentDate.compareTo(a.appointmentDate));

                    final todayAppointments = liveAppointments
                        .where((a) => a.isToday)
                        .where(_matchesPatientSearch)
                        .toList();

                    final pendingCount =
                        liveAppointments.where((a) => a.isPending).length;
                    final completedCount =
                        liveAppointments.where((a) => a.isCompleted).length;
                    final uniquePatients =
                        liveAppointments.map((a) => a.patientId).toSet().length;
                    final topPatients = <String, _PatientSummary>{};
                    for (final appointment in liveAppointments) {
                      final existing = topPatients[appointment.patientId];
                      if (existing == null) {
                        topPatients[appointment.patientId] = _PatientSummary(
                          id: appointment.patientId,
                          name: appointment.patientName,
                          lastVisit: appointment.createdAt,
                          visitCount: 1,
                          latestAppointment: appointment,
                        );
                      } else {
                        topPatients[appointment.patientId] = existing.copyWith(
                          visitCount: existing.visitCount + 1,
                          lastVisit:
                              appointment.createdAt.isAfter(existing.lastVisit)
                                  ? appointment.createdAt
                                  : existing.lastVisit,
                          latestAppointment:
                              appointment.createdAt.isAfter(existing.lastVisit)
                                  ? appointment
                                  : existing.latestAppointment,
                        );
                      }
                    }

                    final recentPatients = topPatients.values.toList()
                      ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));

                    final filteredRecentPatients =
                        recentPatients.where((patient) {
                      if (_patientSearchQuery.isEmpty) {
                        return true;
                      }
                      final haystack = [
                        patient.name,
                        patient.id,
                        patient.visitCount.toString(),
                        patient.latestAppointment?.reason ?? '',
                      ].join(' ').toLowerCase();
                      return haystack.contains(_patientSearchQuery);
                    }).toList();

                    // ── Payment stats ──────────────────────────────────────
                    final totalBilled = liveAppointments.fold<double>(
                        0, (s, a) => s + a.consultationFee);
                    final totalCollected = liveAppointments
                        .where((a) => a.isPaid)
                        .fold<double>(0, (s, a) => s + a.consultationFee);
                    final totalPending = liveAppointments
                        .where((a) =>
                            !a.isPaid &&
                            (a.isCompleted || a.isConfirmed))
                        .fold<double>(0, (s, a) => s + a.consultationFee);
                    final freeCount = liveAppointments
                        .where((a) => a.consultationFee == 0)
                        .length;

                    return RefreshIndicator(
                      onRefresh: () async => setState(() {}),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          _DoctorHeroCard(
                            doctor: doctor,
                            pendingCount: pendingCount,
                            completedCount: completedCount,
                            uniquePatients: uniquePatients,
                            activeAppointments: liveAppointments.length,
                            allAppointments: liveAppointments,
                            onPhotoTap: () => _showPhotoUploadDialog(doctor.imageUrl),
                            onTodayTap: () => _showAppointmentListSheet(
                              context,
                              title: "Today's Appointments",
                              appointments: liveAppointments.where((a) => a.isToday).toList(),
                            ),
                            onPendingTap: () => _showAppointmentListSheet(
                              context,
                              title: 'Pending Appointments',
                              appointments: liveAppointments.where((a) => a.isPending).toList(),
                            ),
                            onDoneTap: () => _showAppointmentListSheet(
                              context,
                              title: 'Completed Appointments',
                              appointments: liveAppointments.where((a) => a.isCompleted).toList(),
                            ),
                            onPatientsTap: () => _showAppointmentListSheet(
                              context,
                              title: 'All Patients',
                              appointments: liveAppointments,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // ── Payment Overview card ──────────────────────
                          _PaymentOverviewCard(
                            totalBilled: totalBilled,
                            totalCollected: totalCollected,
                            totalPending: totalPending,
                            freeCount: freeCount,
                            onViewAll: () => _showPaymentHistorySheet(
                                liveAppointments),
                          ),
                          const SizedBox(height: 16),
                          if (_needsProfileSetup(doctor))
                            _ReminderCard(
                              title: 'Complete doctor profile',
                              subtitle:
                                  'Add clinic name, fee, specialty, and license for a cleaner dashboard.',
                              onTap: () => Navigator.pushNamed(
                                  context, Routes.editProfile),
                            ),
                          if (_needsProfileSetup(doctor))
                            const SizedBox(height: 16),
                          _SectionHeader(
                            title: 'Quick Actions',
                            subtitle:
                                'Fast access to the most common doctor tasks.',
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _QuickActionCard(
                                icon: Icons.note_add_outlined,
                                title: 'Quick Rx',
                                subtitle: 'Create and upload prescription',
                                accent: const Color(0xFF0F766E),
                                onTap: () => _openQuickPrescriptionSheet(),
                              ),
                              _QuickActionCard(
                                icon: Icons.description_rounded,
                                title: 'My Rx',
                                subtitle: 'View uploaded prescriptions',
                                accent: const Color(0xFF667eea),
                                onTap: () => Navigator.pushNamed(
                                    context, Routes.doctorPrescriptions),
                              ),
                              _QuickActionCard(
                                icon: Icons.edit_outlined,
                                title: 'Edit Profile',
                                subtitle: 'Update clinic and fee details',
                                accent: const Color(0xFF2563EB),
                                onTap: () => Navigator.pushNamed(
                                    context, Routes.editProfile),
                              ),
                              _QuickActionCard(
                                icon: Icons.refresh_rounded,
                                title: 'Refresh',
                                subtitle: 'Reload live Firebase data',
                                accent: const Color(0xFF7C3AED),
                                onTap: () => setState(() {}),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: "Today's Patients",
                            subtitle:
                                'Search active patients by name, id, reason, or status.',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _patientSearchController,
                            decoration: InputDecoration(
                              hintText: 'Search today\'s patients',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_patientSearchQuery.isNotEmpty)
                                    IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: _patientSearchController.clear,
                                      icon: const Icon(Icons.clear),
                                    ),
                                  VoiceSuffixButton(
                                    controller: _patientSearchController,
                                    append: false,
                                  ),
                                ],
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (todayAppointments.isEmpty)
                            const _EmptyStateCard(
                              icon: Icons.calendar_today_outlined,
                              title: 'No matching patients today',
                              subtitle:
                                  'Try another search term or wait for new bookings.',
                            )
                          else
                            ...todayAppointments.take(8).map((appointment) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _AppointmentCard(
                                  appointment: appointment,
                                  onTap: () =>
                                      _openAppointmentActions(appointment),
                                  onPrescribe: () =>
                                      _openQuickPrescriptionSheet(
                                    patientId: appointment.patientId,
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: 'Live Appointments',
                            subtitle:
                                'Newest bookings and active patient visits appear here.',
                          ),
                          const SizedBox(height: 12),
                          if (liveAppointments.isEmpty)
                            const _EmptyStateCard(
                              icon: Icons.event_available_outlined,
                              title: 'No live appointments',
                              subtitle:
                                  'When a patient books, the appointment will show up here immediately.',
                            )
                          else
                            ...liveAppointments.take(8).map((appointment) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _AppointmentCard(
                                  appointment: appointment,
                                  onTap: () =>
                                      _openAppointmentActions(appointment),
                                ),
                              );
                            }),
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: 'Recent Patients',
                            subtitle:
                                'Quick view of patients you saw recently.',
                          ),
                          const SizedBox(height: 12),
                          if (filteredRecentPatients.isEmpty)
                            const _EmptyStateCard(
                              icon: Icons.person_search_outlined,
                              title: 'No patient history yet',
                              subtitle:
                                  'Booked appointments will build this list automatically.',
                            )
                          else
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: filteredRecentPatients
                                    .take(6)
                                    .map((patient) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: _PatientCard(
                                      patient: patient,
                                      onTap: () => _openQuickPrescriptionSheet(
                                        patientId: patient.id,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DoctorHeroCard extends StatelessWidget {
  final Doctor doctor;
  final int pendingCount;
  final int completedCount;
  final int uniquePatients;
  final int activeAppointments;
  final VoidCallback? onPhotoTap;
  final List<Appointment> allAppointments;
  final VoidCallback? onTodayTap;
  final VoidCallback? onPendingTap;
  final VoidCallback? onDoneTap;
  final VoidCallback? onPatientsTap;

  const _DoctorHeroCard({
    required this.doctor,
    required this.pendingCount,
    required this.completedCount,
    required this.uniquePatients,
    required this.activeAppointments,
    required this.allAppointments,
    this.onPhotoTap,
    this.onTodayTap,
    this.onPendingTap,
    this.onDoneTap,
    this.onPatientsTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM').format(now);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0369A1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.22),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with photo + info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile photo
                GestureDetector(
                  onTap: onPhotoTap,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3), width: 2),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: doctor.imageUrl != null &&
                            doctor.imageUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              doctor.imageUrl!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  doctor.name.isNotEmpty
                                      ? doctor.name[0].toUpperCase()
                                      : 'D',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              doctor.name.isNotEmpty
                                  ? doctor.name[0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${doctor.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        doctor.specialty,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dateStr,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Availability badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: doctor.isAvailable
                        ? Colors.green.withValues(alpha: 0.25)
                        : Colors.red.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: doctor.isAvailable
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.red.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: doctor.isAvailable
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        doctor.isAvailable ? 'Active' : 'Away',
                        style: TextStyle(
                          color: doctor.isAvailable
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Clinic info row
          if (doctor.clinicName?.isNotEmpty == true ||
              doctor.clinicAddress?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      color: Colors.white.withValues(alpha: 0.6), size: 14),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      [
                        if (doctor.clinicName?.isNotEmpty == true)
                          doctor.clinicName!,
                        if (doctor.clinicAddress?.isNotEmpty == true)
                          doctor.clinicAddress!,
                      ].join('  ·  '),
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

          // Metrics row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
            child: Row(
              children: [
                _HeroMetric(
                  label: 'Today',
                  value: '$activeAppointments',
                  icon: Icons.calendar_today_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  onTap: onTodayTap,
                ),
                _HeroMetric(
                  label: 'Pending',
                  value: '$pendingCount',
                  icon: Icons.hourglass_top_rounded,
                  iconColor: const Color(0xFFFBBF24),
                  onTap: onPendingTap,
                ),
                _HeroMetric(
                  label: 'Done',
                  value: '$completedCount',
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF4ADE80),
                  onTap: onDoneTap,
                ),
                _HeroMetric(
                  label: 'Patients',
                  value: '$uniquePatients',
                  icon: Icons.people_rounded,
                  iconColor: const Color(0xFFC084FC),
                  onTap: onPatientsTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _HeroMetric({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: onTap != null ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(icon, color: iconColor ?? Colors.white, size: 18),
            if (icon != null) const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: iconColor ?? Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, height: 1.4),
        ),
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ReminderCard(
      {required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.badge_outlined, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorNavigationDrawer extends StatelessWidget {
  final VoidCallback onLogout;

  const _DoctorNavigationDrawer({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.medical_services_outlined,
                        color: Colors.white),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Doctor Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Manage appointments, prescriptions, profile, and settings.',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DrawerTile(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerTile(
                    icon: Icons.note_add_outlined,
                    label: 'Quick Prescription',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).maybePop();
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.description_rounded,
                    label: 'My Prescriptions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                          context, Routes.doctorPrescriptions);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit Profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.editProfile);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.notifications);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    iconColor: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      onLogout();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: iconColor ?? const Color(0xFF334155)),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
      ),
    );
  }
}


class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accent.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(height: 14),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Colors.grey.shade600, height: 1.35, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onTap;
  final VoidCallback? onPrescribe;

  const _AppointmentCard({
    required this.appointment,
    required this.onTap,
    this.onPrescribe,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE0F2FE),
                child: Text(
                  appointment.patientName.isNotEmpty
                      ? appointment.patientName[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                      color: Color(0xFF0369A1), fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appointment.patientName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _AppointmentStatusPill(status: appointment.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appointment.reason.isNotEmpty
                          ? appointment.reason
                          : 'No reason provided',
                      style:
                          TextStyle(color: Colors.grey.shade700, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _TinyInfoChip(
                          icon: Icons.calendar_today_outlined,
                          label: DateFormat('EEE, d MMM')
                              .format(appointment.appointmentDate),
                        ),
                        _TinyInfoChip(
                          icon: Icons.access_time_outlined,
                          label: appointment.formattedTime,
                        ),
                        _TinyInfoChip(
                          icon: Icons.payments_outlined,
                          label: appointment.formattedFee,
                        ),
                      ],
                    ),
                    if (onPrescribe != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: onPrescribe,
                          icon: const Icon(Icons.note_add_outlined, size: 18),
                          label: const Text('Prescribe'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final _PatientSummary patient;
  final VoidCallback? onTap;

  const _PatientCard({required this.patient, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFE0F2FE),
                      child: Text(
                        patient.name.isNotEmpty
                            ? patient.name[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                            color: Color(0xFF0369A1),
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        patient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                    '${patient.visitCount} visit${patient.visitCount == 1 ? '' : 's'}'),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM, h:mm a').format(patient.lastVisit),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
                if (patient.latestAppointment != null) ...[
                  const SizedBox(height: 12),
                  _AppointmentStatusPill(
                      status: patient.latestAppointment!.status),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TinyInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AppointmentStatusPill extends StatelessWidget {
  final String status;

  const _AppointmentStatusPill({required this.status});

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade800)),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateCard(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.grey.shade500, size: 28),
          ),
          const SizedBox(height: 14),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _AccessDenied extends StatelessWidget {
  final VoidCallback onGoHome;

  const _AccessDenied({required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.red),
              const SizedBox(height: 14),
              const Text(
                'Doctor access required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'This screen is only available to doctor accounts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onGoHome,
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientSummary {
  final String id;
  final String name;
  final DateTime lastVisit;
  final int visitCount;
  final Appointment? latestAppointment;

  const _PatientSummary({
    required this.id,
    required this.name,
    required this.lastVisit,
    required this.visitCount,
    required this.latestAppointment,
  });

  _PatientSummary copyWith({
    String? id,
    String? name,
    DateTime? lastVisit,
    int? visitCount,
    Appointment? latestAppointment,
  }) {
    return _PatientSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      lastVisit: lastVisit ?? this.lastVisit,
      visitCount: visitCount ?? this.visitCount,
      latestAppointment: latestAppointment ?? this.latestAppointment,
    );
  }
}

class _MedicineRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    durationController.dispose();
  }
}

// ── Payment Overview Card ─────────────────────────────────────────────────────
class _PaymentOverviewCard extends StatelessWidget {
  final double totalBilled;
  final double totalCollected;
  final double totalPending;
  final int freeCount;
  final VoidCallback onViewAll;

  const _PaymentOverviewCard({
    required this.totalBilled,
    required this.totalCollected,
    required this.totalPending,
    required this.freeCount,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF9F67FA)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Payment & Earnings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onViewAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'History',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Total billed big number
            Text(
              '৳${totalBilled.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Total billed (all active appointments)',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 14),
            // Stats row
            Row(
              children: [
                _PayStat(
                  label: 'Collected',
                  value: '৳${totalCollected.toStringAsFixed(0)}',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF86EFAC),
                ),
                _PayStat(
                  label: 'Pending',
                  value: '৳${totalPending.toStringAsFixed(0)}',
                  icon: Icons.hourglass_empty_rounded,
                  color: const Color(0xFFFDE68A),
                ),
                _PayStat(
                  label: 'Free given',
                  value: '$freeCount appt${freeCount == 1 ? '' : 's'}',
                  icon: Icons.volunteer_activism_rounded,
                  color: const Color(0xFF93C5FD),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PayStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PayStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
