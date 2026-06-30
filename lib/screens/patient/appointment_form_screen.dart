// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/services/appointment_service.dart';
import 'package:medicore/services/payment_service.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';

class AppointmentFormScreen extends StatefulWidget {
  const AppointmentFormScreen({super.key});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reasonController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppointmentService _appointmentService = AppointmentService();
  final PaymentService _paymentSvc = PaymentService();

  bool _isLoading = false;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  Map<String, dynamic>? _bookingData;
  bool _didReadArgs = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      setState(() {
        _bookingData = Map<String, dynamic>.from(args);
      });
    }
  }

  void _loadUserData() {
    final user = _auth.currentUser;
    if (user != null) {
      _firestore.collection('users').doc(user.uid).get().then((doc) {
        if (doc.exists && mounted) {
          final data = doc.data()!;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
          });
        }
      });
    }
  }

  double get _consultationFee =>
      (_bookingData?['consultationFee'] ?? 0).toDouble();

  Future<void> _confirmBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bookingData == null) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      bool isPaid = false;

      // ── Online payment via SSLCommerz ─────────────────────────────────────
      if (_paymentMethod == PaymentMethod.online && _consultationFee > 0) {
        final payment = await _paymentSvc.processSslPayment(
          context: context,
          orderId: 'APPT_TEMP_${DateTime.now().millisecondsSinceEpoch}',
          amount: _consultationFee,
          method: PaymentMethod.online,
          customerName: _nameController.text.trim(),
          customerEmail: user.email ?? '',
          customerPhone: _phoneController.text.trim(),
        );

        if (payment.status != 'successful') {
          setState(() => _isLoading = false);
          _showErrorDialog(
            payment.status == 'cancelled'
                ? 'Payment was cancelled.'
                : 'Payment failed. Please try again.',
          );
          return;
        }
        isPaid = true;
      }

      // ── Parse slot time ───────────────────────────────────────────────────
      final DateTime appointmentDate = _bookingData!['date'];
      final String timeSlot = _bookingData!['slot'];
      final timeParts = timeSlot.split(' ');
      final timeValue = timeParts[0];
      final isPM = timeParts[1] == 'PM';
      var hour = int.parse(timeValue.split(':')[0]);
      final minute = int.parse(timeValue.split(':')[1]);
      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;
      final combinedDateTime = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        hour,
        minute,
      );

      await _appointmentService.bookAppointment(
        patientId: user.uid,
        patientName: _nameController.text.trim(),
        doctorId: _bookingData!['doctorId'],
        doctorName: _bookingData!['doctorName'] ?? 'Unknown Doctor',
        doctorSpecialty:
            _bookingData!['doctorSpecialty'] ?? 'General Practitioner',
        appointmentDate: combinedDateTime,
        timeSlot: timeSlot,
        reason: _reasonController.text.trim(),
        consultationFee: _consultationFee,
        isPaid: isPaid,
      );

      await _showSuccessDialog(isPaid);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(_prettyError(e));
    }
  }

  Future<void> _showSuccessDialog(bool isPaid) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child:
              Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded,
                  color: Colors.green.shade600, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Booking Confirmed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_bookingData != null) ...[
              Text('Doctor: ${_bookingData!['doctorName']}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                  '${_formatDate(_bookingData!['date'])} · ${_bookingData!['slot']}',
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Text(
                isPaid
                    ? 'Payment of ৳${_consultationFee.toStringAsFixed(0)} confirmed!'
                    : 'Pay ৳${_consultationFee.toStringAsFixed(0)} at the clinic.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isPaid
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                    fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context)
                      .popUntil((r) => r.settings.name == Routes.patientHome);
                },
                child: const Text('Go to Home',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Booking Failed'),
        content: Text(message),
        actions: [
          TextButton(
              child: const Text('OK'), onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  String _prettyError(Object e) {
    final raw = e.toString();
    if (raw.contains('ইতিমধ্যে বুক')) {
      return 'এই সময়টি ইতিমধ্যে বুক করা আছে। অনুগ্রহ করে অন্য সময় বেছে নিন।';
    }
    if (raw.contains('permission-denied')) {
      return 'অনুমতি নেই। আগে সাইন ইন করুন বা আবার চেষ্টা করুন।';
    }
    if (raw.contains('network') || raw.contains('Network')) {
      return 'নেটওয়ার্ক সমস্যা। পরে চেষ্টা করুন।';
    }
    return 'বুকিং ব্যর্থ: ${raw.replaceFirst('Exception: ', '')}';
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final fee = _consultationFee;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Confirm Booking',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Appointment summary ───────────────────────────────
                    if (_bookingData != null)
                      _card(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.calendar_today_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Text('Appointment Summary',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ]),
                              const SizedBox(height: 14),
                              _row(Icons.person_rounded,
                                  _bookingData!['doctorName'] ?? ''),
                              const SizedBox(height: 6),
                              _row(Icons.medical_services_outlined,
                                  _bookingData!['doctorSpecialty'] ?? ''),
                              const SizedBox(height: 6),
                              _row(
                                  Icons.calendar_today_outlined,
                                  '${_formatDate(_bookingData!['date'])} · ${_bookingData!['slot'] ?? ''}'),
                              if (fee > 0) ...[
                                const SizedBox(height: 6),
                                _row(Icons.payments_outlined,
                                    'Fee: ৳${fee.toStringAsFixed(0)}',
                                    color: theme.colorScheme.primary),
                              ],
                            ]),
                      ),
                    const SizedBox(height: 12),

                    // ── Patient details ───────────────────────────────────
                    _card(
                      child: Form(
                        key: _formKey,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.person_outline_rounded,
                                      color: Colors.blue.shade600, size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Text('Patient Details',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700)),
                              ]),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon:
                                      Icon(Icons.person_outline_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Please enter your name'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Please enter your phone number'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              VoiceTextField(
                                controller: _reasonController,
                                decoration: const InputDecoration(
                                  labelText: 'Reason for Visit',
                                  alignLabelWithHint: true,
                                  prefixIcon:
                                      Icon(Icons.edit_note_rounded),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                                minLines: 2,
                              ),
                            ]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Payment method ────────────────────────────────────
                    _card(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.payment_rounded,
                                    color: Colors.purple.shade600, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text('Payment Method',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ]),
                            const SizedBox(height: 14),
                            _PaymentOption(
                              label: 'Cash at Clinic',
                              sublabel: 'Pay ৳${fee.toStringAsFixed(0)} when you visit',
                              icon: Icons.money_rounded,
                              color: Colors.green.shade600,
                              selected:
                                  _paymentMethod == PaymentMethod.cash,
                              onTap: () => setState(
                                  () => _paymentMethod = PaymentMethod.cash),
                            ),
                            const SizedBox(height: 8),
                            _PaymentOption(
                              label: 'Online Payment',
                              sublabel:
                                  'bKash, Nagad, Rocket, Card & more via SSLCommerz',
                              icon: Icons.credit_card_rounded,
                              color: Colors.blue.shade700,
                              selected:
                                  _paymentMethod == PaymentMethod.online,
                              onTap: () => setState(
                                  () => _paymentMethod = PaymentMethod.online),
                            ),
                          ]),
                    ),
                    const SizedBox(height: 24),

                    // ── Confirm button ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _paymentMethod == PaymentMethod.cash
                                  ? Colors.green.shade600
                                  : Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _confirmBooking,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _paymentMethod == PaymentMethod.cash
                                    ? Icons.check_circle_rounded
                                    : Icons.lock_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _paymentMethod == PaymentMethod.cash
                                    ? 'Confirm Booking'
                                    : 'Pay & Confirm',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                              ),
                            ]),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
            ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      );

  Widget _row(IconData icon, String text, {Color? color}) => Row(children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 14,
                    color: color ?? Colors.grey.shade700,
                    fontWeight: color != null ? FontWeight.w600 : null))),
      ]);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}

// ── Payment option tile ───────────────────────────────────────────────────────
class _PaymentOption extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.07) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selected ? color : Colors.black87)),
                  Text(sublabel,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ]),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? color : Colors.transparent,
              border: Border.all(
                  color: selected ? color : Colors.grey.shade400, width: 2),
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : null,
          ),
        ]),
      ),
    );
  }
}
