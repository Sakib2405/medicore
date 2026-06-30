import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:medicore/models/prescription.dart';
import 'package:medicore/services/prescription_service.dart';

class PrescriptionRemoteViewer extends StatefulWidget {
  final Prescription prescription;

  const PrescriptionRemoteViewer({super.key, required this.prescription});

  @override
  State<PrescriptionRemoteViewer> createState() =>
      _PrescriptionRemoteViewerState();
}

class _PrescriptionRemoteViewerState extends State<PrescriptionRemoteViewer> {
  bool _loading = true;
  bool _downloading = false;
  Uint8List? _bytes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Strips Cloudinary transformations that can cause 401 (e.g. fl_attachment).
  String? get _cleanUrl {
    final url = widget.prescription.pdfUrl;
    if (url == null) return null;
    // Remove fl_attachment transformation inserted between /upload/ and version
    return url
        .replaceAll('/fl_attachment/', '/')
        .replaceAll('fl_attachment,', '')
        .replaceAll(',fl_attachment', '');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _bytes = null;
    });

    // 1. Try to download from remote URL if available
    final url = _cleanUrl;
    if (url != null && url.isNotEmpty) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          if (mounted) {
            setState(() {
              _bytes = response.bodyBytes;
              _loading = false;
            });
          }
          return;
        }
      } catch (_) {
        // fall through to local generation
      }
    }

    // 2. Always fall back to local PDF generation — works offline
    await _generateLocally();
  }

  Future<void> _generateLocally() async {
    try {
      final bytes =
          await PrescriptionService.generatePdfBytes(widget.prescription);
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _download() async {
    if (_bytes == null) return;
    setState(() => _downloading = true);
    try {
      final dir = await _getDownloadDir();
      final filename = 'prescription_${widget.prescription.id}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(_bytes!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: $filename'),
          backgroundColor: Colors.green.shade700,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(file.path),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<Directory> _getDownloadDir() async {
    if (Platform.isAndroid) {
      try {
        final external = await getExternalStorageDirectory();
        if (external != null) {
          final downloads = Directory(
              '${external.parent.parent.parent.parent.path}/Download');
          if (await downloads.exists()) return downloads;
        }
      } catch (_) {}
      return getApplicationDocumentsDirectory();
    }
    return getApplicationDocumentsDirectory();
  }

  Future<void> _print() async {
    if (_bytes == null) return;
    await Printing.layoutPdf(onLayout: (_) async => _bytes!);
  }

  Future<void> _share() async {
    if (_bytes == null) return;
    await Printing.sharePdf(
      bytes: _bytes!,
      filename: 'prescription_${widget.prescription.id}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Prescription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (!_loading && _bytes != null) ...[
            IconButton(
              tooltip: 'Print',
              onPressed: _print,
              icon: const Icon(Icons.print_rounded),
            ),
            IconButton(
              tooltip: 'Share',
              onPressed: _share,
              icon: const Icon(Icons.share_rounded),
            ),
            _downloading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Download',
                    onPressed: _download,
                    icon: const Icon(Icons.download_rounded),
                  ),
          ],
          if (_error != null)
            IconButton(
              tooltip: 'Retry',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bytes == null
              ? _buildError()
              : PdfPreview(
                  build: (_) async => _bytes!,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  pdfFileName: 'prescription_${widget.prescription.id}.pdf',
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Could not load prescription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
