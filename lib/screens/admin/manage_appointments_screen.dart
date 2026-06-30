// lib/screens/admin/manage_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:medicore/widgets/admin/appointment_card_admin.dart';
import 'package:medicore/services/appointment_service.dart';
import 'package:medicore/models/appointment_model.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});

  @override
  State<ManageAppointmentsScreen> createState() =>
      _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  final _appointmentService = AppointmentService();
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Appointment>> get _activeStream {
    if (_selectedFilter == 'all') {
      return _appointmentService.getAllAppointmentsStream();
    }
    return _appointmentService.getAppointmentsByStatusStream(_selectedFilter);
  }

  void _handleFilterChange(String? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedFilter = newValue;
        _searchQuery = '';
        _searchController.clear();
      });
    }
  }

  List<Appointment> _filterBySearch(List<Appointment> appointments) {
    if (_searchQuery.isEmpty) return appointments;
    return appointments.where((a) {
      return a.patientName.toLowerCase().contains(_searchQuery) ||
          a.doctorName.toLowerCase().contains(_searchQuery) ||
          a.reason.toLowerCase().contains(_searchQuery) ||
          a.doctorSpecialty.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _updateStatus(Appointment appointment, String status) async {
    try {
      await _appointmentService.updateAppointmentStatus(
        appointmentId: appointment.id,
        status: status,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Appointment marked as $status'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<bool?> _confirm(String title, String body) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
  }

  void _handleViewDetails(Appointment a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Patient', a.patientName),
              _detailRow('Doctor', a.doctorName),
              _detailRow('Specialty', a.doctorSpecialty),
              _detailRow('Date', a.formattedDate),
              _detailRow('Time', a.formattedTime),
              _detailRow('Status', a.status.toUpperCase()),
              _detailRow('Reason', a.reason),
              _detailRow('Fee', '৳${a.consultationFee.toStringAsFixed(2)}'),
              _detailRow('Payment', a.isPaid ? 'Paid' : 'Unpaid'),
              if (a.notes?.isNotEmpty == true) _detailRow('Notes', a.notes!),
              if (a.diagnosis?.isNotEmpty == true)
                _detailRow('Diagnosis', a.diagnosis!),
              if (a.followUpDate?.isNotEmpty == true)
                _detailRow('Follow-up', a.followUpDate!),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 80,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Appointments'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchFilterSection(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (q) => setState(() => _searchQuery = q.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search by patient, doctor, or reason...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          }),
                    )
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Filter:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedFilter,
                  onChanged: _handleFilterChange,
                  items: const [
                    DropdownMenuItem(
                        value: 'all',
                        child: Row(children: [
                          Icon(Icons.all_inbox, size: 20),
                          SizedBox(width: 8),
                          Text('All Appointments'),
                        ])),
                    DropdownMenuItem(
                        value: 'pending',
                        child: Row(children: [
                          Icon(Icons.pending,
                              size: 20, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Pending'),
                        ])),
                    DropdownMenuItem(
                        value: 'confirmed',
                        child: Row(children: [
                          Icon(Icons.check_circle,
                              size: 20, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Confirmed'),
                        ])),
                    DropdownMenuItem(
                        value: 'completed',
                        child: Row(children: [
                          Icon(Icons.done_all,
                              size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Completed'),
                        ])),
                    DropdownMenuItem(
                        value: 'cancelled',
                        child: Row(children: [
                          Icon(Icons.cancel,
                              size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancelled'),
                        ])),
                  ],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return StreamBuilder<List<Appointment>>(
      stream: _activeStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        }

        final all = snapshot.data ?? [];
        final filtered = _filterBySearch(all);

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.search_off
                      : Icons.calendar_today,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No appointments found for "$_searchQuery"'
                      : 'No appointments found',
                  style: const TextStyle(
                      fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Showing ${filtered.length} of ${all.length} appointments — live',
                    style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final a = filtered[index];
                  return AppointmentCardAdmin(
                    patientName: a.patientName,
                    doctorName: a.doctorName,
                    date: a.formattedDate,
                    time: a.formattedTime,
                    status: a.status,
                    reason: a.reason,
                    consultationFee: a.consultationFee,
                    specialty: a.doctorSpecialty,
                    isPaid: a.isPaid,
                    onApprove: a.isPending
                        ? () async {
                            final ok = await _confirm(
                                'Confirm Appointment',
                                'Confirm appointment for ${a.patientName}?');
                            if (ok == true) _updateStatus(a, 'confirmed');
                          }
                        : null,
                    onCancel: () async {
                      final ok = await _confirm(
                          'Cancel Appointment',
                          'Cancel appointment for ${a.patientName}? This cannot be undone.');
                      if (ok == true) _updateStatus(a, 'cancelled');
                    },
                    onComplete: a.isConfirmed
                        ? () async {
                            final ok = await _confirm(
                                'Complete Appointment',
                                'Mark appointment for ${a.patientName} as completed?');
                            if (ok == true) _updateStatus(a, 'completed');
                          }
                        : null,
                    onViewDetails: () => _handleViewDetails(a),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
