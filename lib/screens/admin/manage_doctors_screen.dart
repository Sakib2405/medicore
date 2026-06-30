import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicore/models/doctor_model.dart';
import 'package:medicore/providers/doctor_provider.dart';
import 'package:medicore/widgets/admin/doctor_card_admin.dart';

class ManageDoctorsScreen extends StatefulWidget {
  const ManageDoctorsScreen({super.key});

  @override
  State<ManageDoctorsScreen> createState() => _ManageDoctorsScreenState();
}

class _ManageDoctorsScreenState extends State<ManageDoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DoctorProvider>(context, listen: false).loadDoctors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildField(TextEditingController ctrl, String label,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        labelText: label,
      ),
    );
  }

  void _showAddDoctorDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final clinicCtrl = TextEditingController();
    final feeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        bool isPremium = false;
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Add Doctor',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _buildField(nameCtrl, 'Full name'),
                        const SizedBox(height: 8),
                        _buildField(emailCtrl, 'Email',
                            keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 8),
                        _buildField(passwordCtrl, 'Password', obscure: true),
                        const SizedBox(height: 8),
                        _buildField(specialtyCtrl, 'Specialty'),
                        const SizedBox(height: 8),
                        _buildField(phoneCtrl, 'Phone',
                            keyboard: TextInputType.phone),
                        const SizedBox(height: 8),
                        _buildField(expCtrl, 'Experience (years)',
                            keyboard: TextInputType.number),
                        const SizedBox(height: 8),
                        _buildField(clinicCtrl, 'Clinic/Hospital'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: feeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: 'Consultation Fee (৳)',
                              suffixText: 'BDT',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Premium Doctor'),
                            const Spacer(),
                            Switch(
                                value: isPremium,
                                onChanged: (v) =>
                                    setState(() => isPremium = v)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Consumer<DoctorProvider>(
                            builder: (context, prov, child) {
                          return Row(
                            children: [
                              Expanded(
                                  child: OutlinedButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel'))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: prov.isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          onPressed: () async {
                                            if (!formKey.currentState!
                                                .validate()) {
                                              return;
                                            }
                                            final success =
                                                await prov.addDoctor(
                                              name: nameCtrl.text.trim(),
                                              email: emailCtrl.text.trim(),
                                              password:
                                                  passwordCtrl.text.trim(),
                                              specialty:
                                                  specialtyCtrl.text.trim(),
                                              phone: phoneCtrl.text.trim(),
                                              experience: expCtrl.text.trim(),
                                              clinic: clinicCtrl.text.trim(),
                                              consultationFee:
                                                  feeCtrl.text.trim().isEmpty
                                                      ? null
                                                      : double.tryParse(
                                                          feeCtrl.text.trim()),
                                              isPremium: isPremium,
                                            );
                                            if (success && context.mounted) {
                                              Navigator.of(ctx).pop();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Doctor added')));
                                            } else if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(prov
                                                              .errorMessage ??
                                                          'Failed to add')));
                                            }
                                          },
                                          child: const Text('Add Doctor'),
                                        )),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showEditDoctorDialog(BuildContext context, Doctor doctor) {
    final nameCtrl = TextEditingController(text: doctor.name);
    final emailCtrl = TextEditingController(text: doctor.email);
    final specialtyCtrl = TextEditingController(text: doctor.specialty);
    final phoneCtrl = TextEditingController(text: doctor.phone);
    final expCtrl =
        TextEditingController(text: doctor.experienceYears?.toString() ?? '');
    final clinicCtrl = TextEditingController(text: doctor.clinicName);
    final feeCtrl = TextEditingController(
        text: doctor.consultationFee?.toStringAsFixed(0) ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        bool isPremium = doctor.isPremium;
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Edit Doctor',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        _buildField(nameCtrl, 'Full name'),
                        const SizedBox(height: 8),
                        _buildField(emailCtrl, 'Email',
                            keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 8),
                        _buildField(specialtyCtrl, 'Specialty'),
                        const SizedBox(height: 8),
                        _buildField(phoneCtrl, 'Phone',
                            keyboard: TextInputType.phone),
                        const SizedBox(height: 8),
                        _buildField(expCtrl, 'Experience (years)',
                            keyboard: TextInputType.number),
                        const SizedBox(height: 8),
                        _buildField(clinicCtrl, 'Clinic/Hospital'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: feeCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: 'Consultation Fee (৳)',
                              suffixText: 'BDT',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Premium Doctor'),
                            const Spacer(),
                            Switch(
                                value: isPremium,
                                onChanged: (v) =>
                                    setState(() => isPremium = v)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Consumer<DoctorProvider>(
                            builder: (context, prov, child) {
                          return Row(
                            children: [
                              Expanded(
                                  child: OutlinedButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Cancel'))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: prov.isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          onPressed: () async {
                                            if (!formKey.currentState!
                                                .validate()) {
                                              return;
                                            }
                                            final success =
                                                await prov.updateDoctor(
                                              uid: doctor.uid,
                                              name: nameCtrl.text.trim(),
                                              email: emailCtrl.text.trim(),
                                              specialty:
                                                  specialtyCtrl.text.trim(),
                                              phone: phoneCtrl.text.trim(),
                                              experience: expCtrl.text.trim(),
                                              clinic: clinicCtrl.text.trim(),
                                              consultationFee:
                                                  feeCtrl.text.trim().isEmpty
                                                      ? null
                                                      : double.tryParse(
                                                          feeCtrl.text.trim()),
                                              isPremium: isPremium,
                                            );
                                            if (success && context.mounted) {
                                              Navigator.of(ctx).pop();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'Doctor updated')));
                                            } else if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(prov
                                                              .errorMessage ??
                                                          'Failed to update doctor. Try again.')));
                                            }
                                          },
                                          child: const Text('Update Doctor'),
                                        )),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, Doctor doctor, DoctorProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: Text(
            'Are you sure you want to delete ? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final success = await provider.deleteDoctor(doctor.uid);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Doctor deleted')));
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content:
                          Text(provider.errorMessage ?? 'Failed to delete')));
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _updateApprovalStatus(
    BuildContext context,
    DoctorProvider provider,
    Doctor doctor,
    bool approve,
  ) async {
    final success = approve
        ? await provider.approveDoctor(doctor.uid)
        : await provider.rejectDoctor(doctor.uid);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${doctor.name} ${approve ? 'approved' : 'rejected'}'
              : (provider.errorMessage ?? 'Failed to update doctor status'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Manage Doctors'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () => _showAddDoctorDialog(context),
              icon: const Icon(Icons.add_rounded, color: Colors.blue))
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search doctors',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Approval Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All doctors')),
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('Pending approval'),
                  ),
                  DropdownMenuItem(value: 'verified', child: Text('Approved')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatus = value);
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<DoctorProvider>(builder: (context, prov, child) {
                if (prov.isLoading && prov.doctors.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final doctors = prov.doctors
                    .where((d) =>
                        _searchQuery.isEmpty ||
                        d.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                    .where((doctor) => _selectedStatus == 'all'
                        ? true
                        : doctor.verificationStatus == _selectedStatus)
                    .toList();
                if (doctors.isEmpty) {
                  return Center(
                      child: Text(_searchQuery.isEmpty
                          ? 'No doctors'
                          : 'No results for ""'));
                }
                return RefreshIndicator(
                  onRefresh: () => prov.loadDoctors(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: doctors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final doctor = doctors[index];
                      return DoctorCardAdmin(
                        doctor: doctor,
                        onEdit: () => _showEditDoctorDialog(context, doctor),
                        onDelete: () =>
                            _showDeleteConfirmation(context, doctor, prov),
                        onApprove: doctor.verificationStatus == 'verified'
                            ? null
                            : () => _updateApprovalStatus(
                                context, prov, doctor, true),
                        onReject: doctor.verificationStatus == 'rejected'
                            ? null
                            : () => _updateApprovalStatus(
                                context, prov, doctor, false),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDoctorDialog(context),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
