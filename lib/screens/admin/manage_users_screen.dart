// screens/admin/manage_users_screen.dart
// ignore_for_file: deprecated_member_use, unnecessary_brace_in_string_interps, use_build_context_synchronously, unused_element

import 'package:flutter/material.dart';
import 'package:medicore/services/user_service.dart';
import 'package:medicore/widgets/admin/user_card.dart';
import 'package:medicore/models/user.dart';
import 'package:medicore/widgets/image_upload_dialog.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final UserService _userService = UserService();
  String _searchQuery = '';
  String _selectedRole = 'all';
  String _selectedStatus = 'all';

  final List<String> _roles = ['all', 'patient', 'doctor', 'admin'];
  final List<String> _statuses = [
    'all',
    'active',
    'inactive',
    'verified',
    'unverified'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildFilterSection(),

          // Users List
          Expanded(
            child: StreamBuilder<List<User>>(
              stream: _getFilteredUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final users = snapshot.data!;

                return _buildUsersList(users);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users by name, email, or phone...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.blue[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Filters Row
          Row(
            children: [
              // Role Filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      labelStyle: TextStyle(color: Colors.blue[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    dropdownColor: Colors.white,
                    items: _roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(
                          role == 'all' ? 'All Roles' : _capitalize(role),
                          style: TextStyle(
                            color: Colors.grey[800],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Status Filter
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      labelStyle: TextStyle(color: Colors.blue[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    dropdownColor: Colors.white,
                    items: _statuses.map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          status == 'all' ? 'All Status' : _capitalize(status),
                          style: TextStyle(
                            color: Colors.grey[800],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading Users...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 64),
          const SizedBox(height: 16),
          Text(
            'Error loading users',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              error,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, color: Colors.grey[400], size: 80),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateMessage(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty ||
              _selectedRole != 'all' ||
              _selectedStatus != 'all')
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedRole = 'all';
                  _selectedStatus = 'all';
                });
              },
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  Widget _buildUsersList(List<User> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: UserCard(
            user: user,
            onTap: () => _viewUserDetails(user),
            onEdit: () => _editUser(user),
            onDelete: () => _deleteUser(user),
            onImageEdit: () => _editProfilePicture(user),
            onVerify: user.isVerified ? null : () => _verifyUser(user),
            onActivate: user.isActive ? null : () => _activateUser(user),
          ),
        );
      },
    );
  }

  Future<void> _verifyUser(User user) async {
    try {
      final updated =
          user.copyWith(isVerified: true, verificationStatus: 'verified');
      await _userService.updateUser(updated);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} verified'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to verify ${user.name}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _activateUser(User user) async {
    try {
      final updated = user.copyWith(isActive: true);
      await _userService.updateUser(updated);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} activated'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to activate ${user.name}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Stream<List<User>> _getFilteredUsersStream() {
    Stream<List<User>> baseStream;

    if (_selectedRole != 'all') {
      baseStream = _userService.getUsersByRole(_selectedRole);
    } else {
      baseStream = _userService.getUsers();
    }

    if (_searchQuery.isEmpty && _selectedStatus == 'all') {
      return baseStream;
    }

    return baseStream.map((users) {
      return users.where((user) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.phone.contains(_searchQuery);

        // Status filter
        final matchesStatus = _selectedStatus == 'all' ||
            (_selectedStatus == 'active' && user.isActive) ||
            (_selectedStatus == 'inactive' && !user.isActive) ||
            (_selectedStatus == 'verified' && user.isUserVerified) ||
            (_selectedStatus == 'unverified' && !user.isUserVerified);

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  String _getEmptyStateMessage() {
    if (_searchQuery.isNotEmpty) {
      return 'No users found for "$_searchQuery"';
    }
    if (_selectedRole != 'all') {
      return 'No ${_selectedRole}s found';
    }
    if (_selectedStatus != 'all') {
      return 'No ${_selectedStatus} users found';
    }
    return 'No users found';
  }

  void _viewUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (MediaQuery.of(context).size.width - 32) < 680
                ? (MediaQuery.of(context).size.width - 32)
                : 680,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: user.displayPhoto.isNotEmpty
                            ? NetworkImage(user.displayPhoto)
                            : const AssetImage(
                                    'assets/images/default_avatar.png')
                                as ImageProvider,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.roleDisplay,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(Icons.email, 'Email', user.email),
                      _buildDetailItem(Icons.phone, 'Phone', user.phone),
                      _buildDetailItem(
                          Icons.person, 'Display Name', user.displayName),
                      _buildDetailItem(Icons.cake, 'Age', '${user.age} years'),
                      _buildDetailItem(
                        Icons.verified,
                        'Verification',
                        user.isUserVerified ? 'Verified' : 'Not Verified',
                        color:
                            user.isUserVerified ? Colors.green : Colors.orange,
                      ),
                      _buildDetailItem(
                        Icons.circle,
                        'Status',
                        user.statusDisplay,
                        color: user.statusColor,
                      ),
                      if (user.isDoctor && user.specialization != null)
                        _buildDetailItem(Icons.medical_services,
                            'Specialization', user.specialization!),
                      if (user.address != null)
                        _buildDetailItem(
                            Icons.location_on, 'Address', user.address!),
                      if (user.isDoctor && user.consultationFee != null)
                        _buildDetailItem(Icons.attach_money, 'Consultation Fee',
                            user.formattedConsultationFee),
                      if (user.isDoctor && user.experienceYears != null)
                        _buildDetailItem(
                            Icons.work, 'Experience', user.experienceDisplay),
                      if (user.rating != null)
                        _buildDetailItem(
                            Icons.star, 'Rating', user.ratingDisplay),
                      _buildDetailItem(Icons.calendar_today, 'Date of Birth',
                          user.formattedDateOfBirth),
                      _buildDetailItem(Icons.calendar_today, 'Joined',
                          user.formattedJoinDate),
                      _buildDetailItem(Icons.access_time, 'Last Login',
                          user.lastLoginDisplay),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _editUser(user);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value,
      {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editUser(User user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    final addressController = TextEditingController(text: user.address ?? '');
    final specializationController =
        TextEditingController(text: user.specialization ?? '');
    final licenseController =
        TextEditingController(text: user.licenseNumber ?? '');
    final clinicNameController =
        TextEditingController(text: user.clinicName ?? '');
    final clinicAddressController =
        TextEditingController(text: user.clinicAddress ?? '');
    final consultationFeeController =
        TextEditingController(text: user.consultationFee?.toString() ?? '');
    final experienceController =
        TextEditingController(text: user.experienceYears?.toString() ?? '');

    String selectedRole = user.role;
    String selectedGender = user.gender;
    bool isActive = user.isActive;
    bool isVerified = user.isVerified;
    String verificationStatus = user.verificationStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (MediaQuery.of(context).size.width - 32) < 720
                ? (MediaQuery.of(context).size.width - 32)
                : 720,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: user.displayPhoto.isNotEmpty
                            ? NetworkImage(user.displayPhoto)
                            : const AssetImage(
                                    'assets/images/default_avatar.png')
                                as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _editProfilePicture(user),
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        tooltip: 'Change Profile Picture',
                      ),
                    ],
                  ),
                ),

                // Form
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildFormField(
                        controller: nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: emailController,
                        label: 'Email',
                        icon: Icons.email,
                        isRequired: true,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: phoneController,
                        label: 'Phone',
                        icon: Icons.phone,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Role and Gender (responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 520;
                          if (isNarrow) {
                            return Column(
                              children: [
                                _buildDropdownField(
                                  value: selectedRole,
                                  label: 'Role',
                                  items: ['patient', 'doctor', 'admin'],
                                  onChanged: (value) =>
                                      setDialogState(() => selectedRole = value!),
                                ),
                                const SizedBox(height: 12),
                                _buildDropdownField(
                                  value: selectedGender,
                                  label: 'Gender',
                                  items: [
                                    'male',
                                    'female',
                                    'prefer-not-to-say'
                                  ],
                                  onChanged: (value) =>
                                      setDialogState(() => selectedGender = value!),
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  value: selectedRole,
                                  label: 'Role',
                                  items: ['patient', 'doctor', 'admin'],
                                  onChanged: (value) =>
                                      setDialogState(() => selectedRole = value!),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  value: selectedGender,
                                  label: 'Gender',
                                  items: [
                                    'male',
                                    'female',
                                    'prefer-not-to-say'
                                  ],
                                  onChanged: (value) =>
                                      setDialogState(() => selectedGender = value!),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildFormField(
                        controller: addressController,
                        label: 'Address',
                        icon: Icons.location_on,
                        maxLines: 2,
                      ),

                      if (selectedRole == 'doctor') ...[
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: specializationController,
                          label: 'Specialization',
                          icon: Icons.medical_services,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: licenseController,
                          label: 'License Number',
                          icon: Icons.badge,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: clinicNameController,
                          label: 'Clinic Name',
                          icon: Icons.business,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: clinicAddressController,
                          label: 'Clinic Address',
                          icon: Icons.location_city,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                controller: consultationFeeController,
                                label: 'Consultation Fee',
                                icon: Icons.attach_money,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildFormField(
                                controller: experienceController,
                                label: 'Experience (Years)',
                                icon: Icons.work,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Verification Status
                      _buildDropdownField(
                        value: verificationStatus,
                        label: 'Verification Status',
                        items: ['pending', 'verified', 'rejected'],
                        onChanged: (value) =>
                            setDialogState(() => verificationStatus = value!),
                      ),

                      const SizedBox(height: 16),

                      // Toggle Switches
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleSwitch(
                              value: isActive,
                              onChanged: (value) =>
                                  setDialogState(() => isActive = value),
                              label: 'Active',
                              activeColor: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildToggleSwitch(
                              value: isVerified,
                              onChanged: (value) =>
                                  setDialogState(() => isVerified = value),
                              label: 'Verified',
                              activeColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final updatedUser = user.copyWith(
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              phone: phoneController.text.trim(),
                              role: selectedRole,
                              gender: selectedGender,
                              address: addressController.text.trim().isEmpty
                                  ? null
                                  : addressController.text.trim(),
                              isActive: isActive,
                              isVerified: isVerified,
                              verificationStatus: verificationStatus,
                              specialization:
                                  specializationController.text.trim().isEmpty
                                      ? null
                                      : specializationController.text.trim(),
                              licenseNumber:
                                  licenseController.text.trim().isEmpty
                                      ? null
                                      : licenseController.text.trim(),
                              clinicName:
                                  clinicNameController.text.trim().isEmpty
                                      ? null
                                      : clinicNameController.text.trim(),
                              clinicAddress:
                                  clinicAddressController.text.trim().isEmpty
                                      ? null
                                      : clinicAddressController.text.trim(),
                              consultationFee:
                                  consultationFeeController.text.trim().isEmpty
                                      ? null
                                      : double.tryParse(
                                          consultationFeeController.text),
                              experienceYears:
                                  experienceController.text.trim().isEmpty
                                      ? null
                                      : int.tryParse(experienceController.text),
                            );

                            try {
                              await _userService.updateUser(updatedUser);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('${user.name} updated successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to update user: $e'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          prefixIcon: Icon(icon, color: Colors.blue[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          prefixIcon: Icon(Icons.category, color: Colors.blue[700]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(_capitalize(item)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggleSwitch({
    required bool value,
    required Function(bool) onChanged,
    required String label,
    required Color activeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
          ),
        ],
      ),
    );
  }

  void _editProfilePicture(User user) {
    showDialog(
      context: context,
      builder: (context) => ImageUploadDialog(
        title: 'Update Profile Picture',
        currentImageUrl: user.displayPhoto,
        onImageSelected: (imageUrl) async {
          try {
            final updatedUser = user.copyWith(
              profileImage: imageUrl.isEmpty ? null : imageUrl,
            );
            await _userService.updateUser(updatedUser);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(imageUrl.isEmpty
                    ? 'Profile picture removed'
                    : 'Profile picture updated successfully'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update profile picture: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        useCloudinary: true,
        cloudinaryKind: 'profile',
      ),
    );
  }

  void _deleteUser(User user) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[400],
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Delete User?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete ${user.name}? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await _userService.deleteUser(user.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${user.name} deleted successfully'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Failed to delete ${user.name}: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

