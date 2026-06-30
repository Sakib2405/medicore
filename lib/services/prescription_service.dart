import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'cloudinary_upload_service.dart';
import '../models/prescription.dart';

class PrescriptionService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<Uint8List> generatePdfBytes(Prescription p) async {
    try {
      final doc = pw.Document();

      // Try Google Fonts; fall back to built-in Helvetica if unavailable
      pw.Font regularFont;
      pw.Font boldFont;
      try {
        regularFont = await PdfGoogleFonts.notoSansRegular()
            .timeout(const Duration(seconds: 8));
        boldFont = await PdfGoogleFonts.notoSansBold()
            .timeout(const Duration(seconds: 8));
      } catch (_) {
        regularFont = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
      }

      // Try to load logo asset
      pw.ImageProvider? logoImage;
      try {
        final logoBytes = await rootBundle.load('assets/images/logo.png');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {
        logoImage = null;
      }

      doc.addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with logo and clinic name
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 50,
                            height: 50,
                            margin: const pw.EdgeInsets.only(right: 10),
                            child: pw.Image(logoImage),
                          ),
                        pw.Text('Medicore Clinic',
                            style: pw.TextStyle(
                                fontSize: 18, font: boldFont)),
                      ],
                    ),
                    pw.Text('Prescription',
                        style: pw.TextStyle(
                            fontSize: 14, font: regularFont)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text('Date: ${p.createdAt.toDate().toString()}',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: pdf.PdfColors.grey,
                        font: regularFont)),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                    p.doctorName != null && p.doctorName!.isNotEmpty
                        ? 'Dr. ${p.doctorName}'
                        : 'Doctor ID: ${p.doctorId}',
                    style: pw.TextStyle(
                        fontSize: 12, font: boldFont)),
                pw.Text('Patient ID: ${p.patientId}',
                    style: pw.TextStyle(
                        fontSize: 12, font: regularFont)),
                pw.SizedBox(height: 12),
                pw.Text('Medicines',
                    style: pw.TextStyle(
                        fontSize: 14, font: boldFont)),
                pw.SizedBox(height: 6),
                ...p.medicines.map((m) {
                  final name = (m['name'] ?? '') as String;
                  final dosage = (m['dosage'] ?? '') as String;
                  final duration = (m['duration'] ?? '') as String;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Text('* $name - $dosage - $duration',
                        style: pw.TextStyle(
                            fontSize: 12, font: regularFont)),
                  );
                }),
                pw.SizedBox(height: 12),
                pw.Text('Notes',
                    style: pw.TextStyle(
                        fontSize: 14, font: boldFont)),
                pw.SizedBox(height: 6),
                pw.Text(p.notes,
                    style: pw.TextStyle(
                        fontSize: 12, font: regularFont)),
                pw.SizedBox(height: 32),
                pw.Text(
                    p.doctorName != null && p.doctorName!.isNotEmpty
                        ? 'Dr. ${p.doctorName}'
                        : 'Dr. ${p.doctorId}',
                    style: pw.TextStyle(
                        fontSize: 11,
                        font: boldFont)),
                pw.Text('________________________',
                    style: pw.TextStyle(
                        fontSize: 12, font: regularFont)),
                pw.Text('Signature',
                    style: pw.TextStyle(
                        fontSize: 9,
                        color: pdf.PdfColors.grey,
                        font: regularFont)),
              ],
            );
          },
        ),
      );

      return doc.save();
    } catch (e) {
      throw Exception('PDF generation failed: $e');
    }
  }

  /// Creates prescription, generates PDF, uploads to Cloudinary, saves to Firestore.
  /// Uses FirebaseAuth.currentUser.uid as doctorId to match Firestore security rules.
  static Future<String> createAndUploadPrescription({
    required String doctorId,
    required String patientId,
    required List<Map<String, dynamic>> medicines,
    required String notes,
    String? doctorName,
  }) async {
    final id = const Uuid().v4();
    final now = Timestamp.now();

    // CRITICAL: Use Firebase Auth UID for Firestore writes to pass security rules.
    // The Firestore rule checks: request.resource.data.doctorId == request.auth.uid
    // So the data's doctorId must match the authenticated user's UID.
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null) {
      throw Exception('User not authenticated. Please sign in first.');
    }

    final prescription = Prescription(
      id: id,
      doctorId: authUid,
      doctorName: doctorName,
      patientId: patientId,
      medicines: medicines,
      notes: notes,
      createdAt: now,
    );

    final bytes = await generatePdfBytes(prescription);

    String url;
    try {
      url = await CloudinaryUploadService.uploadPrescriptionPdfBytes(
        bytes,
        doctorId: authUid,
        prescriptionId: id,
      );
    } catch (uploadError) {
      throw Exception(
        'Prescription PDF upload failed: $uploadError',
      );
    }

    // Make the URL publicly accessible
    final publicUrl = _ensurePublicUrl(url);

    await _firestore.collection('prescriptions').doc(id).set({
      'id': id,
      'doctorId': authUid,
      'doctorName': doctorName,
      'patientId': patientId,
      'medicines': medicines,
      'notes': notes,
      'createdAt': now,
      'pdfUrl': publicUrl,
    });

    return id;
  }

  /// Upload pre-generated PDF bytes — skips regeneration for speed.
  /// Use this when you already have the bytes from a preview.
  static Future<String> uploadAndSavePrescription({
    required Uint8List bytes,
    required String patientId,
    required List<Map<String, dynamic>> medicines,
    required String notes,
    String? doctorName,
    String? existingId, // pass to reuse same Firestore doc id
  }) async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null) throw Exception('Not authenticated');

    final id = existingId ?? const Uuid().v4();
    final now = Timestamp.now();

    final url = await CloudinaryUploadService.uploadPrescriptionPdfBytes(
      bytes,
      doctorId: authUid,
      prescriptionId: id,
    );

    await _firestore.collection('prescriptions').doc(id).set({
      'id': id,
      'doctorId': authUid,
      'doctorName': doctorName,
      'patientId': patientId,
      'medicines': medicines,
      'notes': notes,
      'createdAt': now,
      'pdfUrl': url,
    });

    return id;
  }

  /// Delete a prescription (Firestore doc only — Cloudinary cleanup optional).
  static Future<void> deletePrescription(String prescriptionId) async {
    await _firestore.collection('prescriptions').doc(prescriptionId).delete();
  }

  /// Update medicines/notes and re-generate + re-upload PDF.
  static Future<void> updatePrescription({
    required Prescription existing,
    required List<Map<String, dynamic>> medicines,
    required String notes,
  }) async {
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (authUid == null) throw Exception('Not authenticated');

    final updated = Prescription(
      id: existing.id,
      doctorId: authUid,
      doctorName: existing.doctorName,
      patientId: existing.patientId,
      medicines: medicines,
      notes: notes,
      createdAt: existing.createdAt,
    );

    final bytes = await generatePdfBytes(updated);

    final url = await CloudinaryUploadService.uploadPrescriptionPdfBytes(
      bytes,
      doctorId: authUid,
      prescriptionId: existing.id,
    );

    await _firestore.collection('prescriptions').doc(existing.id).update({
      'medicines': medicines,
      'notes': notes,
      'pdfUrl': url,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Stream all prescriptions created by a doctor (client-side sort avoids
  /// needing a composite Firestore index on doctorId + createdAt).
  static Stream<List<Prescription>> streamDoctorPrescriptions(
      String doctorId) {
    return _firestore
        .collection('prescriptions')
        .where('doctorId', isEqualTo: doctorId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Prescription.fromMap(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Returns the Cloudinary URL as-is (already public from unsigned upload).
  /// fl_attachment was removed because it triggers 401 on accounts with
  /// Strict Transformations enabled.
  static String _ensurePublicUrl(String url) => url;

  static Stream<List<Prescription>> streamPatientPrescriptions(
      String patientId) {
    return _firestore
        .collection('prescriptions')
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Prescription.fromMap(d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}