// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:intl/intl.dart';

import 'package:medicore/models/doctor_model.dart' as models;
import 'package:medicore/models/review_model.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/providers/patient_provider.dart';
import 'package:medicore/services/appointment_service.dart';
import 'package:medicore/services/payment_service.dart';
import 'package:medicore/services/review_service.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';

class DoctorProfileScreen extends StatefulWidget {
  final models.Doctor doctor;

  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final PaymentService _paymentService = PaymentService();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _selectedServiceIndex = 0;
  final TextEditingController _reasonCtrl =
      TextEditingController(text: 'সাধারণ পরামর্শ');
  final TextEditingController _notesCtrl = TextEditingController();
  bool _isBooking = false;
  bool _payOnline = false;
  PaymentMethod _method = PaymentMethod.bkash;
  Set<int> _bookedMinutes = <int>{};

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final patientProvider = context.read<PatientProvider>();
      await patientProvider
          .syncCurrentPatientFromUser(authProvider.currentUser);
    });
  }

  void _showFullPhoto() {
    if (!mounted || !(widget.doctor.imageUrl?.isNotEmpty ?? false)) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Hero(
            tag: 'doctor-photo-${widget.doctor.uid}',
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                widget.doctor.imageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                },
                errorBuilder: (context, error, stack) => const Center(
                  child:
                      Icon(Icons.broken_image, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('ডাক্তারের প্রোফাইল / Doctor Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorHeader(),
              const SizedBox(height: 16),
              _buildPatientInfoCard(),
              const SizedBox(height: 24),
              _buildAboutSection(),
              const SizedBox(height: 24),
              if (widget.doctor.services.isNotEmpty) _buildServicesSection(),
              if (widget.doctor.services.isNotEmpty) const SizedBox(height: 24),
              _buildEducationCertifications(),
              const SizedBox(height: 24),
              _buildLanguagesSection(),
              const SizedBox(height: 24),
              _buildWorkingHours(),
              const SizedBox(height: 24),
              _buildAvailabilitySection(),
              const SizedBox(height: 24),
              _buildReviewsSection(),
              const SizedBox(height: 24),
              _buildReasonNotes(),
              const SizedBox(height: 24),
              _buildPaymentChoice(),
              const SizedBox(height: 12),
              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChoice() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('পেমেন্ট অপশন / Payment Option',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                  'Pay Online (bKash/Nagad/Rocket) / অনলাইনে পরিশোধ'),
              value: _payOnline,
              onChanged: (v) => setState(() => _payOnline = v),
            ),
            if (_payOnline) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('bKash'),
                    selected: _method == PaymentMethod.bkash,
                    onSelected: (_) =>
                        setState(() => _method = PaymentMethod.bkash),
                  ),
                  ChoiceChip(
                    label: const Text('Nagad'),
                    selected: _method == PaymentMethod.nagad,
                    onSelected: (_) =>
                        setState(() => _method = PaymentMethod.nagad),
                  ),
                  ChoiceChip(
                    label: const Text('Rocket'),
                    selected: _method == PaymentMethod.rocket,
                    onSelected: (_) =>
                        setState(() => _method = PaymentMethod.rocket),
                  ),
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.blue.shade100,
                      width: 3,
                    ),
                  ),
                  child: widget.doctor.hasImage
                      ? GestureDetector(
                          onTap: _showFullPhoto,
                          child: Hero(
                            tag: 'doctor-photo-${widget.doctor.uid}',
                            child: ClipOval(
                              child: Image.network(
                                widget.doctor.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    color: Colors.blue.shade600,
                                    size: 40,
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.blue.shade600,
                          size: 40,
                        ),
                ),
                if (widget.doctor.isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.doctor.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.doctor.isHighlyRated)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Top Rated',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 6),
                      if (widget.doctor.isPremium)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.workspace_premium,
                                  size: 14, color: Colors.amber.shade800),
                              const SizedBox(width: 6),
                              Text(
                                'Premium',
                                style: TextStyle(
                                    color: Colors.amber.shade800,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.doctor.specialty,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 20,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.doctor.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.doctor.totalRatings} reviews)'
                            .replaceAll('reviews', 'রিভিউ'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (widget.doctor.experienceYears != null)
                    Text(
                      '${widget.doctor.experienceYears} years experience'
                          .replaceAll('years', 'বছর'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (widget.doctor.qualification != null)
                    Text(
                      widget.doctor.qualification!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
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

  Widget _buildPatientInfoCard() {
    return Consumer<PatientProvider>(
      builder: (context, patientProvider, _) {
        final patientRecordId = patientProvider.currentPatient?.id ?? 'N/A';
        final patientCode = patientProvider.currentPatient?.patientId ?? 'N/A';
        final isConnected =
            patientProvider.isDoctorConnected(widget.doctor.uid);

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Patient Record ID',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isConnected ? Icons.verified : Icons.add,
                              size: 14,
                              color: isConnected
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isConnected ? 'Connected' : 'Connect',
                              style: TextStyle(
                                fontSize: 12,
                                color: isConnected
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientRecordId,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Patient Code',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          patientCode,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Copied from patient profile',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Copied: $patientRecordId',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.copy,
                                size: 18,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isConnected) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final success = await patientProvider
                              .connectDoctor(widget.doctor.uid);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Connected to ${widget.doctor.name}'
                                      : 'Failed to connect',
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                            if (success) {
                              setState(() {});
                            }
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Connect with this Doctor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You are connected with ${widget.doctor.name}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ডাক্তারের সম্পর্কে / About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.doctor.clinicName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.doctor.clinicName!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.doctor.clinicAddress != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.doctor.clinicAddress!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.doctor.email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.doctor.email,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.doctor.phone != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.doctor.phone!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 20,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ফি: ${widget.doctor.consultationFeeText}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.doctor.licenseNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge,
                      size: 20,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'লাইসেন্স: ${widget.doctor.licenseNumber!}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            if (widget.doctor.bio != null && widget.doctor.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.doctor.bio!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'সার্ভিসসমূহ / Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.doctor.services.asMap().entries.map((entry) {
                final index = entry.key;
                final service = entry.value;
                return ChoiceChip(
                  label: Text(service),
                  selected: _selectedServiceIndex == index,
                  onSelected: (selected) {
                    setState(() {
                      _selectedServiceIndex = index;
                    });
                  },
                  selectedColor: Colors.blue.shade100,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: _selectedServiceIndex == index
                        ? Colors.blue.shade800
                        : Colors.grey.shade700,
                    fontWeight: _selectedServiceIndex == index
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _selectedServiceIndex == index
                          ? Colors.blue.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationCertifications() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.doctor.education.isNotEmpty) ...[
              const Text(
                'Education',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.doctor.education.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.school,
                          size: 16,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],
            if (widget.doctor.certifications.isNotEmpty) ...[
              const Text(
                'Certifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.doctor.certifications.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.verified_user,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ভাষা / Languages',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.doctor.languages
                  .map((language) => Chip(
                        label: Text(language),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade200),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingHours() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'চেম্বার সময়সূচী / Working Hours',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.doctor.workingHours.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: entry.value == 'Closed'
                                ? Colors.red.shade600
                                : Colors.grey.shade700,
                            fontWeight: entry.value == 'Closed'
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  Text(
                    'Today: ${widget.doctor.todayWorkingHours}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.doctor.isWorkingNow)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Working Now',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildAvailabilitySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'অ্যাপয়েন্টমেন্ট বুক করুন / Book Appointment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.doctor.services.isNotEmpty) ...[
              const Text(
                'সার্ভিস নির্বাচন করুন / Select Service:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedServiceIndex,
                onChanged: (value) {
                  setState(() {
                    _selectedServiceIndex = value!;
                  });
                },
                items: widget.doctor.services.asMap().entries.map((entry) {
                  return DropdownMenuItem<int>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'তারিখ নির্বাচন করুন / Select Date:',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selectDate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Choose Date'
                        : '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 20,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'সময় নির্বাচন করুন / Selected Time:',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selectedDate == null ? null : _selectTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade50,
                    foregroundColor: Colors.blue.shade700,
                  ),
                  child: Text(
                    _selectedTime == null
                        ? 'সময় বাছাই করুন / Choose Time'
                        : _formatTimeOfDay(_selectedTime!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedDate != null) _buildTimeSlots(),
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'অ্যাপয়েন্টমেন্ট সময়কাল: ${widget.doctor.appointmentDuration} মিনিট',
                    style: TextStyle(
                      color: Colors.grey.shade700,
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

  Widget _buildTimeSlots() {
    final availableSlots = widget.doctor.availableTimeSlots.isEmpty
        ? <String>[
            '09:00 AM',
            '10:00 AM',
            '11:00 AM',
            '02:00 PM',
            '03:00 PM',
            '04:00 PM'
          ]
        : widget.doctor.availableTimeSlots;

    final selectedTimeString =
        _selectedTime == null ? null : _formatTimeOfDay(_selectedTime!);

    // We will show all slots, but disable the ones that are booked
    final allSlots = availableSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'উপলব্ধ সময় / Available Slots (${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}):',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (allSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'আজকের সব স্লট বুকড। অন্য তারিখ বা সময় চেষ্টা করুন।',
              style: TextStyle(color: Colors.orange.shade800),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allSlots.map((slot) {
              final minutes = _slotToMinutes(slot);
              final isBooked = minutes >= 0 && _bookedMinutes.contains(minutes);
              final isSelected = !isBooked && selectedTimeString == slot;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isBooked) ...[
                      Icon(Icons.lock_clock,
                          size: 14, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                    ],
                    Text(isBooked ? slot : slot),
                  ],
                ),
                selected: isSelected,
                onSelected: isBooked
                    ? null
                    : (selected) {
                        if (selected) {
                          final format = RegExp(r'^(\d+):(\d+)\s*(AM|PM)\b');
                          final match = format.firstMatch(slot);
                          if (match != null) {
                            int hour = int.parse(match.group(1)!);
                            final minute = int.parse(match.group(2)!);
                            final period = match.group(3)!;
                            if (period == 'PM' && hour != 12) hour += 12;
                            if (period == 'AM' && hour == 12) hour = 0;
                            setState(() {
                              _selectedTime =
                                  TimeOfDay(hour: hour, minute: minute);
                            });
                          }
                        }
                      },
                selectedColor: Colors.blue.shade100,
                backgroundColor:
                    isBooked ? Colors.grey.shade200 : Colors.grey.shade100,
                labelStyle: TextStyle(
                  color: isBooked
                      ? Colors.grey.shade600
                      : (isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade700),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isBooked
                        ? Colors.grey.shade300
                        : (isSelected
                            ? Colors.blue.shade300
                            : Colors.grey.shade300),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final doctorId = widget.doctor.uid;
    final totalRatings = widget.doctor.totalRatings;
    final avgRating = totalRatings > 0
        ? widget.doctor.rating / totalRatings
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with aggregate
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
                const SizedBox(width: 8),
                const Text('Patient Reviews',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                if (totalRatings > 0) ...[
                  Text(avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF59E0B))),
                  const SizedBox(width: 4),
                  Text('/ 5  ($totalRatings)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ],
            ),
            if (totalRatings > 0) ...[
              const SizedBox(height: 6),
              // Star bar
              Row(
                children: List.generate(5, (i) {
                  final filled = i < avgRating.round();
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 18,
                  );
                }),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            StreamBuilder<List<Review>>(
              stream: ReviewService.streamDoctorReviews(doctorId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ));
                }
                final reviews = snap.data ?? [];
                if (reviews.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No reviews yet. Be the first to rate!',
                        style: TextStyle(color: Colors.grey.shade500)),
                  );
                }
                return Column(
                  children: reviews.take(5).map((r) {
                    final date =
                        DateFormat('d MMM yyyy').format(r.createdAt.toDate());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFF667eea)
                                    .withValues(alpha: 0.12),
                                child: Text(
                                  r.patientName.isNotEmpty
                                      ? r.patientName[0].toUpperCase()
                                      : 'P',
                                  style: const TextStyle(
                                      color: Color(0xFF667eea),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.patientName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                    Text(date,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500)),
                                  ],
                                ),
                              ),
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < r.rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: const Color(0xFFF59E0B),
                                    size: 14,
                                  );
                                }),
                              ),
                            ],
                          ),
                          if (r.comment.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(r.comment,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    height: 1.4)),
                          ],
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonNotes() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ভিজিটের কারণ / Reason for Visit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            VoiceTextField(
              controller: _reasonCtrl,
              decoration: InputDecoration(
                hintText:
                    'যেমন: ফলো-আপ, জ্বর, কাশি... / e.g. Follow-up, Fever, Cough',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'অতিরিক্ত নোট (ঐচ্ছিক) / Additional Notes (optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            VoiceTextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'ডাক্তারের জন্য বার্তা... / Message for the doctor...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    final selectedService = widget.doctor.services.isNotEmpty
        ? widget.doctor.services[_selectedServiceIndex]
        : 'Consultation';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isBooking || _selectedDate == null || _selectedTime == null
            ? null
            : _bookAppointment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isBooking
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'অ্যাপয়েন্টমেন্ট বুক করুন / Book Appointment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.doctor.consultationFeeText} • $selectedService',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
      // Load booked slots for the selected date
      await _loadBookedSlots();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final auth = context.read<AuthProvider>();
    var user = auth.currentUser;
    if (user == null) {
      // On web the Firebase auth state can be present while our provider hasn't
      // yet loaded the Firestore user document. Try to refresh provider state.
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await auth.refreshUser();
        user = auth.currentUser;
      }
    }

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('দয়া করে প্রথমে লগইন করুন / Please sign in first'),
          backgroundColor: Colors.red,
        ),
      );
      // Redirect to login screen so user can sign in
      Navigator.pushNamed(context, Routes.login);
      return;
    }

    final date = _selectedDate!;
    final time = _selectedTime!;
    final appointmentDate =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);

    final selectedService = widget.doctor.services.isNotEmpty
        ? widget.doctor.services[_selectedServiceIndex]
        : 'Consultation';

    setState(() => _isBooking = true);

    try {
      // If online payment, charge first
      bool paid = false;
      if (_payOnline) {
        final result = await _paymentService.processSslPayment(
          context: context,
          orderId: 'APPT_${DateTime.now().millisecondsSinceEpoch}',
          amount: widget.doctor.consultationFee ?? 0.0,
          method: _method,
          customerName: user.name,
          customerEmail: user.email,
          customerPhone: user.phone,
        );
        if (result.status != 'successful') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed or cancelled')),
          );
          setState(() => _isBooking = false);
          return;
        }
        paid = true;
      }

      final created = await _appointmentService.bookAppointment(
        patientId: user.id,
        patientName: user.name,
        doctorId: widget.doctor.uid,
        doctorName: widget.doctor.name,
        doctorSpecialty: widget.doctor.specialty,
        appointmentDate: appointmentDate,
        timeSlot: _formatTimeOfDay(time),
        reason: _reasonCtrl.text.trim().isEmpty
            ? selectedService
            : _reasonCtrl.text.trim(),
        consultationFee: widget.doctor.consultationFee ?? 0.0,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        isPaid: paid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'অ্যাপয়েন্টমেন্ট বুকিং সফল • স্ট্যাটাস: ${created.status.toUpperCase()}'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamed(
        context,
        Routes.appointmentDetail,
        arguments: created.id,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = _prettyError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  Future<void> _loadBookedSlots() async {
    if (_selectedDate == null) return;
    try {
      final set = await _appointmentService.getBookedSlotMinutesForDoctorOnDate(
        doctorId: widget.doctor.uid,
        date: _selectedDate!,
      );
      if (!mounted) return;
      setState(() => _bookedMinutes = set);
    } catch (_) {
      // Ignore silently; UI will just not mark booked slots
    }
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

  String _prettyError(Object e) {
    final raw = e.toString();
    // Common Firestore/Service error messages polishing
    if (raw.contains('এই সময়টি ইতিমধ্যে বুক করা হয়েছে')) {
      return 'এই সময়টি ইতিমধ্যে বুক করা আছে। অনুগ্রহ করে অন্য সময় বেছে নিন।';
    }
    if (raw.contains('permission-denied')) {
      return 'অনুমতি নেই। আগে সাইন ইন করুন বা আবার চেষ্টা করুন।';
    }
    if (raw.contains('network') || raw.contains('Network')) {
      return 'নেটওয়ার্ক সমস্যার কারণে বুকিং সম্পন্ন হয়নি। পরে চেষ্টা করুন।';
    }
    return 'বুকিং ব্যর্থ: ${raw.replaceFirst('Exception: ', '')}';
  }
}
