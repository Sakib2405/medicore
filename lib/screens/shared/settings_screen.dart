// ignore_for_file: no_leading_underscores_for_local_identifiers, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    void _logout() async {
      try {
        await authProvider.signOut();
        // Navigate to the patient login screen, clearing all previous routes
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.login,
          (route) => false,
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    void _showThemeDialog(BuildContext context) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Theme'),
            content: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThemeOption(
                      context,
                      themeProvider,
                      ThemeMode.system,
                      Icons.settings,
                      'System Default',
                      'Follow device theme',
                    ),
                    const SizedBox(height: 12),
                    _buildThemeOption(
                      context,
                      themeProvider,
                      ThemeMode.light,
                      Icons.light_mode,
                      'Light Mode',
                      'Always use light theme',
                    ),
                    const SizedBox(height: 12),
                    _buildThemeOption(
                      context,
                      themeProvider,
                      ThemeMode.dark,
                      Icons.dark_mode,
                      'Dark Mode',
                      'Always use dark theme',
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Settings',
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
        child: Column(
          children: [
            // Profile Section
            _buildSectionHeader('Account'),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.editProfile);
                  },
                ),
                _buildSettingsItem(
                  context: context,
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.changePassword);
                  },
                ),
              ],
            ),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  context: context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    Navigator.pushNamed(context, Routes.notifications);
                  },
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildSettingsItem(
                      context: context,
                      icon: Icons.palette_outlined,
                      title: 'Theme',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getThemeModeText(themeProvider.themeMode),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                      onTap: () {
                        _showThemeDialog(context);
                      },
                    );
                  },
                ),
              ],
            ),

            // Support Section
            _buildSectionHeader('Support'),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    _showHelpSupportDialog(context);
                  },
                ),
                _buildSettingsItem(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  title: 'About App',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),

            // Legal Section
            _buildSectionHeader('Legal'),
            _buildSettingsCard(
              children: [
                _buildSettingsItem(
                  context: context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    _showPrivacyPolicyDialog(context);
                  },
                ),
                _buildSettingsItem(
                  context: context,
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    _showTermsDialog(context);
                  },
                ),
              ],
            ),

            // Logout Section
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                  onTap: _logout,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            // Version Info
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'MediCore v1.0.0',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Health Companion',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                ],
              ),
            ),
          ),
        ),
        if (trailing == null) // Only show divider if it's not the last item
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),
          ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemeMode mode,
    IconData icon,
    String title,
    String description,
  ) {
    final isSelected = themeProvider.themeMode == mode;

    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(title),
        subtitle: Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: () {
          themeProvider.setThemeMode(mode);
          Navigator.pop(context);
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About MediCore'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MediCore - Your Health Companion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A comprehensive healthcare app providing AI-powered health insights, '
                  'doctor appointments, and medicine delivery services.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Features:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                _buildFeatureItem('AI Symptom Checker'),
                _buildFeatureItem('Doctor Appointments'),
                _buildFeatureItem('Medicine Store'),
                _buildFeatureItem('Health Insights'),
                _buildFeatureItem('Chat Support'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need help? Contact our support team:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildContactItem(Icons.email_rounded, 'support@medicore.com'),
              _buildContactItem(Icons.phone_rounded, '+1 (555) 123-4567'),
              _buildContactItem(Icons.access_time_rounded, '24/7 Available'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SingleChildScrollView(
            child: Text(
              'Your privacy is important to us. This Privacy Policy explains how MediCore collects, uses, and protects your personal information when you use our app.\n\n'
              'We collect information to provide and improve our services, including appointment scheduling, medical records management, and personalized health insights.\n\n'
              'All data is encrypted and stored securely. We never share your personal health information with third parties without your explicit consent.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: SingleChildScrollView(
            child: Text(
              'By using MediCore, you agree to these terms:\n\n'
              '1. The app provides health information and should not replace professional medical advice.\n'
              '2. You are responsible for the accuracy of information you provide.\n'
              '3. We reserve the right to modify these terms at any time.\n'
              '4. The service is provided "as is" without warranties.\n\n'
              'Please consult healthcare professionals for medical diagnoses and treatment.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Text(feature),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
