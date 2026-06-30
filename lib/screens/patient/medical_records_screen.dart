// lib/screens/patient/medical_records_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/models/medical_record_model.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/services/medical_record_service.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final _service = MedicalRecordService();

  static const List<String> _recordTypes = [
    'Laboratory',
    'Radiology',
    'Cardiology',
    'Consultation',
    'Surgery',
    'Other',
  ];

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'laboratory':
        return Colors.blue;
      case 'radiology':
        return Colors.purple;
      case 'cardiology':
        return Colors.red;
      case 'consultation':
        return Colors.green;
      case 'surgery':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'laboratory':
        return Icons.science_outlined;
      case 'radiology':
        return Icons.broken_image_outlined;
      case 'cardiology':
        return Icons.favorite_outline_rounded;
      case 'consultation':
        return Icons.medical_services_outlined;
      case 'surgery':
        return Icons.cut_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  void _showAddSheet(String userId) {
    final titleCtrl = TextEditingController();
    final doctorCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedType = 'Consultation';
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Add Medical Record',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Record Title',
                          hintText: 'e.g. Blood Test Report'),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration:
                          const InputDecoration(labelText: 'Type'),
                      items: _recordTypes
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          setSheet(() => selectedType = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: doctorCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Doctor Name',
                          hintText: 'e.g. Dr. Rahman'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Brief description of the record'),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: Text(
                          DateFormat('d MMM yyyy').format(selectedDate)),
                      subtitle: const Text('Tap to change date'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setSheet(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }
                              final record = MedicalRecordModel(
                                id: '',
                                userId: userId,
                                title: titleCtrl.text.trim(),
                                type: selectedType,
                                doctor: doctorCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                                date: selectedDate,
                                createdAt: DateTime.now(),
                              );
                              await _service.addRecord(record);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: const Text('Save'),
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
      ),
    );
  }

  void _confirmDelete(String recordId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteRecord(recordId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Record deleted'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewRecord(MedicalRecordModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(r.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.category_outlined, 'Type', r.type),
            _detailRow(Icons.person_outline, 'Doctor',
                r.doctor.isNotEmpty ? r.doctor : 'N/A'),
            _detailRow(Icons.calendar_today_outlined, 'Date',
                DateFormat('d MMM yyyy').format(r.date)),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Description:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(r.description,
                  style: TextStyle(color: Colors.grey.shade700)),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
              child: Text(value,
                  style: TextStyle(color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId =
        context.watch<AuthProvider>().currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, Routes.myPrescriptions),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'My Prescriptions',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F8FB),
      floatingActionButton: userId.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddSheet(userId),
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: userId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<MedicalRecordModel>>(
              stream: _service.watchRecords(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final records = snapshot.data ?? [];

                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.04),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.medical_services_rounded,
                                color: Colors.white,
                                size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Medical Records',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${records.length} record${records.length == 1 ? '' : 's'} — live',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: records.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: records.length,
                              itemBuilder: (_, i) =>
                                  _buildCard(records[i]),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCard(MedicalRecordModel r) {
    final color = _typeColor(r.type);
    return Dismissible(
      key: Key(r.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 28),
      ),
      confirmDismiss: (_) async {
        _confirmDelete(r.id, r.title);
        return false; // Dialog handles the actual delete
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewRecord(r),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_typeIcon(r.type), color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(r.title,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(r.type,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      if (r.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(r.description,
                            style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 14,
                              color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                                r.doctor.isNotEmpty
                                    ? r.doctor
                                    : 'Unknown doctor',
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Icon(Icons.calendar_today_outlined,
                              size: 13,
                              color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                              DateFormat('d MMM yyyy').format(r.date),
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.medical_services_outlined,
                size: 52, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text('No Medical Records',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Tap + to add your first record',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}
