// ignore_for_file: unused_local_variable, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/appointment_provider.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/models/appointment_model.dart';
import 'package:medicore/services/appointment_service.dart';
import 'package:medicore/services/review_service.dart';
import 'package:medicore/config/routes.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:medicore/widgets/patient/appointment_card.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  bool _selectionMode = false;
  final Set<String> _selected = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id ?? authProvider.currentUserId;
      if (userId != null) {
        appointmentProvider.loadUserAppointments(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final apptService = AppointmentService();
    return Scaffold(
      appBar: AppBar(
        leading: _selectionMode
            ? IconButton(
                tooltip: 'Clear selection',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _selectionMode = false;
                  _selected.clear();
                }),
              )
            : null,
        title: _selectionMode
            ? Text('${_selected.length} selected')
            : const Text('আমার অ্যাপয়েন্টমেন্ট / My Appointments'),
        actions: [
          if (_selectionMode)
            IconButton(
              tooltip: 'Select all',
              icon: const Icon(Icons.select_all),
              onPressed: () {
                final items = context.read<AppointmentProvider>().appointments;
                setState(() {
                  if (_selected.length == items.length && items.isNotEmpty) {
                    _selected.clear();
                    _selectionMode = false;
                  } else {
                    _selectionMode = true;
                    _selected
                      ..clear()
                      ..addAll(items.map((e) => e.id));
                  }
                });
              },
            ),
          if (_selectionMode)
            IconButton(
              tooltip: 'Cancel selected',
              icon: const Icon(Icons.event_busy_outlined),
              onPressed: () async => _cancelSelected(context),
            ),
          if (_selectionMode)
            IconButton(
              tooltip: 'Delete selected',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async => _deleteSelected(context),
            ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer2<AuthProvider, AppointmentProvider>(
          builder: (context, authProvider, appointmentProvider, child) {
            final currentUserId =
                authProvider.currentUser?.id ?? authProvider.currentUserId;

            if (currentUserId == null) {
              return const Center(
                child: Text(
                    'দয়া করে লগইন করুন / Please login to view appointments'),
              );
            }

            if (authProvider.currentUser == null &&
                authProvider.currentFirebaseUser != null) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Google login detected. Loading your appointments... / Google login detected. Please wait.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Real-time stream so newly booked appointments appear instantly
            return StreamBuilder<List<Appointment>>(
              stream: apptService.getAppointmentsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                            'লোড করতে ব্যর্থ / Failed to load: ${snapshot.error}')
                      ],
                    ),
                  );
                }
                final appointments = snapshot.data ?? const <Appointment>[];
                if (appointments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'কোনো অ্যাপয়েন্টমেন্ট নেই / No Appointments',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                            'ডাক্তারের সাথে আপনার প্রথম অ্যাপয়েন্টমেন্ট বুক করুন / Book your first appointment'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final userId = authProvider.currentUser!.id;
                    final isSelected = _selected.contains(appointment.id);
                    return Dismissible(
                      key: ValueKey(appointment.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                      confirmDismiss: (direction) async {
                        final canDelete = appointment.status == 'cancelled' ||
                            appointment.status == 'completed';
                        if (!canDelete) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please cancel first before deleting / আগে বাতিল করুন তারপর ডিলিট করুন'),
                            ),
                          );
                          return false;
                        }
                        return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Appointment?'),
                                content: const Text(
                                    'This will permanently remove it. Are you sure?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('No'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) async {
                        final removed = appointment;
                        final ok = await appointmentProvider.deleteAppointment(
                            removed.id, userId);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Appointment deleted / অ্যাপয়েন্টমেন্ট ডিলিট হয়েছে'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () async {
                                  try {
                                    await AppointmentService()
                                        .restoreAppointment(removed);
                                    if (mounted) {
                                      await context
                                          .read<AppointmentProvider>()
                                          .loadUserAppointments(userId);
                                    }
                                  } catch (_) {}
                                },
                              ),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      },
                      child: GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _selectionMode = true;
                            _selected.add(appointment.id);
                          });
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Stack(
                          children: [
                            // Polished card UI
                            AppointmentCard(
                              appointment: appointment,
                              onTap: () {
                                if (_selectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      _selected.remove(appointment.id);
                                      if (_selected.isEmpty) {
                                        _selectionMode = false;
                                      }
                                    } else {
                                      _selected.add(appointment.id);
                                    }
                                  });
                                } else {
                                  Routes.goToAppointmentDetail(
                                      context, appointment.id);
                                }
                              },
                              showActions: appointment.status == 'pending' ||
                                  appointment.status == 'confirmed',
                              onCancel: (appointment.status == 'pending' ||
                                      appointment.status == 'confirmed')
                                  ? () => _cancelAppointment(appointment,
                                      context, appointmentProvider, userId)
                                  : null,
                              onReschedule: (appointment.status == 'pending' ||
                                      appointment.status == 'confirmed')
                                  ? () => _rescheduleAppointment(
                                      appointment, context)
                                  : null,
                            )
                                .animate()
                                .fadeIn(duration: 250.ms)
                                .slideY(begin: 0.05, end: 0),
                            // Selection toggle icon
                            Positioned(
                              right: 12,
                              top: 12,
                              child: AnimatedOpacity(
                                opacity: _selectionMode ? 1 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selected.remove(appointment.id);
                                        if (_selected.isEmpty) {
                                          _selectionMode = false;
                                        }
                                      } else {
                                        _selected.add(appointment.id);
                                      }
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.0),
                                      child: Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? const Color(0xFF10B981)
                                            : Colors.grey.shade400,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ), // Stack
                            // Rate Doctor button for completed appointments
                            if (appointment.isCompleted)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 12, left: 4, right: 4),
                                child: _RateDoctorButton(
                                  appointment: appointment,
                                  patientName: authProvider.currentUser?.name ??
                                      'Patient',
                                ),
                              ),
                          ], // Column children
                        ), // Column
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

  // Removed previous inline card builder in favor of AppointmentCard

  void _cancelAppointment(Appointment appointment, BuildContext context,
      AppointmentProvider appointmentProvider, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('অ্যাপয়েন্টমেন্ট বাতিল / Cancel Appointment'),
        content: const Text(
            'আপনি কি নিশ্চিত? / Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('না / No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await appointmentProvider.cancelAppointment(
                  appointment.id, userId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'অ্যাপয়েন্টমেন্ট বাতিল হয়েছে / Appointment cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('হ্যাঁ, বাতিল / Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(Appointment appointment, BuildContext context) {
    DateTime? pickedDate;
    String? pickedSlot;

    final timeSlots = <String>[
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM',
      '12:00 PM',
      '12:30 PM',
      '01:00 PM',
      '01:30 PM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM',
      '04:00 PM',
      '04:30 PM',
      '05:00 PM',
      '05:30 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'নতুন তারিখ ও সময় নির্বাচন করুন / Select new date & time',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  // Date Picker
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final now = DateTime.now();
                            final res = await showDatePicker(
                              context: context,
                              initialDate:
                                  appointment.appointmentDate.isAfter(now)
                                      ? appointment.appointmentDate
                                      : now.add(const Duration(days: 1)),
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 60)),
                            );
                            if (res != null) {
                              setState(() => pickedDate = res);
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            pickedDate == null
                                ? 'তারিখ নির্বাচন করুন / Pick date'
                                : DateFormat('EEE, MMM d, yyyy')
                                    .format(pickedDate!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Time Slots
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: timeSlots.map((slot) {
                      final selected = pickedSlot == slot;
                      return ChoiceChip(
                        label: Text(slot),
                        selected: selected,
                        onSelected: (_) => setState(() => pickedSlot = slot),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Reschedule'),
                      onPressed: () async {
                        if (pickedDate == null || pickedSlot == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'তারিখ ও সময় নির্বাচন করুন / Please select date and time')),
                          );
                          return;
                        }
                        // Combine pickedSlot into pickedDate
                        final parts = pickedSlot!.split(' ');
                        final hm = parts[0].split(':');
                        int hour = int.parse(hm[0]);
                        final minute = int.parse(hm[1]);
                        final isPM = parts[1].toUpperCase() == 'PM';
                        if (isPM && hour < 12) hour += 12;
                        if (!isPM && hour == 12) hour = 0;
                        final newDate = DateTime(pickedDate!.year,
                            pickedDate!.month, pickedDate!.day, hour, minute);

                        await AppointmentService().rescheduleAppointment(
                          appointmentId: appointment.id,
                          newDate: newDate,
                          newTimeSlot: pickedSlot!,
                        );
                        if (context.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Rescheduled successfully')),
                          );
                        }
                      },
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteSelected(BuildContext context) async {
    if (_selected.isEmpty) return;

    final appts = context.read<AppointmentProvider>().appointments;
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser!.id;

    final selectedAppts =
        appts.where((a) => _selected.contains(a.id)).toList(growable: false);
    final deletable = selectedAppts
        .where((a) => a.status == 'cancelled' || a.status == 'completed')
        .toList();
    final blocked = selectedAppts.length - deletable.length;

    if (deletable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Only cancelled/completed can be deleted / আগে বাতিল করুন')));
      return;
    }

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete selected appointments?'),
            content: Text(blocked > 0
                ? 'Deleting ${deletable.length}. Skipping $blocked not allowed.'
                : 'This will permanently remove ${deletable.length}.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    final provider = context.read<AppointmentProvider>();
    for (final a in deletable) {
      await provider.deleteAppointment(a.id, userId);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Deleted ${deletable.length}${blocked > 0 ? ' (skipped $blocked)' : ''}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              for (final a in deletable) {
                await AppointmentService().restoreAppointment(a);
              }
              if (mounted) {
                await context
                    .read<AppointmentProvider>()
                    .loadUserAppointments(userId);
              }
            } catch (_) {}
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );

    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }

  Future<void> _cancelSelected(BuildContext context) async {
    if (_selected.isEmpty) return;

    final appts = context.read<AppointmentProvider>().appointments;
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser!.id;

    final selectedAppts =
        appts.where((a) => _selected.contains(a.id)).toList(growable: false);
    final eligible = selectedAppts
        .where((a) => a.status == 'pending' || a.status == 'confirmed')
        .toList();
    final notEligible = selectedAppts.length - eligible.length;

    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Only pending/confirmed can be cancelled / কেবল pending/confirmed বাতিল করা যাবে')));
      return;
    }

    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancel selected appointments?'),
            content: Text(notEligible > 0
                ? 'Cancelling ${eligible.length}. Skipping $notEligible not eligible.'
                : 'This will cancel ${eligible.length} appointments.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirm) return;

    int success = 0;
    int failed = 0;
    final provider = context.read<AppointmentProvider>();
    for (final a in eligible) {
      final ok = await provider.cancelAppointment(a.id, userId);
      if (ok) {
        success++;
      } else {
        failed++;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Cancelled $success${failed > 0 ? ', failed $failed' : ''}${notEligible > 0 ? ', skipped $notEligible' : ''}'),
        duration: const Duration(seconds: 4),
      ),
    );

    setState(() {
      _selectionMode = false;
      _selected.clear();
    });
  }
}

// ─── Rate Doctor Button ───────────────────────────────────────────────────────

class _RateDoctorButton extends StatefulWidget {
  final Appointment appointment;
  final String patientName;

  const _RateDoctorButton({
    required this.appointment,
    required this.patientName,
  });

  @override
  State<_RateDoctorButton> createState() => _RateDoctorButtonState();
}

class _RateDoctorButtonState extends State<_RateDoctorButton> {
  bool _checked = false;
  bool _alreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final existing = await ReviewService.getExistingReview(
      patientId: widget.appointment.patientId,
      appointmentId: widget.appointment.id,
    );
    if (mounted) setState(() { _checked = true; _alreadyReviewed = existing != null; });
  }

  void _openReviewSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        appointment: widget.appointment,
        patientName: widget.patientName,
        onSubmitted: () => setState(() => _alreadyReviewed = true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const SizedBox.shrink();

    if (_alreadyReviewed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 6),
            Text('Review submitted',
                style: TextStyle(color: Colors.green.shade700, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openReviewSheet,
        icon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
        label: const Text('Rate Doctor'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF59E0B),
          side: const BorderSide(color: Color(0xFFF59E0B)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}

// ─── Review Bottom Sheet ──────────────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final Appointment appointment;
  final String patientName;
  final VoidCallback onSubmitted;

  const _ReviewSheet({
    required this.appointment,
    required this.patientName,
    required this.onSubmitted,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  double _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ReviewService.submitReview(
        doctorId: widget.appointment.doctorId,
        patientId: widget.appointment.patientId,
        patientName: widget.patientName,
        appointmentId: widget.appointment.id,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted! Thank you.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                width: 48, height: 5,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rate your experience',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Dr. ${widget.appointment.doctorName}',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            // Star row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = star.toDouble()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _ratingLabel(_rating),
              style: const TextStyle(
                  color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            VoiceTextField(
              controller: _commentCtrl,
              decoration: InputDecoration(
                hintText: 'Write your experience (optional)...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
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
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  String _ratingLabel(double r) {
    if (r >= 5) return 'Excellent!';
    if (r >= 4) return 'Very Good';
    if (r >= 3) return 'Good';
    if (r >= 2) return 'Fair';
    return 'Poor';
  }
}
