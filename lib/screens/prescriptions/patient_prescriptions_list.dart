// imports trimmed; PDF viewing handled by PrescriptionRemoteViewer
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medicore/screens/prescriptions/prescription_remote_viewer.dart';
import 'package:medicore/models/prescription.dart';
import 'package:medicore/services/prescription_service.dart';

class PatientPrescriptionsList extends StatelessWidget {
  const PatientPrescriptionsList({super.key});

  // in-app viewer is used now; keep this class focused on listing

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final patientId = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Prescriptions')),
      body: StreamBuilder<List<Prescription>>(
        stream: PrescriptionService.streamPatientPrescriptions(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No prescriptions'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final p = list[i];
              final date = p.createdAt.toDate();
              final formatted =
                  '${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.description_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.doctorName != null && p.doctorName!.isNotEmpty
                                ? 'Dr. ${p.doctorName}'
                                : 'Doctor',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${p.medicines.length} medicine${p.medicines.length == 1 ? '' : 's'}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatted,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => PrescriptionRemoteViewer(
                                  prescription: p))),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('View'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
