import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/widgets/common/logo_widget.dart';
import 'package:provider/provider.dart';

class DoctorApprovalPendingScreen extends StatelessWidget {
  const DoctorApprovalPendingScreen({super.key});

  Future<void> _checkApproval(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
    // Show loading indicator
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking approval status...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    
    await authProvider.reloadUser();

    if (!context.mounted) return;

    final user = authProvider.currentUser;
    
    // Check if user is verified (approved by admin)
    if (user != null && user.isUserVerified) {
      // Navigate to doctor home
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.doctorHome,
        (route) => false,
      );
      return;
    }

    // Check if user's verification status is still pending
    if (user != null && user.verificationStatus == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account is still pending admin approval.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // If verification status is rejected or something else
    if (user != null && user.verificationStatus == 'rejected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account has been rejected. Please contact support.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Default message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to verify approval status. Please try again later.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    
    // Show loading indicator
    if (!context.mounted) return;
    
    await authProvider.signOut();
    
    if (!context.mounted) return;
    
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.doctorLogin,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final email = currentUser?.email ??
        fb_auth.FirebaseAuth.instance.currentUser?.email ??
        '';
    
    // Get verification status with fallback
    final verificationStatus = currentUser?.verificationStatus ?? 'pending';
    final isRejected = verificationStatus == 'rejected';
    final isPending = verificationStatus == 'pending';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.teal.shade900,
              Colors.blueGrey.shade900,
              Colors.teal.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(height: 96, width: 96),
                        const SizedBox(height: 20),
                        
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isRejected 
                                ? Colors.red.shade50 
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isRejected 
                                  ? Colors.red.shade200 
                                  : Colors.orange.shade200,
                            ),
                          ),
                          child: Text(
                            isRejected 
                                ? 'Verification Rejected' 
                                : 'Pending for Verification',
                            style: TextStyle(
                              color: isRejected 
                                  ? Colors.red.shade800 
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Main message
                        Text(
                          isRejected
                              ? 'Your doctor account application has been rejected.'
                              : 'Your doctor account has been submitted and is waiting for admin approval.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.4,
                            fontSize: 15,
                          ),
                        ),
                        
                        if (isRejected) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Please contact support for more information or to reapply.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              height: 1.4,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // Email display
                        if (email.isNotEmpty)
                          Text(
                            email,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.teal.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 20),
                        
                        // Information card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRejected 
                                ? Colors.red.shade50 
                                : Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isRejected 
                                  ? Colors.red.shade100 
                                  : Colors.teal.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRejected ? 'What you can do' : 'What happens next',
                                style: TextStyle(
                                  color: isRejected 
                                      ? Colors.red.shade900 
                                      : Colors.teal.shade900,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (isRejected) ...[
                                _buildStep(
                                  '1',
                                  'Contact admin support to understand the rejection reason.',
                                  isRejected: true,
                                ),
                                const SizedBox(height: 10),
                                _buildStep(
                                  '2',
                                  'Update your profile information if needed.',
                                  isRejected: true,
                                ),
                                const SizedBox(height: 10),
                                _buildStep(
                                  '3',
                                  'Submit a new application after making necessary changes.',
                                  isRejected: true,
                                ),
                              ] else ...[
                                _buildStep(
                                  '1',
                                  'Admin will review your profile details and license information.',
                                  isRejected: false,
                                ),
                                const SizedBox(height: 10),
                                _buildStep(
                                  '2',
                                  'You will receive an email notification after approval.',
                                  isRejected: false,
                                ),
                                const SizedBox(height: 10),
                                _buildStep(
                                  '3',
                                  'Once approved, you can sign in and access the doctor dashboard.',
                                  isRejected: false,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Check approval button (only if pending)
                        if (isPending) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _checkApproval(context),
                              icon: authProvider.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded),
                              label: authProvider.isLoading
                                  ? const Text('Checking...')
                                  : const Text('Check Approval Status'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade800,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 12),
                        
                        // Sign out button
                        TextButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _signOut(context),
                          child: Text(
                            isRejected ? 'Sign Out' : 'Sign out',
                            style: TextStyle(
                              color: isRejected 
                                  ? Colors.red.shade700 
                                  : Colors.teal.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String step, String text, {bool isRejected = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isRejected ? Colors.red.shade800 : Colors.teal.shade800,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isRejected ? Colors.red.shade700 : Colors.grey.shade700,
              height: 1.4,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}