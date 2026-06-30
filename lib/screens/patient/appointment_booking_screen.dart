// lib/screens/appointment_booking_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/services/appointment_service.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({super.key});

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  String? _selectedSlot;
  DateTime? _selectedDate;
  Map<String, dynamic>? _doctor;
  bool _isLoading = true;
  bool _submitting = false;
  String? _error;
  final AppointmentService _appointmentService = AppointmentService();
  Set<int> _bookedMinutes = <int>{};
  StreamSubscription<Set<int>>? _slotsSub;

  // Mock data for time slots
  final List<String> _timeSlots = [
    '09:00 AM',
    '09:30 AM',
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '02:30 PM',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _checkAuthAndRedirect();
    // Defer route argument access to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDoctorData();
    });
  }

  void _checkAuthAndRedirect() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('দয়া করে প্রথমে লগইন করুন / Please sign in first'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacementNamed(context, Routes.login);
      });
    }
  }

  Future<void> _loadDoctorData() async {
    try {
      final args = ModalRoute.of(context)?.settings.arguments;
      final doctorId = args is String
          ? args
          : (args is Map && args['doctorId'] is String
              ? args['doctorId'] as String
              : null);

      if (doctorId == null || doctorId.isEmpty) {
        setState(() {
          _error = 'No doctor selected.';
          _isLoading = false;
        });
        return;
      }

      final doctorDoc =
          await _firestore.collection('doctors').doc(doctorId).get();

      if (doctorDoc.exists) {
        setState(() {
          _doctor = {
            'id': doctorDoc.id,
            ...doctorDoc.data()!,
          };
          _isLoading = false;
        });
        _subscribeToSlots();
      } else {
        setState(() {
          _error = 'Doctor not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load doctor data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null; // Reset time slot when date changes
      });
      _subscribeToSlots();
    }
  }

  void _subscribeToSlots() {
    if (_doctor == null || _selectedDate == null) return;
    _slotsSub?.cancel();
    _slotsSub = _appointmentService
        .watchBookedSlotsForDoctorOnDate(
          doctorId: _doctor!['id'] as String,
          date: _selectedDate!,
        )
        .listen((set) {
      if (!mounted) return;
      setState(() {
        _bookedMinutes = set;
        _error = null;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load booked slots. Please try again.');
    });
  }

  @override
  void dispose() {
    _slotsSub?.cancel();
    super.dispose();
  }

  Widget _buildRecentHistory(BuildContext context) {
    final patientId =
        context.read<AuthProvider>().currentUser?.id ?? '';
    if (patientId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'completed')
          .orderBy('appointmentDate', descending: true)
          .limit(3)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final docs = snapshot.data!.docs;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            backgroundColor: Colors.white,
            collapsedBackgroundColor: Colors.white,
            leading: const Icon(Icons.history_rounded,
                color: Color(0xFF2563EB)),
            title: const Text('Your Recent Visits',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15)),
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['appointmentDate'];
              DateTime? date;
              if (ts is Timestamp) date = ts.toDate();
              return ListTile(
                dense: true,
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.check_rounded,
                      size: 16, color: Color(0xFF2563EB)),
                ),
                title: Text(data['doctorName'] ?? 'Doctor',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(
                  data['reason']?.toString().isNotEmpty == true
                      ? data['reason']
                      : 'No reason noted',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: date != null
                    ? Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11),
                      )
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  int _slotToMinutes(String slot) {
    final format = RegExp(r'^(\d+):(\d+)\s*(AM|PM)\b');
    final match = format.firstMatch(slot.trim());
    if (match == null) return -1;
    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!;
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDoctorData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_doctor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Appointment')),
        body: const Center(child: Text('Doctor data not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_doctor!['name'] ?? 'Doctor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Doctor Info Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: _doctor!['imageUrl'] != null
                          ? NetworkImage(_doctor!['imageUrl']!)
                          : null,
                      child: _doctor!['imageUrl'] == null
                          ? const Icon(Icons.person, size: 34)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _doctor!['name'] ?? 'Unknown Doctor',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _doctor!['specialty'] ?? 'General Practitioner',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((_doctor!['fee'] ??
                                  _doctor!['consultationFee']) !=
                              null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Fee: ৳${(_doctor!['fee'] ?? _doctor!['consultationFee']).toString()}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade800),
                            ),
                          ]
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // --- Recent History ---
              _buildRecentHistory(context),

              // --- Date Picker ---
              Text(
                'Select Date',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select a date',
                  ),
                  subtitle: _selectedDate != null
                      ? Text(
                          [
                            'Sun',
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat'
                          ][_selectedDate!.weekday % 7],
                          style: TextStyle(color: Colors.grey.shade600),
                        )
                      : null,
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Previous day',
                        onPressed: () async {
                          final prev = (_selectedDate ??
                                  DateTime.now().add(const Duration(days: 1)))
                              .subtract(const Duration(days: 1));
                          // Disallow past or today
                          final min =
                              DateTime.now().add(const Duration(days: 1));
                          if (prev.isBefore(
                              DateTime(min.year, min.month, min.day))) {
                            return;
                          }
                          setState(() {
                            _selectedDate = prev;
                            _selectedSlot = null;
                          });
                          _subscribeToSlots();
                        },
                        icon: const Icon(Icons.chevron_left),
                      ),
                      const VerticalDivider(width: 1),
                      IconButton(
                        tooltip: 'Pick date',
                        onPressed: _selectDate,
                        icon: const Icon(Icons.edit_calendar_outlined),
                      ),
                      const VerticalDivider(width: 1),
                      IconButton(
                        tooltip: 'Next day',
                        onPressed: () async {
                          final next = (_selectedDate ??
                                  DateTime.now().add(const Duration(days: 1)))
                              .add(const Duration(days: 1));
                          setState(() {
                            _selectedDate = next;
                            _selectedSlot = null;
                          });
                          _subscribeToSlots();
                        },
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Time Slot Picker ---
              Text(
                'Select Time Slot',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              // Legend
              Row(
                children: [
                  Chip(
                    label: const Text('Available'),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Booked'),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_selectedDate == null)
                const Text('Please select a date first')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Morning',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _timeSlots
                          .where((s) => _slotToMinutes(s) < 12 * 60)
                          .map((slot) => _buildSlotChip(slot))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Text('Afternoon',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _timeSlots
                          .where((s) => _slotToMinutes(s) >= 12 * 60)
                          .map((slot) => _buildSlotChip(slot))
                          .toList(),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed:
              _selectedSlot == null || _selectedDate == null || _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        // Final re-check just before navigating (best-effort UI guard)
                        _subscribeToSlots();
                        if (!mounted) return;
                        final minutes = _slotToMinutes(_selectedSlot!);
                        if (_bookedMinutes.contains(minutes)) {
                          messenger.showSnackBar(const SnackBar(
                              content: Text(
                                  'This slot was just booked. Pick another.')));
                          return;
                        }

                        navigator.pushNamed(
                          Routes.appointmentForm,
                          arguments: {
                            'doctorId': _doctor!['id'],
                            'doctorName': _doctor!['name'],
                            'doctorSpecialty': _doctor!['specialty'],
                            'slot': _selectedSlot,
                            'date': _selectedDate,
                            'consultationFee': (_doctor!['fee'] ?? _doctor!['consultationFee'] ?? 0).toDouble(),
                          },
                        );
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
          child: _submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Book Now'),
        ),
      ),
    );
  }

  Widget _buildSlotChip(String slot) {
    final minutes = _slotToMinutes(slot);
    final isBooked = minutes >= 0 && _bookedMinutes.contains(minutes);
    final isSelected = !isBooked && _selectedSlot == slot;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBooked) ...[
            Icon(Icons.lock_clock, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
          ],
          Text(slot),
        ],
      ),
      selected: isSelected,
      onSelected: isBooked
          ? null
          : (selected) {
              setState(() {
                _selectedSlot = selected ? slot : null;
              });
            },
      selectedColor: Colors.blue.shade100,
      backgroundColor: isBooked ? Colors.grey.shade200 : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isBooked
            ? Colors.grey.shade600
            : (isSelected ? Colors.blue.shade700 : Colors.grey.shade700),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isBooked
              ? Colors.grey.shade300
              : (isSelected ? Colors.blue.shade300 : Colors.grey.shade300),
        ),
      ),
    );
  }
}
