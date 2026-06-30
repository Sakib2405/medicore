// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/services/cloudinary_upload_service.dart';
import 'package:medicore/models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late final AnimationController _controller;
  bool _isUploading = false;

  static const _gradientColors = [Color(0xFF667eea), Color(0xFF764ba2)];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return CustomScrollView(
            slivers: [
              _buildSliverHeader(user, authProvider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatsSection(user),
                      const SizedBox(height: 20),
                      _buildPersonalInfoSection(user),
                      const SizedBox(height: 16),
                      _buildMedicalInfoSection(user),
                      const SizedBox(height: 16),
                      _buildQuickActionsSection(),
                      const SizedBox(height: 16),
                      _buildMoreOptionsSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditProfileDialog(context),
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  // ────────────────── SliverAppBar ──────────────────
  Widget _buildSliverHeader(User user, AuthProvider authProvider) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: _gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Photo
                GestureDetector(
                  onTap: () => _showImageSourceDialog(),
                  child: Stack(
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.8, end: 1.0)
                            .animate(_controller),
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _isUploading
                                ? Container(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  )
                                : _getProfileImageWidget(user),
                          ),
                        ),
                      ),
                      if (!_isUploading)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Tap to change photo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Builder(
          builder: (context) {
            final settings = context.dependOnInheritedWidgetOfExactType<
                FlexibleSpaceBarSettings>();
            if (settings == null) return const SizedBox();
            final isCollapsed = settings.currentExtent <= settings.minExtent + 10;
            return AnimatedOpacity(
              opacity: isCollapsed ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pushNamed(context, Routes.settings),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ────────────────── Stats Section ──────────────────
  Widget _buildStatsSection(User user) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '${user.appointmentCount ?? 0}',
            label: 'Appointments',
            icon: Icons.calendar_today_rounded,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${user.orderCount ?? 0}',
            label: 'Orders',
            icon: Icons.shopping_bag_rounded,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            value: '${user.medicalRecordCount ?? 0}',
            label: 'Records',
            icon: Icons.medical_information_rounded,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  // ────────────────── Personal Info Section ──────────────────
  Widget _buildPersonalInfoSection(User user) {
    return _InfoSection(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      color: Colors.blue,
      items: [
        _InfoItem(
          label: 'Full Name',
          value: user.name,
          icon: Icons.person_rounded,
          onEdit: () => _editField(context, 'Full Name', user.name, 'name'),
        ),
        _InfoItem(
          label: 'Email',
          value: user.email,
          icon: Icons.email_rounded,
          onEdit: () => _editField(context, 'Email', user.email, 'email'),
        ),
        _InfoItem(
          label: 'Phone',
          value: user.phone,
          icon: Icons.phone_rounded,
          onEdit: () => _editField(context, 'Phone', user.phone, 'phone',
              keyboardType: TextInputType.phone),
        ),
        _InfoItem(
          label: 'Age',
          value: user.age > 0 ? '${user.age} years' : 'Not set',
          icon: Icons.cake_rounded,
          onEdit: () => _editField(context, 'Age',
              user.age > 0 ? user.age.toString() : '', 'age',
              keyboardType: TextInputType.number),
        ),
        _InfoItem(
          label: 'Gender',
          value: _formatGender(user.gender),
          icon: Icons.transgender_rounded,
          onEdit: () => _editGender(context, user.gender),
        ),
      ],
    );
  }

  // ────────────────── Medical Info Section ──────────────────
  Widget _buildMedicalInfoSection(User user) {
    final health = user.healthProfile ?? {};
    return _InfoSection(
      title: 'Medical Information',
      icon: Icons.medical_services_outlined,
      color: Colors.green,
      items: [
        _InfoItem(
          label: 'Blood Group',
          value: (health['bloodGroup'] as String?)?.toUpperCase() ?? 'Not set',
          icon: Icons.bloodtype_rounded,
          onEdit: () =>
              _editBloodGroup(context, health['bloodGroup'] as String?),
        ),
        _InfoItem(
          label: 'Height',
          value: health['height'] != null ? '${health['height']} cm' : 'Not set',
          icon: Icons.height_rounded,
          onEdit: () => _editField(context, 'Height',
              health['height']?.toString() ?? '', 'height',
              keyboardType: TextInputType.number),
        ),
        _InfoItem(
          label: 'Weight',
          value: health['weight'] != null ? '${health['weight']} kg' : 'Not set',
          icon: Icons.monitor_weight_rounded,
          onEdit: () => _editField(context, 'Weight',
              health['weight']?.toString() ?? '', 'weight',
              keyboardType: TextInputType.number),
        ),
        _InfoItem(
          label: 'Allergies',
          value: health['allergies'] as String? ?? 'Not set',
          icon: Icons.warning_rounded,
          onEdit: () => _editField(context, 'Allergies',
              health['allergies'] as String? ?? '', 'allergies'),
        ),
      ],
    );
  }

  // ────────────────── Quick Actions ──────────────────
  Widget _buildQuickActionsSection() {
    return _ActionSection(
      title: 'Quick Actions',
      icon: Icons.flash_on_rounded,
      color: Colors.orange,
      actions: [
        _ActionItem(
          title: 'My Appointments',
          icon: Icons.calendar_today_rounded,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, Routes.myAppointments),
        ),
        _ActionItem(
          title: 'My Orders',
          icon: Icons.shopping_bag_rounded,
          color: Colors.purple,
          onTap: () => Navigator.pushNamed(context, Routes.myOrders),
        ),
        _ActionItem(
          title: 'Medical Records',
          icon: Icons.medical_information_rounded,
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, Routes.medicalRecords),
        ),
        _ActionItem(
          title: 'Change Password',
          icon: Icons.lock_outline_rounded,
          color: Colors.red,
          onTap: () => _showChangePasswordDialog(context),
        ),
      ],
    );
  }

  // ────────────────── More Options ──────────────────
  Widget _buildMoreOptionsSection() {
    return _ActionSection(
      title: 'More',
      icon: Icons.more_horiz_rounded,
      color: Colors.grey,
      actions: [
        _ActionItem(
          title: 'Settings',
          icon: Icons.settings_rounded,
          color: Colors.grey,
          onTap: () => Navigator.pushNamed(context, Routes.settings),
        ),
        _ActionItem(
          title: 'Help & Support',
          icon: Icons.support_agent_rounded,
          color: Colors.blue,
          onTap: () => _showHelpDialog(context),
        ),
        _ActionItem(
          title: 'About App',
          icon: Icons.info_outline_rounded,
          color: Colors.teal,
          onTap: () => _showAboutDialog(context),
        ),
        _ActionItem(
          title: 'Log Out',
          icon: Icons.logout_rounded,
          color: Colors.red.shade600,
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Log Out?'),
                content: const Text('Are you sure you want to log out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            );
            if (confirmed ?? false) {
              await context.read<AuthProvider>().signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  Routes.login,
                  (route) => false,
                );
              }
            }
          },
        ),
      ],
    );
  }

  // ────────────────── Helper Methods ──────────────────

  Widget _getProfileImageWidget(User? user) {
    final profileImage = user?.photoUrl ?? user?.profileImage;
    if (profileImage != null && profileImage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: profileImage,
        fit: BoxFit.cover,
        placeholder: (_, __) => Center(
          child: CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.8)),
            strokeWidth: 2,
          ),
        ),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: Icon(
        Icons.person_rounded,
        size: 55,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (mounted) Navigator.pop(context);
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );
      if (image != null) {
        await _uploadImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);
    try {
      final url =
          await CloudinaryUploadService.uploadProfileImageFile(imageFile);
      final auth = context.read<AuthProvider>();
      final success = await auth.updateProfileImage(url);
      if (success && mounted) {
        _showSuccessSnackBar('Profile photo updated! 📸');
      } else if (mounted) {
        _showErrorSnackBar('Failed to update profile photo');
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Upload error: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Change Profile Picture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.blue),
              title: const Text('Photo Gallery'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
              title: const Text('Camera'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _editField(
    BuildContext context,
    String label,
    String current,
    String field, {
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: current);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.number
              ? [FilteringTextInputFormatter.digitsOnly]
              : [],
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = controller.text.trim();
              if (value.isEmpty) {
                _showErrorSnackBar('Cannot be empty');
                return;
              }
              final auth = context.read<AuthProvider>();
              final updateData = {field: value};
              final success = await auth.updateProfile(updateData);
              if (success && mounted) {
                _showSuccessSnackBar('$label updated! ✓');
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editGender(BuildContext context, String? current) async {
    final options = ['Male', 'Female', 'Other', 'Prefer not to say'];
    String? selected = current;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((option) {
                  final value = option.toLowerCase().replaceAll(' ', '-');
                  final isSelected = selected == value;
                  return InkWell(
                    onTap: () => setState(() => selected = value),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF667eea)
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? Center(
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF667eea),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(option),
                        ],
                      ),
                    ),
                  );
                })
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((value) async {
      if (value != null && value != current) {
        final auth = context.read<AuthProvider>();
        final success = await auth.updateProfile({'gender': value});
        if (success && mounted) {
          _showSuccessSnackBar('Gender updated! ✓');
        }
      }
    });
  }

  Future<void> _editBloodGroup(BuildContext context, String? current) async {
    const groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Blood Group',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: groups
                  .map((g) => ChoiceChip(
                        label: Text(g),
                        selected: current == g,
                        onSelected: (selected) {
                          Navigator.pop(ctx);
                          if (selected) {
                            context
                                .read<AuthProvider>()
                                .updateHealthProfile({'bloodGroup': g});
                            _showSuccessSnackBar('Blood group updated! ✓');
                          }
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final current = TextEditingController();
    final newPass = TextEditingController();
    final confirm = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPass.text != confirm.text) {
                _showErrorSnackBar('Passwords do not match');
                return;
              }
              if (newPass.text.length < 6) {
                _showErrorSnackBar('Password must be at least 6 characters');
                return;
              }
              final success = await context.read<AuthProvider>().changePassword(
                    current.text,
                    newPass.text,
                  );
              if (success && mounted) {
                _showSuccessSnackBar('Password changed! 🔒');
                Navigator.pop(ctx);
              } else if (mounted) {
                _showErrorSnackBar('Failed to change password');
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    final name = TextEditingController(text: user.name);
    final phone = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quick Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updates = <String, dynamic>{};
              if (name.text.trim().isNotEmpty) updates['name'] = name.text.trim();
              if (phone.text.trim().isNotEmpty) updates['phone'] = phone.text.trim();

              if (updates.isNotEmpty) {
                final success = await auth.updateProfile(updates);
                if (success && mounted) {
                  _showSuccessSnackBar('Profile updated! ✓');
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 support@medicore.com'),
            SizedBox(height: 12),
            Text('📞 +1 (555) 123-HELP'),
            SizedBox(height: 12),
            Text('⏰ 24/7 Available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About MediCore'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your comprehensive healthcare companion',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text(
                  'MediCore provides AI-powered health insights, doctor appointments, medicine delivery, and personalized health management.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == null) return 'Not set';
    return gender[0].toUpperCase() + gender.substring(1).replaceAll('-', ' ');
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ════════════════════ UI Components ════════════════════

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_InfoItem> items;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...items.map((item) => _buildInfoItemWidget(item)),
        ],
      ),
    );
  }

  Widget _buildInfoItemWidget(_InfoItem item) {
    return InkWell(
      onTap: item.onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, size: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_rounded, size: 18, color: Colors.blue.shade600),
          ],
        ),
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onEdit;

  _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.onEdit,
  });
}

class _ActionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<_ActionItem> actions;

  const _ActionSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...actions.map((action) => _buildActionItemWidget(action)),
        ],
      ),
    );
  }

  Widget _buildActionItemWidget(_ActionItem action) {
    return InkWell(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, size: 20, color: action.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _ActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
