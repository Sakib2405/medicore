// widgets/image_upload_dialog.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medicore/services/cloudinary_upload_service.dart';
import 'dart:convert';

class ImageUploadDialog extends StatefulWidget {
  final String title;
  final String? currentImageUrl;
  final Function(String) onImageSelected;
  final bool isCircular;
  final double imageSize;
  final String? removeText;
  final bool
      useCloudinary; // when true, upload to Cloudinary instead of Firebase
  final String?
      cloudinaryKind; // 'profile' | 'medicine' | 'general' | null (defaults to medicine)
  final String? cloudinaryCollection; // custom folder name for generic uploads

  const ImageUploadDialog({
    super.key,
    required this.title,
    this.currentImageUrl,
    required this.onImageSelected,
    this.isCircular = false,
    this.imageSize = 150,
    this.removeText = 'Remove Picture',
    this.useCloudinary = false,
    this.cloudinaryKind,
    this.cloudinaryCollection,
  });

  @override
  State<ImageUploadDialog> createState() => _ImageUploadDialogState();
}

class _ImageUploadDialogState extends State<ImageUploadDialog> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  String? _tempImageUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview
            Stack(
              children: [
                Container(
                  width: widget.imageSize,
                  height: widget.imageSize,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: widget.isCircular
                        ? BorderRadius.circular(widget.imageSize)
                        : BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue[300]!,
                      width: 2,
                    ),
                  ),
                  child: _buildImageContent(),
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: widget.isCircular
                            ? BorderRadius.circular(widget.imageSize)
                            : BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            // Upload Options
            Row(
              children: [
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.photo_camera,
                    label: 'Camera',
                    onTap: () => _uploadImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUploadOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _uploadImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Remove Button (only show if there's a current image)
            if (widget.currentImageUrl != null && widget.removeText != null)
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _removeImage,
                icon: const Icon(Icons.delete),
                label: Text(widget.removeText!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

            const SizedBox(height: 8),

            // Cancel Button
            TextButton(
              onPressed: _isUploading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    final imageUrl = _tempImageUrl ?? widget.currentImageUrl;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Support data URI images to avoid "No host specified" errors
      if (imageUrl.startsWith('data:image')) {
        try {
          final commaIndex = imageUrl.indexOf(',');
          if (commaIndex != -1) {
            final base64Data = imageUrl.substring(commaIndex + 1);
            final bytes = base64Decode(base64Data);
            return ClipRRect(
              borderRadius: widget.isCircular
                  ? BorderRadius.circular(widget.imageSize)
                  : BorderRadius.circular(16),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
              ),
            );
          }
        } catch (_) {
          // Fall through to placeholder on failure
        }
      }
      return ClipRRect(
        borderRadius: widget.isCircular
            ? BorderRadius.circular(widget.imageSize)
            : BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderContent();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    }

    return _buildPlaceholderContent();
  }

  Widget _buildPlaceholderContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.isCircular ? Icons.person : Icons.photo,
          color: Colors.blue[300],
          size: widget.imageSize * 0.3,
        ),
        const SizedBox(height: 8),
        Text(
          widget.isCircular ? 'Add Photo' : 'Add Image',
          style: TextStyle(
            color: Colors.blue[700],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isUploading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon,
                    color: _isUploading ? Colors.grey : Colors.blue[700],
                    size: 32),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: _isUploading ? Colors.grey : Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (image != null) {
        setState(() => _isUploading = true);
        String imageUrl;

        // Always use Cloudinary - never Firebase Storage
        final bytes = await image.readAsBytes();

        if (widget.cloudinaryKind == 'profile') {
          imageUrl =
              await CloudinaryUploadService.uploadProfileImageBytes(bytes);
        } else if (widget.cloudinaryKind == 'medicine') {
          imageUrl =
              await CloudinaryUploadService.uploadMedicineImageBytes(bytes);
        } else {
          // Generic upload to a custom collection folder
          final collection =
              widget.cloudinaryCollection ?? 'general_uploads';
          imageUrl = await CloudinaryUploadService.uploadImageBytes(
            bytes,
            collection: collection,
          );
        }

        setState(() {
          _tempImageUrl = imageUrl;
        });

        // Call the callback with the new image URL
        widget.onImageSelected(imageUrl);

        // Capture messenger before popping to avoid using a disposed context
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);

        messenger.showSnackBar(
          SnackBar(
            content: const Text('Image uploaded successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _removeImage() async {
    try {
      setState(() => _isUploading = true);

      // Call the callback with empty string to indicate removal
      widget.onImageSelected('');

      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Image removed successfully'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Failed to remove image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }
}

// Extension methods for easy usage in different contexts
extension ImageUploadDialogExtensions on ImageUploadDialog {
  // For profile pictures (circular)
  static Future<void> showProfilePictureUpload({
    required BuildContext context,
    required String title,
    required Function(String) onImageSelected,
    String? currentImageUrl,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ImageUploadDialog(
        title: title,
        currentImageUrl: currentImageUrl,
        onImageSelected: onImageSelected,
        isCircular: true,
        imageSize: 120,
        removeText: 'Remove Profile Picture',
        useCloudinary: true,
        cloudinaryKind: 'profile',
      ),
    );
  }

  // For medicine/images (rectangular)
  static Future<void> showMedicineImageUpload({
    required BuildContext context,
    required String title,
    required Function(String) onImageSelected,
    String? currentImageUrl,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ImageUploadDialog(
        title: title,
        currentImageUrl: currentImageUrl,
        onImageSelected: onImageSelected,
        isCircular: false,
        imageSize: 150,
        removeText: 'Remove Image',
        useCloudinary: true,
        cloudinaryKind: 'medicine',
      ),
    );
  }

  // Generic image upload (always uses Cloudinary)
  static Future<void> showGenericImageUpload({
    required BuildContext context,
    required String title,
    required Function(String) onImageSelected,
    String? currentImageUrl,
    bool isCircular = false,
    double imageSize = 150,
    String? removeText,
    String? cloudinaryCollection,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => ImageUploadDialog(
        title: title,
        currentImageUrl: currentImageUrl,
        onImageSelected: onImageSelected,
        isCircular: isCircular,
        imageSize: imageSize,
        removeText: removeText,
        useCloudinary: true,
        cloudinaryCollection: cloudinaryCollection ?? 'general_uploads',
      ),
    );
  }
}