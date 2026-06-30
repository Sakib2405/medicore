import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:medicore/config/routes.dart';
import 'package:medicore/models/doctor_model.dart';
import 'package:medicore/widgets/common/logo_widget.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _specializationController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showVerificationStep = false;
  int _resendTimer = 0;
  Timer? _timer;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specializationController.dispose();
    _licenseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _signupEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'user-null', message: 'User creation failed');
      }

      await user.updateDisplayName(_nameController.text.trim());
      await user.sendEmailVerification();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showVerificationStep = true;
          _startResendTimer();
        });
        
        _showSuccess('Verification email sent to ${user.email}');
      }
      
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String message = 'Failed to sign up';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already in use. Please use a different email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'weak-password':
          message = 'Weak password. Password must be at least 6 characters.';
          break;
        case 'too-many-requests':
          message = 'Too many requests. Please try again later.';
          break;
        default:
          message = 'Sign up failed: ${e.message}';
      }
      _showError(message);
    } on FirebaseException catch (e) {
      setState(() => _isLoading = false);
      _showError('Database error: ${e.message}');
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('An unexpected error occurred: $e');
    }
  }

  Future<void> _sendEmailVerificationLink() async {
    try {
      final user = _auth.currentUser;
      if (user == null || (user.email ?? '').isEmpty) {
        _showError('No user found to verify');
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
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _showError('User not logged in');
        setState(() => _isLoading = false);
        return;
      }
      
      await currentUser.reload();
      final updatedUser = _auth.currentUser;
      final isVerified = updatedUser?.emailVerified ?? false;
      
      if (isVerified) {
        await _completeSignup();
        
        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccess('Account verified and created successfully!');
          Navigator.pushReplacementNamed(
            context,
            Routes.doctorApprovalPending,
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Email not verified yet. Please check your inbox and click the verification link.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Could not verify email status: $e');
      }
    }
  }

  Future<void> _resendCode() async {
    await _sendEmailVerificationLink();
  }

  Future<void> _completeSignup() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userData = {
      'uid': user.uid,
      'name': _nameController.text.trim(),
      'email': user.email ?? _emailController.text.trim(),
      'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
      'isVerified': true,
      'role': 'doctor',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'specialization': _specializationController.text.trim(),
      'licenseNumber': _licenseController.text.trim(),
      'verificationStatus': 'pending',
    };

    await _firestore.collection('users').doc(user.uid).set(userData);

    final doctorProfile = Doctor(
      uid: user.uid,
      name: _nameController.text.trim(),
      email: user.email ?? _emailController.text.trim(),
      specialty: _specializationController.text.trim(),
      phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
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
      isVerified: true,
      isPremium: false,
      verificationStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestore
        .collection('doctors')
        .doc(user.uid)
        .set(doctorProfile.toMap());
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.teal.shade600),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_showVerificationStep) ...[
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
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
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  icon: Icons.phone_iphone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (value.trim().length < 10) {
                        return 'Please enter a valid phone number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _specializationController,
                  label: 'Specialization',
                  icon: Icons.medical_services_outlined,
                  hint: 'Cardiology, Dermatology, etc.',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your specialization';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _licenseController,
                  label: 'License Number',
                  icon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your license number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() {
                      _obscurePassword = !_obscurePassword;
                    }),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_reset_rounded,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    }),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signupEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Doctor Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_user, color: Colors.teal.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Verify Your Email',
                            style: TextStyle(
                              color: Colors.teal.shade900,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'We sent a verification link to:',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailController.text.trim(),
                        style: TextStyle(
                          color: Colors.teal.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please check your email inbox and click the verification link. Then click "Complete Verification" below.',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_resendTimer > 0)
                        Text(
                          'Resend available in $_resendTimer seconds',
                          style: TextStyle(color: Colors.grey.shade600),
                        )
                      else
                        TextButton.icon(
                          onPressed: _resendCode,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Resend Verification Link'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.teal.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _showVerificationStep = false;
                                  });
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _checkEmailVerifiedAndComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Complete Verification',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobileLayout = size.width < 600;
    final maxWidth = isMobileLayout ? double.infinity : 460.0;

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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight:
                        size.height - MediaQuery.of(context).padding.vertical,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      const AppLogo(height: 96, width: 96),
                      const SizedBox(height: 18),
                      Text(
                        'Doctor Sign Up',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your doctor account to manage appointments, prescriptions, and patient records.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildFormCard(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushNamed(
                                context, Routes.doctorLogin),
                        child: const Text(
                          'Already have a doctor account? Sign In',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushNamed(context, Routes.login),
                        child: const Text(
                          'Back to patient login',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      if (kIsWeb) const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}