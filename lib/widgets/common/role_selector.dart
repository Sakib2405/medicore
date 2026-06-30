import 'package:flutter/material.dart';

// Define an enum for your roles
enum AppRole { patient, admin }

class RoleSelector extends StatelessWidget {
  final AppRole selectedRole;
  final Function(AppRole) onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppRole>(
      segments: const [
        ButtonSegment(
          value: AppRole.patient,
          label: Text('Patient'),
          icon: Icon(Icons.person_outline),
        ),
        ButtonSegment(
          value: AppRole.admin,
          label: Text('Admin'),
          icon: Icon(Icons.admin_panel_settings_outlined),
        ),
      ],
      selected: {selectedRole},
      onSelectionChanged: (Set<AppRole> newSelection) {
        onRoleChanged(newSelection.first);
      },
    );
  }
}
