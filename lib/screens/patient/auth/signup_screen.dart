// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:medicore/config/routes.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicore/models/doctor_model.dart';
import 'package:medicore/widgets/common/logo_widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showVerificationStep = false;
  bool _registerAsDoctor = false;
  final _codeController = TextEditingController();

  int _resendTimer = 0;
  Timer? _timer;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Cloud Functions not needed for link-based email verification

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['registerAsDoctor'] == true) {
      setState(() => _registerAsDoctor = true);
    }
  }

  void _startResendTimer() {
    _resendTimer = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _signupEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      User? user = cred.user;

      if (user == null) {
        throw FirebaseAuthException(code: 'user-null');
      }

      await user.updateDisplayName(_nameController.text.trim());

      setState(() {
        _showVerificationStep = true;
        _isLoading = false;
      });

      await _sendEmailVerificationLink();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String msg = 'Failed to sign up';
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Email already in use';
          break;
        case 'invalid-email':
          msg = 'Invalid email';
          break;
        case 'weak-password':
          msg = 'Weak password (Min 6 characters)';
          break;
      }
      _showError(msg);
    } catch (_) {
      setState(() => _isLoading = false);
      _showError('Failed to sign up');
    }
  }

  Future<void> _sendEmailVerificationLink() async {
    try {
      final user = _auth.currentUser;
      if (user == null || (user.email ?? '').isEmpty) {
        _showError('No user/email to verify');
        return;
      }
      await user.sendEmailVerification();
      _startResendTimer();
      _showSuccess('Verification link sent to ${user.email}');
    } catch (e) {
      _showError('Failed to send verification link');
    }
  }

  Future<void> _checkEmailVerifiedAndComplete() async {
    setState(() => _isLoading = true);
    try {
      await _auth.currentUser?.reload();
      final verified = _auth.currentUser?.emailVerified ?? false;
      if (verified) {
        await _completeSignup(isVerified: true);
      } else {
        _showError('Email not verified yet. Please check your inbox.');
        setState(() => _isLoading = false);
      }
    } catch (_) {
      _showError('Could not verify email status');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    await _sendEmailVerificationLink();
  }

  Future<void> _signupWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = kIsWeb
          ? await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn()
          : await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await _completeSignup();
    } catch (e) {
      _showError('Google sign-in failed');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSignup({bool isVerified = false}) async {
    final user = _auth.currentUser;
    if (user != null) {
      final role = _registerAsDoctor ? 'doctor' : 'patient';
      final uid = user.uid;
      final patientIdSuffix = uid.length >= 6
          ? uid.substring(0, 6).toUpperCase()
          : uid.padRight(6, '0').toUpperCase();
      final data = {
        'uid': uid,
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : user.displayName,
        'email': user.email ?? _emailController.text.trim(),
        'phone': _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        'isVerified': isVerified,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        if (role == 'patient') 'patientId': 'MED-PAT-$patientIdSuffix',
      };

      if (role == 'doctor') {
        data['specialization'] = _specializationController.text.trim();
        data['licenseNumber'] = _licenseController.text.trim();
        data['verificationStatus'] = 'pending';
        data['isVerified'] = false;
      }

      await _firestore.collection('users').doc(user.uid).set(data);

      if (role == 'doctor') {
        final doctorProfile = Doctor(
          uid: user.uid,
          name: data['name']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          specialty: _specializationController.text.trim(),
          phone: data['phone']?.toString(),
          licenseNumber: _licenseController.text.trim(),
          clinicName: null,
          clinicAddress: null,
          bio: null,
          imageUrl: user.photoURL,
          isAvailable: true,
          rating: 0.0,
          totalRatings: 0,
          consultationFee: null,
          languages: const ['English'],
          education: const [],
          certifications: const [],
          services: const [],
          appointmentDuration: 30,
          isVerified: false,
          isPremium: false,
          verificationStatus: 'pending',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firestore.collection('doctors').doc(user.uid).set(
              doctorProfile.toMap(),
            );
      }

      _showSuccess('Account created successfully!');
      if (!mounted) return;
      if (role == 'doctor') {
        Navigator.pushReplacementNamed(
          context,
          Routes.doctorApprovalPending,
        );
      } else {
        Navigator.pushReplacementNamed(context, Routes.patientHome);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobileLayout = size.width < 600;
    final maxWidth = isMobileLayout ? double.infinity : 450.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.95),
              Theme.of(context).primaryColor.withOpacity(0.85),
              Colors.white.withOpacity(0.9),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minHeight: size.height,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Section
                      SizedBox(
                          height: isMobileLayout ? size.height * 0.02 : 10),
                      _buildHeaderSection(context),
                      const SizedBox(height: 40),

                      // Form Card
                      _buildFormCard(context),

                      // Action Buttons
                      const SizedBox(height: 24),
                      _buildActionButtons(context),

                      // Divider
                      const SizedBox(height: 20),
                      _buildDivider(),

                      // Google Sign In
                      const SizedBox(height: 20),
                      _buildGoogleSignInButton(context),

                      // Doctor registration shortcut
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.doctorSignup);
                        },
                        icon: const Icon(Icons.medical_services_outlined),
                        label: const Text('Create Doctor Account'),
                      ),

                      // Login Redirect
                      const SizedBox(height: 24),
                      _buildLoginRedirect(),
                    ]
                        .animate(interval: 100.ms)
                        .slideY(
                            begin: 0.1,
                            end: 0,
                            duration: 500.ms,
                            curve: Curves.easeOut)
                        .fadeIn(duration: 500.ms),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      children: [
        // Premium Logo Design
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: AppLogo(
              height: 60,
              width: 60,
              lightColor: Colors.white,
              darkColor: Colors.white,
            ),
          ),
        )
            .animate()
            .scale(duration: 800.ms, curve: Curves.elasticOut)
            .then()
            .shake(duration: 600.ms, hz: 4),

        const SizedBox(height: 24),

        // Title
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: -0.5, end: 0, curve: Curves.easeOut),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Join thousands of users managing their health',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Card(
      elevation: 25,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Verification Method Selector
              _buildVerificationMethodBanner(),
              const SizedBox(height: 16),

              // Name Field
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Please enter your name' : null,
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -20, end: 0),

              const SizedBox(height: 16),

              // Phone Field - Conditionally Required
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number (Optional)',
                icon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      value.trim().length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -20, end: 0),

              const SizedBox(height: 16),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    (value?.isEmpty ?? true) || !value!.contains('@')
                        ? 'Please enter a valid email'
                        : null,
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -20, end: 0),

              const SizedBox(height: 16),

              // Password Field
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                icon: Icons.lock_rounded,
                obscureText: _obscurePassword,
                validator: (value) => (value?.length ?? 0) < 6
                    ? 'Password must be at least 6 characters'
                    : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ).animate().fadeIn(delay: 600.ms).slideX(begin: -20, end: 0),

              const SizedBox(height: 16),

              // Confirm Password Field
              _buildTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                icon: Icons.lock_reset_rounded,
                obscureText: _obscureConfirmPassword,
                validator: (value) => value != _passwordController.text
                    ? 'Passwords do not match'
                    : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ).animate().fadeIn(delay: 700.ms).slideX(begin: -20, end: 0),

              // Verification Section
              if (_showVerificationStep) ...[
                const SizedBox(height: 20),
                _buildVerificationSection(context),
              ],
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack);
  }

  Widget _buildVerificationMethodBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.email_outlined,
                color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email verification only',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Use the same phone number for doctor or patient profiles. It will be saved as profile data, not used as the login key.',
                  style: TextStyle(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_rounded,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verify Your Account',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_registerAsDoctor) ...[
            TextFormField(
              controller: _specializationController,
              decoration: const InputDecoration(
                labelText: 'Specialization (e.g., Cardiology)',
                prefixIcon: Icon(Icons.medical_services_outlined),
              ),
              validator: (v) {
                if (_registerAsDoctor && (v == null || v.trim().isEmpty)) {
                  return 'Enter specialization';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'License Number',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) {
                if (_registerAsDoctor && (v == null || v.trim().isEmpty)) {
                  return 'Enter license number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],

          // Description
          Text(
            'We\'ve sent a verification link to your email address:',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _emailController.text.trim(),
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Email link flow does not require code input
          // Resend Section
          if (_resendTimer > 0)
            Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Resend available in $_resendTimer seconds',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(Icons.refresh_rounded,
                    size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: _resendCode,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Resend Link',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ).animate().scale(duration: 400.ms).fadeIn();
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_showVerificationStep
                    ? _checkEmailVerifiedAndComplete
                    : _signupEmail),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showVerificationStep
                            ? Icons.verified_user_rounded
                            : Icons.person_add_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _showVerificationStep
                            ? 'Complete Verification'
                            : 'Create Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey.shade400,
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey.shade400,
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _signupWithGoogle,
        icon: Image.asset(
          'assets/images/google.png',
          height: 20,
          width: 20,
          errorBuilder: (_, __, ___) => Icon(
            Icons.g_mobiledata_rounded,
            size: 24,
            color: Colors.grey.shade700,
          ),
        ),
        label: Text(
          'Continue with Google',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoginRedirect() {
    // Use Wrap so the text and button will wrap on narrow widths and avoid overflow
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 15,
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      style: TextStyle(
        color: Colors.grey.shade900,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey.shade600,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        counterText: '',
        errorStyle: TextStyle(
          color: Colors.red.shade600,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
