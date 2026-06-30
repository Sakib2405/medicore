import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/storage_config.dart';

/// A tiny client-only uploader using Cloudinary unsigned uploads.
/// Works on Spark plan (no Cloud Functions, no Storage triggers needed).
/// Returns a publicly accessible URL. Do NOT use for highly sensitive images
/// unless your Cloudinary setup is private/signed. For profile avatars this is fine.
class CloudinaryUploadService {
  CloudinaryUploadService._();

  static final Uri _uploadUri = Uri.parse(
    'https://api.cloudinary.com/v1_1/${StorageConfig.cloudName}/image/upload',
  );
  static final Uri _rawUploadUri = Uri.parse(
    'https://api.cloudinary.com/v1_1/${StorageConfig.cloudName}/raw/upload',
  );
  static final Uri _autoUploadUri = Uri.parse(
    'https://api.cloudinary.com/v1_1/${StorageConfig.cloudName}/auto/upload',
  );

  /// Upload a profile image (File) and return its URL.
  static Future<String> uploadProfileImageFile(File file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    final folder = _folder('profile_images', uid);
    return _uploadFile(file, folder);
  }

  /// Upload a prescription image (File) and return its URL.
  static Future<String> uploadPrescriptionImageFile(File file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    final folder = _folder('prescriptions', uid);
    return _uploadFile(file, folder);
  }

  /// Upload a medicine image (File) for the admin store and return its URL.
  static Future<String> uploadMedicineImageFile(File file) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final folder = _folder('medicine_images', uid);
    return _uploadFile(file, folder);
  }

  /// Upload a profile image (bytes) and return its URL. Useful for Web.
  static Future<String> uploadProfileImageBytes(Uint8List bytes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    final folder = _folder('profile_images', uid);
    return _uploadBytes(bytes, folder);
  }

  /// Upload a prescription image (bytes) and return its URL. Useful for Web.
  static Future<String> uploadPrescriptionImageBytes(Uint8List bytes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    final folder = _folder('prescriptions', uid);
    return _uploadBytes(bytes, folder);
  }

  /// Upload a medicine image (bytes) for the admin store and return its URL.
  static Future<String> uploadMedicineImageBytes(Uint8List bytes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final folder = _folder('medicine_images', uid);
    return _uploadBytes(bytes, folder);
  }

  /// Generic upload: upload any image (bytes) to a custom folder and return its URL.
  /// [collection] is the folder name (e.g., 'general', 'documents', etc.).
  /// If [uid] is null, uses current user's UID or 'anonymous'.
  static Future<String> uploadImageBytes(
    Uint8List bytes, {
    required String collection,
    String? uid,
  }) async {
    final userId = uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final folder = _folder(collection, userId);
    return _uploadBytes(bytes, folder);
  }

  /// Generic upload: upload any image (File) to a custom folder and return its URL.
  /// [collection] is the folder name (e.g., 'general', 'documents', etc.).
  /// If [uid] is null, uses current user's UID or 'anonymous'.
  static Future<String> uploadImageFile(
    File file, {
    required String collection,
    String? uid,
  }) async {
    final userId = uid ?? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final folder = _folder(collection, userId);
    return _uploadFile(file, folder);
  }

  /// Upload a prescription PDF and return its URL.
  /// Uses Cloudinary's /auto/upload endpoint which auto-detects resource type
  /// (image, raw, video) and is most compatible with unsigned upload presets
  /// that restrict to image types only.
  static Future<String> uploadPrescriptionPdfBytes(
    Uint8List bytes, {
    required String doctorId,
    required String prescriptionId,
  }) async {
    final folder = _folder('prescriptions', doctorId);
    // Strategy 1: Use /auto/upload endpoint which auto-detects resource type.
    // This works with image-only unsigned presets because Cloudinary treats PDFs
    // as image-type resources when uploaded through /auto/upload.
    try {
      return await _uploadBytesAuto(
        bytes,
        folder,
        filename: '$prescriptionId.pdf',
      );
    } catch (e) {
      // Fallback: raw upload endpoint
      try {
        return await _uploadRawBytes(
          bytes,
          folder,
          filename: '$prescriptionId.pdf',
        );
      } catch (e2) {
        // Final fallback: image upload endpoint (PDF as image)
        try {
          return await _uploadBytesAsImage(
            bytes,
            folder,
            filename: '$prescriptionId.pdf',
          );
        } catch (fallbackError) {
          throw Exception(
            'PDF upload failed. Cloudinary says "missing or insufficient permission".\n\n'
            'Fix: Go to Cloudinary Console → Settings → Upload → "${StorageConfig.unsignedUploadPreset}" preset → '
            'Add "pdf" to "Allowed formats" (or select "All") and enable "Raw" type support.\n'
            'Also verify the preset is set to "Unsigned" mode.\n'
            'Error details: $fallbackError',
          );
        }
      }
    }
  }

  /// Upload PDF bytes via the /auto/upload endpoint.
  /// Cloudinary's /auto/upload auto-detects the resource type (image, raw, video).
  /// PDFs are typically treated as image-type resources.
  static Future<String> _uploadBytesAuto(
    Uint8List bytes,
    String folder, {
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _autoUploadUri)
      ..fields['upload_preset'] = StorageConfig.unsignedUploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    }
    throw Exception(
      'Auto upload failed: ${response.statusCode} ${response.body}',
    );
  }

  /// Upload PDF bytes via the image upload endpoint.
  /// Cloudinary's /image/upload natively accepts PDF files and stores them
  /// as image-type resources. No special resource_type override needed.
  static Future<String> _uploadBytesAsImage(
    Uint8List bytes,
    String folder, {
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = StorageConfig.unsignedUploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    }
    throw Exception(
      'Image endpoint upload failed: ${response.statusCode} ${response.body}',
    );
  }

  static String _folder(String collection, String uid) {
    final root = StorageConfig.rootFolder.isEmpty
        ? collection
        : '${StorageConfig.rootFolder}/$collection';
    return '$root/$uid';
  }

  static Future<String> _uploadFile(File file, String folder) async {
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = StorageConfig.unsignedUploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    }
    throw Exception('Upload failed: ${response.statusCode} ${response.body}');
  }

  static Future<String> _uploadBytes(Uint8List bytes, String folder) async {
    final request = http.MultipartRequest('POST', _uploadUri)
      ..fields['upload_preset'] = StorageConfig.unsignedUploadPreset
      ..fields['folder'] = folder
      ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: 'image.jpg'));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    }
    throw Exception('Upload failed: ${response.statusCode} ${response.body}');
  }

  static Future<String> _uploadRawBytes(
    Uint8List bytes,
    String folder, {
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', _rawUploadUri)
      ..fields['upload_preset'] = StorageConfig.unsignedUploadPreset
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['secure_url'] as String;
    }
    throw Exception('Raw upload failed: ${response.statusCode} ${response.body}');
  }
}