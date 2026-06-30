// widgets/admin/user_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:medicore/models/user.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onVerify;
  final VoidCallback? onActivate;
  final VoidCallback? onImageEdit;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onVerify,
    this.onActivate,
    this.onImageEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // User Avatar
                  _buildUserAvatar(),
                  const SizedBox(width: 12),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildRoleAndStatus(),
                      ],
                    ),
                  ),

                  // Action Menu
                  _buildActionMenu(),
                ],
              ),

              const SizedBox(height: 12),

              // Additional Info
              _buildAdditionalInfo(),

              // Action Buttons (for mobile)
              if (onVerify != null || onActivate != null) ...[
                const SizedBox(height: 12),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue[100],
            image: user.displayPhoto.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(user.displayPhoto),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: user.displayPhoto.isEmpty
              ? Icon(
                  user.isDoctor
                      ? Icons.medical_services
                      : user.isAdmin
                          ? Icons.admin_panel_settings
                          : Icons.person,
                  color: Colors.blue,
                  size: 24,
                )
              : null,
        ),

        // Online/Offline Status
        if (user.lastLogin != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color:
                    _isUserOnline(user.lastLogin!) ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRoleAndStatus() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        // Role Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _getRoleColor(user.role),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.roleDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: user.statusColor.withOpacity(0.1),
            border: Border.all(color: user.statusColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            user.statusDisplay,
            style: TextStyle(
              color: user.statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Verification Badge
        if (user.isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.green, size: 10),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
      onSelected: (value) {
        switch (value) {
          case 'view':
            onTap();
            break;
          case 'edit':
            onEdit();
            break;
          case 'verify':
            onVerify?.call();
            break;
          case 'activate':
            onActivate?.call();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Text('View Details'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.orange),
              SizedBox(width: 8),
              Text('Edit User'),
            ],
          ),
        ),
        if (onVerify != null && !user.isVerified)
          const PopupMenuItem<String>(
            value: 'verify',
            child: Row(
              children: [
                Icon(Icons.verified, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text('Verify User'),
              ],
            ),
          ),
        if (onActivate != null && !user.isActive)
          const PopupMenuItem<String>(
            value: 'activate',
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text('Activate User'),
              ],
            ),
          ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Delete User',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone Number
        if (user.phone.isNotEmpty)
          Row(
            children: [
              Icon(Icons.phone, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                user.phone,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),

        // Specialization (for doctors)
        if (user.isDoctor && user.specialization != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.medical_services, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                user.specialization!,
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],

        // Address
        if (user.address != null && user.address!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  user.address!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],

        // Last Login
        if (user.lastLogin != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                'Last login: ${user.lastLoginDisplay}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],

        // Statistics for doctors
        if (user.isDoctor &&
            (user.rating != null || user.experienceYears != null)) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            children: [
              if (user.rating != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      user.ratingDisplay,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              if (user.experienceYears != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.work, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      user.experienceDisplay,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (onVerify != null && !user.isVerified)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onVerify,
              icon: Icon(Icons.verified, size: 16),
              label: const Text('Verify'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: BorderSide(color: Colors.green),
              ),
            ),
          ),
        if (onVerify != null && !user.isVerified) const SizedBox(width: 8),
        if (onActivate != null && !user.isActive)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onActivate,
              icon: Icon(Icons.check_circle, size: 16),
              label: const Text('Activate'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue),
              ),
            ),
          ),
      ],
    );
  }

  bool _isUserOnline(DateTime lastLogin) {
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    return difference.inMinutes <
        5; // Consider online if last login within 5 minutes
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'doctor':
        return Colors.green;
      case 'admin':
        return Colors.red;
      case 'patient':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
