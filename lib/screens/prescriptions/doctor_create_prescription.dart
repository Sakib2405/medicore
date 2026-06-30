import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/services/prescription_service.dart';
import 'package:medicore/models/prescription.dart';
import 'package:uuid/uuid.dart';
import 'package:medicore/screens/prescriptions/prescription_pdf_viewer.dart';
import 'package:medicore/widgets/common/voice_text_field.dart';

class MedicineRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController durationController = TextEditingController();

  void dispose() {
    nameController.dispose();
    dosageController.dispose();
    durationController.dispose();
  }
}

class DoctorCreatePrescriptionScreen extends StatefulWidget {
  const DoctorCreatePrescriptionScreen({super.key});

  @override
  State<DoctorCreatePrescriptionScreen> createState() =>
      _DoctorCreatePrescriptionScreenState();
}

class _DoctorCreatePrescriptionScreenState
    extends State<DoctorCreatePrescriptionScreen> {
  final _patientController = TextEditingController();
  final _notesController = TextEditingController();
  final List<MedicineRow> _medicines = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill patient ID if passed as argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is String && arg.isNotEmpty) {
        _patientController.text = arg;
      } else if (arg is Map<String, dynamic> && arg['patientId'] != null) {
        _patientController.text = arg['patientId'];
      }
      // Start with one medicine row
      _addMedicineRow();
    });
  }

  void _addMedicineRow() {
    setState(() {
      _medicines.add(MedicineRow());
    });
  }

  void _removeMedicineRow(int index) {
    setState(() {
      _medicines[index].dispose();
      _medicines.removeAt(index);
    });
  }

  @override
  void dispose() {
    _patientController.dispose();
    _notesController.dispose();
    for (final m in _medicines) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final patientId = _patientController.text.trim();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Provide patient ID')));
      return;
    }

    // Validate input for non-ASCII characters
    for (int i = 0; i < _medicines.length; i++) {
      final m = _medicines[i];
      final name = m.nameController.text.trim();
      final dosage = m.dosageController.text.trim();
      final duration = m.durationController.text.trim();
      
      if (name.contains(RegExp(r'[^\x00-\x7F]'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medicine name in row ${i + 1} contains unsupported characters. Please use English characters only.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (dosage.contains(RegExp(r'[^\x00-\x7F]'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dosage in row ${i + 1} contains unsupported characters. Please use English characters only.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (duration.contains(RegExp(r'[^\x00-\x7F]'))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duration in row ${i + 1} contains unsupported characters. Please use English characters only.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final notes = _notesController.text.trim();
    if (notes.contains(RegExp(r'[^\x00-\x7F]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes contain unsupported characters. Please use English characters only.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final medicines = _medicines
        .map((m) {
          return {
            'name': m.nameController.text.trim(),
            'dosage': m.dosageController.text.trim(),
            'duration': m.durationController.text.trim(),
          };
        })
        .where((m) => (m['name'] ?? '').isNotEmpty)
        .toList();
    
    setState(() => _loading = true);

    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to create a prescription'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    final doctorId = doctor.uid;

    try {
      // generate PDF preview first
      final tempId = const Uuid().v4();
      final prescription = Prescription(
        id: tempId,
        doctorId: doctorId,
        patientId: patientId,
        medicines: medicines,
        notes: notes,
        createdAt: Timestamp.now(),
      );

      final bytes = await PrescriptionService.generatePdfBytes(prescription);
      if (!mounted) return;

      final uploaded = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => PrescriptionPdfViewer(
          previewBytes: bytes,
          doctorId: doctorId,
          patientId: patientId,
          medicines: medicines,
          notes: notes,
        ),
      ));
      
      // Only pop this screen if upload was successful
      if (uploaded == true && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Prescription')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _patientController,
              decoration: const InputDecoration(labelText: 'Patient ID'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Medicines',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _medicines.length,
                      itemBuilder: (context, index) {
                        final row = _medicines[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: row.nameController,
                                        decoration: const InputDecoration(
                                            labelText: 'Name'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () =>
                                          _removeMedicineRow(index),
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: row.dosageController,
                                        decoration: const InputDecoration(
                                            labelText: 'Dosage'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: row.durationController,
                                        decoration: const InputDecoration(
                                            labelText: 'Duration'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _addMedicineRow,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Medicine'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: VoiceTextField(
                          controller: _notesController,
                          decoration: const InputDecoration(labelText: 'Notes'),
                          minLines: 1,
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Create & Upload PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
