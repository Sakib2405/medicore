/// Cloudinary client config for unsigned uploads (no server, no Blaze).
///
/// Steps to set up:
/// 1) Create a Cloudinary account (free).
/// 2) Create an unsigned upload preset (Settings → Upload → Upload presets → Add).
///    - Restrict allowed formats to images (jpg, png, webp) and set max file size (e.g., 5MB).
///    - Optionally set a default folder (e.g., medicore), though we also pass folder per upload.
/// 3) Fill in the values below.
class StorageConfig {
  // Your Cloud Name (from Cloudinary dashboard)
  static const String cloudName = "dnwg7lpsx";

  // Unsigned upload preset name (string) created in Cloudinary.
  static const String unsignedUploadPreset =
      "medicore"; // MUST be set to Unsigned mode in Cloudinary

  // Optional: root folder in Cloudinary to keep things organized
  static const String rootFolder = "medicore";
}
