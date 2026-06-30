// Modern Patient Signup Screen with Email Code & SMS OTP Verification
// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'package:medicore/config/routes.dart';
import 'package:medicore/services/email_verification_service.dart';
import 'package:medicore/services/sms_otp_service.dart';

class PatientSignupModern extends StatefulWidget {
  const PatientSignupModern({super.key});

  @override
  State<PatientSignupModern> createState() => _PatientSignupModernState();
}

class _PatientSignupModernState extends State<PatientSignupModern>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _emailVerificationService = EmailVerificationService();
  final _smsOtpService = SmsOtpService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0; // 0: Form, 1: Email Verification, 2: SMS OTP (optional)
  String _verificationMethod = 'email'; // 'email' or 'sms'
  int _resendTimer = 0;
  Timer? _timer;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _timer?.cancel();
    super.dispose();
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

  Future<void> _sendVerificationCode() async {
    if (_emailController.text.trim().isEmpty) {
      _showError('Please enter an email address');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _emailVerificationService.sendVerificationCode(
        _emailController.text.trim(),
      );
      setState(() {
        _currentStep = 1;
        _verificationMethod = 'email';
      });
      _startResendTimer();
      _showSuccess('Verification code sent to your email!');
    } catch (e) {
      _showError('Failed to send verification code: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyEmailCode() async {
    if (_verificationCodeController.text.trim().isEmpty) {
      _showError('Please enter the verification code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _emailVerificationService.verifyCode(
        _emailController.text.trim(),
        _verificationCodeController.text.trim(),
      );
      // Show SMS OTP option
      _showSmsOtpDialog();
    } catch (e) {
      _showError('Invalid verification code: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSmsOtp() async {
    if (_phoneController.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _smsOtpService.sendOtpToPhone(
        _phoneController.text.trim(),
        (verificationId) {
          setState(() {
            _verificationId = verificationId;
            _currentStep = 2;
            _verificationMethod = 'sms';
          });
          _startResendTimer();
          _showSuccess('OTP sent to your phone!');
        },
        (error) {
          _showError('Failed to send OTP: ${error.message}');
        },
      );
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifySmsOtp() async {
    if (_verificationCodeController.text.trim().isEmpty) {
      _showError('Please enter the OTP');
      return;
    }

    if (_verificationId == null) {
      _showError('Verification ID not found');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _smsOtpService.verifyOtpCode(
        _verificationId!,
        _verificationCodeController.text.trim(),
        _phoneController.text.trim(),
      );
      // Complete signup
      await _completeSignup();
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'OTP verification failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _skipSmsAndComplete() async {
    await _completeSignup();
  }

  Future<void> _completeSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      // Create Firebase Auth user
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) throw Exception('User creation failed');

      // Create Firestore user document
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'email': email,
        'name': name,
        'phone': phone,
        'role': 'patient',
        'isEmailVerified': true,
        'isPhoneVerified': _verificationMethod == 'sms',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSuccess('Account created successfully!');
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.patientHome,
          (route) => false,
        );
      });
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Signup failed');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) throw Exception('Google sign-up failed');

      // Check if user already exists
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Create new user document
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'Patient',
          'phone': '',
          'photoUrl': user.photoURL,
          'role': 'patient',
          'isEmailVerified': user.emailVerified,
          'isPhoneVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      _showSuccess('Account created successfully with Google!');
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.patientHome,
          (route) => false,
        );
      });
    } catch (e) {
      _showError('Google sign-up failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSmsOtpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Additional Security'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your email is verified! ✓'),
            SizedBox(height: 12),
            Text(
              'For extra security, we can verify your phone number too.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _skipSmsAndComplete();
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _sendSmsOtp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
            ),
            child: const Text('Verify Phone'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(_controller),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 30),
              if (_currentStep == 0) _buildSignupForm(),
              if (_currentStep == 1) _buildEmailVerification(),
              if (_currentStep == 2) _buildSmsOtpVerification(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStepDot(0, 'Account'),
        const Expanded(
          child: SizedBox(height: 2, child: Divider()),
        ),
        _buildStepDot(1, 'Email'),
        const Expanded(
          child: SizedBox(height: 2, child: Divider()),
        ),
        _buildStepDot(2, 'Phone'),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = step <= _currentStep;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFF667eea) : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.black87 : Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Your Account',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Join MediCore for better healthcare management',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_rounded,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Name is required';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Email is required';
              if (!value!.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number (for SMS OTP)',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            hint: '+880XXXXXXXXXX',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Password is required';
              if (value!.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_rounded,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 20,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Continue to Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Or continue with',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(height: 24),
          _buildGoogleSignUpButton(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, Routes.login),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Email Address',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a verification code to ${_emailController.text}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        const Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _verificationCodeController,
          label: 'Code',
          icon: Icons.mail_outline_rounded,
          hint: '000000',
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 20),
        if (_resendTimer > 0)
          Text(
            'Resend code in ${_resendTimer}s',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          )
        else
          GestureDetector(
            onTap: () {
              _verificationCodeController.clear();
              _sendVerificationCode();
            },
            child: const Text(
              'Resend Code',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF667eea),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyEmailCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            ),
        ),
      ],
    );
  }

  Widget _buildSmsOtpVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Phone Number',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent an OTP to ${_phoneController.text}',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 32),
        const Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _verificationCodeController,
          label: 'OTP Code',
          icon: Icons.sms_rounded,
          hint: '000000',
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        const SizedBox(height: 20),
        if (_resendTimer > 0)
          Text(
            'Resend OTP in ${_resendTimer}s',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          )
        else
          GestureDetector(
            onTap: () {
              _verificationCodeController.clear();
              _sendSmsOtp();
            },
            child: const Text(
              'Resend OTP',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF667eea),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifySmsOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _skipSmsAndComplete,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFF667eea)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Skip & Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signUpWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDB4437),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Text(
                '🔐',
                style: TextStyle(fontSize: 18),
              ),
            const SizedBox(width: 10),
            const Text(
              'Sign up with Gmail',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? hint,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
      ),
    );
  }
}
