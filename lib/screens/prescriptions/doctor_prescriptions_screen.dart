// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicore/models/prescription.dart';
import 'package:medicore/services/prescription_service.dart';
import 'package:medicore/screens/prescriptions/prescription_pdf_viewer.dart';
import 'package:medicore/screens/prescriptions/prescription_remote_viewer.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';

class DoctorPrescriptionsScreen extends StatefulWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  State<DoctorPrescriptionsScreen> createState() =>
      _DoctorPrescriptionsScreenState();
}

class _DoctorPrescriptionsScreenState
    extends State<DoctorPrescriptionsScreen> {
  final String _doctorId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _confirmDelete(Prescription p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Prescription'),
        content: const Text(
            'Are you sure you want to delete this prescription? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await PrescriptionService.deletePrescription(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _openEdit(Prescription p) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPrescriptionSheet(prescription: p),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<List<Prescription>>(
        stream: PrescriptionService.streamDoctorPrescriptions(_doctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final prescriptions = snapshot.data ?? [];
          if (prescriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No prescriptions yet',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: prescriptions.length,
            itemBuilder: (_, i) => _PrescriptionCard(
              prescription: prescriptions[i],
              onEdit: () => _openEdit(prescriptions[i]),
              onDelete: () => _confirmDelete(prescriptions[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─── Prescription Card ───────────────────────────────────────────────────────

class _PrescriptionCard extends StatelessWidget {
  final Prescription prescription;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PrescriptionCard({
    required this.prescription,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    final date = p.createdAt.toDate();
    final formatted =
        '${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.description_rounded,
                      color: Color(0xFF667eea), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.medicines.length} Medicine${p.medicines.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      Text(
                        'Patient: ${p.patientId}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(formatted,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ],
            ),
            if (p.medicines.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              ...p.medicines.take(3).map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: Color(0xFF667eea)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${m['name'] ?? ''} — ${m['dosage'] ?? ''} — ${m['duration'] ?? ''}',
                            style: const TextStyle(fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
              if (p.medicines.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('+${p.medicines.length - 3} more',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                // View PDF
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PrescriptionRemoteViewer(prescription: p),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF667eea),
                      side: const BorderSide(color: Color(0xFF667eea)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Edit
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete
                ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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

// ─── Edit Prescription Sheet ─────────────────────────────────────────────────

class _EditPrescriptionSheet extends StatefulWidget {
  final Prescription prescription;
  const _EditPrescriptionSheet({required this.prescription});

  @override
  State<_EditPrescriptionSheet> createState() =>
      _EditPrescriptionSheetState();
}

class _EditPrescriptionSheetState extends State<_EditPrescriptionSheet> {
  final _notesController = TextEditingController();
  late List<_MedRow> _rows;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.prescription.notes;
    _rows = widget.prescription.medicines
        .map((m) => _MedRow(
              name: m['name'] as String? ?? '',
              dosage: m['dosage'] as String? ?? '',
              duration: m['duration'] as String? ?? '',
            ))
        .toList();
    if (_rows.isEmpty) _rows.add(_MedRow());
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final medicines = _rows
        .map((r) => {
              'name': r.name.text.trim(),
              'dosage': r.dosage.text.trim(),
              'duration': r.duration.text.trim(),
            })
        .where((m) => (m['name'] as String).isNotEmpty)
        .toList();

    if (medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medicine')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Generate updated PDF first to show preview
      final updated = Prescription(
        id: widget.prescription.id,
        doctorId: widget.prescription.doctorId,
        doctorName: widget.prescription.doctorName,
        patientId: widget.prescription.patientId,
        medicines: medicines,
        notes: _notesController.text.trim(),
        createdAt: widget.prescription.createdAt,
      );

      final bytes = await PrescriptionService.generatePdfBytes(updated);
      if (!mounted) return;

      Navigator.pop(context); // close sheet
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrescriptionPdfViewer(
            previewBytes: bytes,
            doctorId: widget.prescription.doctorId,
            doctorName: widget.prescription.doctorName,
            patientId: widget.prescription.patientId,
            medicines: medicines,
            notes: _notesController.text.trim(),
            existingId: widget.prescription.id, // overwrite same doc
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          top: false,
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
                        borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Edit Prescription',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Patient: ${widget.prescription.patientId}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                        child: Text('Medicines',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700))),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _rows.add(_MedRow())),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                ..._rows.asMap().entries.map((e) {
                  final i = e.key;
                  final r = e.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: r.name,
                                  decoration: const InputDecoration(
                                      labelText: 'Name',
                                      isDense: true),
                                ),
                              ),
                              IconButton(
                                onPressed: _rows.length > 1
                                    ? () => setState(() {
                                          _rows[i].dispose();
                                          _rows.removeAt(i);
                                        })
                                    : null,
                                icon: const Icon(Icons.delete_rounded,
                                    color: Colors.red, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: r.dosage,
                                  decoration: const InputDecoration(
                                      labelText: 'Dosage',
                                      isDense: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: r.duration,
                                  decoration: const InputDecoration(
                                      labelText: 'Duration',
                                      isDense: true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                VoiceTextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Optional notes for the patient',
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
                        onPressed: _loading ? null : _save,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white))
                            : const Icon(Icons.preview_rounded, size: 18),
                        label: const Text('Preview & Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MedRow {
  final TextEditingController name;
  final TextEditingController dosage;
  final TextEditingController duration;

  _MedRow({String name = '', String dosage = '', String duration = ''})
      : name = TextEditingController(text: name),
        dosage = TextEditingController(text: dosage),
        duration = TextEditingController(text: duration);

  void dispose() {
    name.dispose();
    dosage.dispose();
    duration.dispose();
  }
}
