// ignore_for_file: unused_import, deprecated_member_use, depend_on_referenced_packages, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/services/cloudinary_upload_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _feeController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _experienceController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _bioController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _isLoading = false;
  bool _uploadingPhoto = false;
  String? _selectedGender;
  File? _pickedImage;
  String? _currentPhotoUrl;

  static const List<String> _weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  // ignore: prefer_final_fields
  Map<String, String> _workingHours = {
    'Monday': '9:00 AM - 5:00 PM',
    'Tuesday': '9:00 AM - 5:00 PM',
    'Wednesday': '9:00 AM - 5:00 PM',
    'Thursday': '9:00 AM - 5:00 PM',
    'Friday': '9:00 AM - 5:00 PM',
    'Saturday': '9:00 AM - 1:00 PM',
    'Sunday': 'Closed',
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _ageController.text = user.age > 0 ? user.age.toString() : '';
      _selectedGender = user.gender;
      _currentPhotoUrl = user.photoUrl ?? user.profileImage;
      if (user.consultationFee != null) {
        _feeController.text = user.consultationFee!.toStringAsFixed(0);
      }
      if (user.isDoctor) {
        _specialtyController.text = user.specialization ?? '';
        _experienceController.text = user.experienceYears?.toString() ?? '';
        _clinicNameController.text = user.clinicName ?? '';
        _clinicAddressController.text = user.clinicAddress ?? '';
        _bioController.text = user.professionalInfo?['bio']?.toString() ?? '';
        _licenseController.text = user.licenseNumber ?? '';
        final storedHours = user.professionalInfo?['workingHours'];
        if (storedHours is Map) {
          _workingHours = Map<String, String>.from(storedHours);
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  Future<String?> _uploadImageIfNeeded() async {
    if (_pickedImage == null) return null;
    setState(() => _uploadingPhoto = true);
    try {
      final url =
          await CloudinaryUploadService.uploadProfileImageFile(_pickedImage!);
      return url;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Upload new photo if one was picked
        final newPhotoUrl = await _uploadImageIfNeeded();

        // Prepare update data
        final updates = <String, dynamic>{
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
        };

        // Add age if provided
        if (_ageController.text.trim().isNotEmpty) {
          updates['age'] = int.tryParse(_ageController.text.trim());
        }

        // Add gender if selected
        if (_selectedGender != null && _selectedGender!.isNotEmpty) {
          updates['gender'] = _selectedGender;
        }

        // Add photo URL if uploaded
        if (newPhotoUrl != null) {
          updates['profileImage'] = newPhotoUrl;
          updates['photoUrl'] = newPhotoUrl;
        }

        // Add doctor-specific fields
        final user = authProvider.currentUser;
        if (user?.role == 'doctor') {
          if (_feeController.text.trim().isNotEmpty) {
            final fee = double.tryParse(_feeController.text.trim());
            if (fee != null) updates['consultationFee'] = fee;
          }
          updates['specialization'] = _specialtyController.text.trim();
          if (_experienceController.text.trim().isNotEmpty) {
            final exp = int.tryParse(_experienceController.text.trim());
            if (exp != null) updates['experienceYears'] = exp;
          }
          updates['clinicName'] = _clinicNameController.text.trim();
          updates['clinicAddress'] = _clinicAddressController.text.trim();
          updates['licenseNumber'] = _licenseController.text.trim();
          updates['professionalInfo'] = {
            'bio': _bioController.text.trim(),
            'workingHours': _workingHours,
          };
        }

        final success = await authProvider.updateProfile(updates);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile updated successfully!'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${authProvider.error}'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $error'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _editWorkingHours(String day) {
    final controller = TextEditingController(text: _workingHours[day] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hours for $day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'e.g. 9:00 AM - 5:00 PM or Closed',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('9 AM - 5 PM'),
                  onPressed: () {
                    controller.text = '9:00 AM - 5:00 PM';
                  },
                ),
                ActionChip(
                  label: const Text('Closed'),
                  onPressed: () {
                    controller.text = 'Closed';
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _workingHours[day] = controller.text.trim().isEmpty
                    ? 'Closed'
                    : controller.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showGenderSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildGenderOption('Male', 'male'),
            _buildGenderOption('Female', 'female'),
            _buildGenderOption('Other', 'other'),
            _buildGenderOption('Prefer not to say', 'prefer-not-to-say'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String label, String value) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: _selectedGender,
      onChanged: (newValue) {
        setState(() {
          _selectedGender = newValue;
        });
        Navigator.pop(context);
      },
    );
  }

  String _getGenderDisplayText() {
    switch (_selectedGender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      case 'prefer-not-to-say':
        return 'Prefer not to say';
      default:
        return 'Select Gender';
    }
  }

  Widget _buildPhotoSection(BuildContext context) {
    final photoUrl = _pickedImage != null ? null : _currentPhotoUrl;
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.blue.shade300, width: 3),
              color: Colors.grey.shade100,
            ),
            child: ClipOval(
              child: _pickedImage != null
                  ? Image.file(_pickedImage!, fit: BoxFit.cover)
                  : (photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              color: Colors.grey.shade400,
                              size: 50))
                      : Icon(Icons.person_rounded,
                          color: Colors.grey.shade400, size: 50)),
            ),
          ),
          if (_uploadingPhoto)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x88000000)),
                child: const Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _uploadingPhoto ? null : _pickImage,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.black87,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildPhotoSection(context),
                  const SizedBox(height: 12),
                  const Text(
                    'Update Your Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the camera icon to change your photo',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Profile Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Full Name Field
                    _buildFormField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      icon: Icons.person_outline_rounded,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        if (value.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email Field (Read-only)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixIcon: Icon(
                                Icons.email_rounded,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Email cannot be changed',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Phone Field
                    _buildFormField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: 'Enter your phone number',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 10) {
                            return 'Enter a valid phone number';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Age Field
                    _buildFormField(
                      controller: _ageController,
                      label: 'Age',
                      hint: 'Enter your age',
                      icon: Icons.cake_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final age = int.tryParse(value);
                          if (age == null || age < 1 || age > 120) {
                            return 'Enter a valid age (1-120)';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Gender Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showGenderSelectionDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.transgender_rounded,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getGenderDisplayText(),
                                    style: TextStyle(
                                      color: _selectedGender != null
                                          ? Colors.black87
                                          : Colors.grey.shade500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Colors.grey.shade600,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Doctor-only fields
                    if (user?.role == 'doctor') ...[
                      const SizedBox(height: 20),
                      _buildFormField(
                        controller: _feeController,
                        label: 'Consultation Fee (BDT)',
                        hint: 'e.g. 500',
                        icon: Icons.monetization_on_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final fee = double.tryParse(value);
                            if (fee == null || fee < 0) {
                              return 'Enter a valid fee amount';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildFormField(
                        controller: _specialtyController,
                        label: 'Specialty',
                        hint: 'e.g. Cardiologist',
                        icon: Icons.local_hospital_rounded,
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 20),
                      _buildFormField(
                        controller: _experienceController,
                        label: 'Years of Experience',
                        hint: 'e.g. 10',
                        icon: Icons.work_outline_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final v = int.tryParse(value);
                            if (v == null || v < 0) return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildFormField(
                        controller: _licenseController,
                        label: 'License Number',
                        hint: 'e.g. BMDC-12345',
                        icon: Icons.badge_outlined,
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 20),
                      _buildFormField(
                        controller: _clinicNameController,
                        label: 'Clinic / Hospital Name',
                        hint: 'e.g. City Medical Center',
                        icon: Icons.business_rounded,
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 20),
                      _buildFormField(
                        controller: _clinicAddressController,
                        label: 'Clinic Address',
                        hint: 'e.g. 123 Main St, Dhaka',
                        icon: Icons.location_on_outlined,
                        validator: (_) => null,
                      ),
                      const SizedBox(height: 20),
                      // Bio
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bio / About',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: TextFormField(
                              controller: _bioController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: 'Write a short bio about yourself...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(16),
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 12, right: 8, top: 12),
                                  child: Icon(Icons.notes_rounded, color: Colors.grey.shade600, size: 20),
                                ),
                                prefixIconConstraints: const BoxConstraints(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Working Hours
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Working Hours',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              children: _weekDays.map((day) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        child: Text(
                                          day,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _editWorkingHours(day),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    _workingHours[day] ?? 'Closed',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: (_workingHours[day] == 'Closed')
                                                          ? Colors.red.shade400
                                                          : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade500),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // Profile Completion
                    if (user != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade100,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates_rounded,
                                  color: Colors.blue.shade600,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Profile Completion',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: authProvider.profileCompletionPercentage,
                              backgroundColor: Colors.blue.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(authProvider.profileCompletionPercentage * 100).toInt()}% complete',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Additional Info
                    if (user != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Information:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('User ID', user.id),
                            _buildInfoRow('Role', user.role.toUpperCase()),
                            _buildInfoRow(
                                'Member since',
                                user.createdAt != null
                                    ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                                    : 'N/A'),
                            _buildInfoRow(
                              'Email Verified',
                              user.isVerified ? 'Yes' : 'No',
                              isVerified: user.isVerified,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: Colors.grey.shade600,
                size: 20,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isVerified = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isVerified ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color:
                    isVerified ? Colors.green.shade200 : Colors.grey.shade300,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isVerified ? Colors.green.shade700 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _feeController.dispose();
    _specialtyController.dispose();
    _experienceController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _bioController.dispose();
    _licenseController.dispose();
    super.dispose();
  }
}
