// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_import, avoid_print

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/widgets/common/logo_widget.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

enum LoginType { email, phone }

class CountryCode {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.isDoctorLogin = false});

  final bool isDoctorLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LoginType _loginType = LoginType.email;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showOtpField = false;
  late final bool _isDoctorLogin;
  String? _verificationId;
  int _resendTimer = 0;
  Timer? _timer;

  // Country code selection
  CountryCode _selectedCountry = CountryCode(
    name: 'United States',
    code: 'US',
    dialCode: '+1',
    flag: '🇺🇸',
  );

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  late AnimationController _animationController;
  late AnimationController _buttonScaleController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonScaleAnimation;

  // List of common country codes
  final List<CountryCode> _countryCodes = [
    CountryCode(
        name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
    CountryCode(
        name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
    CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
    CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
    CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
    CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
    CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
    CountryCode(name: 'Bangladesh', code: 'BD', dialCode: '+880', flag: '🇧🇩'),
    CountryCode(name: 'Pakistan', code: 'PK', dialCode: '+92', flag: '🇵🇰'),
    CountryCode(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
    CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
    CountryCode(name: 'South Korea', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
    CountryCode(name: 'Singapore', code: 'SG', dialCode: '+65', flag: '🇸🇬'),
    CountryCode(name: 'Malaysia', code: 'MY', dialCode: '+60', flag: '🇲🇾'),
    CountryCode(
        name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
    CountryCode(name: 'UAE', code: 'AE', dialCode: '+971', flag: '🇦🇪'),
    CountryCode(name: 'Brazil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
    CountryCode(name: 'Mexico', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
    CountryCode(name: 'Russia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
    CountryCode(
        name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
  ];

  @override
  void initState() {
    super.initState();
    _isDoctorLogin = widget.isDoctorLogin;
    _initializeAnimations();
    _animationController.forward();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
      ),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonScaleController.dispose();
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
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

  // --- Auth Logic ---

  Future<void> _login() async {
    if (_isLoading) return;

    if (_loginType == LoginType.email) {
      if (!_formKey.currentState!.validate()) return;
      await _loginEmailPassword();
    } else {
      if (!_showOtpField) {
        if (!_formKey.currentState!.validate()) return;
        await _sendPhoneOTP();
      } else {
        await _verifyOTP();
      }
    }
  }

  Future<void> _loginEmailPassword() async {
    setState(() => _isLoading = true);
    final email = _emailPhoneController.text.trim();
    final password = _passwordController.text;

    try {
      final success = _isDoctorLogin
          ? await context.read<AuthProvider>().loginDoctor(email, password)
          : await context.read<AuthProvider>().loginPatient(email, password);
      if (!success) {
        throw fb_auth.FirebaseAuthException(
          code: 'login-failed',
          message: _isDoctorLogin
              ? 'Invalid doctor credentials or account role.'
              : 'Invalid patient credentials or account role.',
        );
      }
      await _navigateToHome();
    } on fb_auth.FirebaseAuthException catch (e) {
      _showError('Login Failed: ${e.message ?? 'Check credentials'}');
      setState(() => _isLoading = false);
    } catch (e) {
      print('Login Error: $e');
      _showError('An unexpected error occurred.');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPhoneOTP() async {
    final phoneNumber =
        '${_selectedCountry.dialCode}${_emailPhoneController.text.trim()}';

    setState(() => _isLoading = true);

    try {
      final completer = Completer<void>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          final userCredential = await _auth.signInWithCredential(credential);
          final firebaseUser = userCredential.user;
          if (firebaseUser != null) {
            final userDocRef = FirebaseFirestore.instance
                .collection('users')
                .doc(firebaseUser.uid);
            final userDoc = await userDocRef.get();
            if (!userDoc.exists) {
              await userDocRef.set({
                'uid': firebaseUser.uid,
                'email': firebaseUser.email ?? '',
                'name': firebaseUser.displayName ?? '',
                'phone': firebaseUser.phoneNumber ?? '',
                'role': 'patient',
                'isVerified': true,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
          if (mounted && !completer.isCompleted) {
            completer.complete();
            await _navigateToHome();
          }
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          if (mounted && !completer.isCompleted) {
            completer.completeError(e);
            setState(() => _isLoading = false);
            _showError('Verification Failed: ${e.message}');
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          if (mounted && !completer.isCompleted) {
            completer.complete();
            setState(() {
              _showOtpField = true;
              _isLoading = false;
            });
            _startResendTimer();
            _showSuccess('OTP sent to phone.');
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );

      await completer.future;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code != 'The supplied code is invalid.' && mounted) {
        _showError('Send OTP Failed: ${e.message}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Send OTP Error: $e');
      if (mounted) {
        _showError(
            'Failed to send OTP. Check the phone number format or try again.');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6 || _verificationId == null) {
      _showError('Enter a valid 6-digit code.');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final fb_auth.PhoneAuthCredential credential =
          fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      // Create Firestore user document for new phone-auth users
      if (firebaseUser != null) {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid);
        final userDoc = await userDocRef.get();
        if (!userDoc.exists) {
          await userDocRef.set({
            'uid': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            'name': firebaseUser.displayName ?? '',
            'phone': firebaseUser.phoneNumber ?? '',
            'role': 'patient',
            'isVerified': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await _navigateToHome();
    } on fb_auth.FirebaseAuthException catch (e) {
      _showError('OTP Verification Failed: ${e.message}');
      setState(() => _isLoading = false);
    } catch (e) {
      print('Verify OTP Error: $e');
      _showError('An unexpected error occurred.');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final fb_auth.OAuthCredential credential =
          fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      await _navigateToHome();
    } on fb_auth.FirebaseAuthException catch (e) {
      _showError('Google Sign-In Failed: ${e.message}');
      setState(() => _isLoading = false);
    } catch (e) {
      print('Google Sign-In Error: $e');
      _showError('An unexpected error occurred during Google Sign-In.');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_loginType != LoginType.email ||
        _emailPhoneController.text.isEmpty ||
        !_emailPhoneController.text.contains('@')) {
      _showError('Please enter a valid email address to reset password.');
      return;
    }

    final email = _emailPhoneController.text.trim();
    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSuccess('Password reset email sent! Check your inbox.');
    } on fb_auth.FirebaseAuthException catch (e) {
      _showError('Failed to send reset email: ${e.message}');
    } catch (e) {
      _showError('An unexpected error occurred.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToHome() async {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _showOtpField = false;
      });

      final authUser = _auth.currentUser;
      if (authUser == null) {
        Navigator.pushReplacementNamed(context, Routes.patientHome);
        return;
      }

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .get();
        final role = doc.data()?['role']?.toString();
        final verificationStatus =
            doc.data()?['verificationStatus']?.toString();
        final isVerified = doc.data()?['isVerified'] == true;

        if (!mounted) return;

        if (role == 'doctor') {
          if (verificationStatus == 'verified' && isVerified) {
            Navigator.pushReplacementNamed(context, Routes.doctorHome);
          } else {
            Navigator.pushReplacementNamed(
              context,
              Routes.doctorApprovalPending,
            );
          }
        } else if (role == 'admin') {
          Navigator.pushReplacementNamed(context, Routes.adminHome);
        } else {
          Navigator.pushReplacementNamed(context, Routes.patientHome);
        }
      } catch (_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, Routes.patientHome);
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
    }
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }

    if (value.trim().length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value.trim())) {
      return 'Enter a valid phone number (10-15 digits)';
    }

    return null;
  }

  String? _otpValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }

    if (value.trim().length != 6) {
      return 'Enter a valid 6-digit OTP';
    }

    return null;
  }

  void _showCountryCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Country',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _countryCodes.length,
            itemBuilder: (context, index) {
              final country = _countryCodes[index];
              return ListTile(
                leading: Text(
                  country.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(country.name),
                trailing: Text(
                  country.dialCode,
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedCountry = country;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 800;
    final isTablet = size.width > 600 && size.width <= 800;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
              Colors.blue.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWeb
                      ? size.width * 0.2
                      : isTablet
                          ? size.width * 0.15
                          : 24.0,
                  vertical: 20,
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: MouseRegion(
                    onEnter: (_) => _buttonScaleController.forward(),
                    onExit: (_) => _buttonScaleController.reverse(),
                    child: AnimatedBuilder(
                      animation: _buttonScaleController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScaleAnimation.value,
                          child: child,
                        );
                      },
                      child: Card(
                        elevation: 20,
                        shadowColor: Colors.blue.withOpacity(0.25),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Container(
                          width: isWeb ? 520 : null,
                          constraints: const BoxConstraints(maxWidth: 700),
                          // background image + overlay
                          child: Stack(
                            children: [
                              // Full-card background image
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/images/login.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Slight blur to make overlaying content stand out
                              Positioned.fill(
                                child: ClipRect(
                                  child: BackdropFilter(
                                    filter: ui.ImageFilter.blur(
                                        sigmaX: 4, sigmaY: 4),
                                    child: Container(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),

                              // Dark gradient overlay for readability while keeping photo visible
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.36),
                                        Colors.black.withOpacity(0.12),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Content
                              Padding(
                                padding: EdgeInsets.all(isWeb ? 44 : 28),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Highlighted logo with translucent background
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const AppLogo(
                                          height: 56,
                                          width: 56,
                                          lightColor: Colors.blue,
                                          darkColor: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 18),

                                      // Title
                                      _buildTitleSection(context, isWeb),
                                      const SizedBox(height: 20),

                                      // Login Type Toggle
                                      _buildLoginTypeToggle(),
                                      const SizedBox(height: 20),

                                      // Form Fields
                                      _buildFormFields(context),

                                      const SizedBox(height: 18),

                                      // Forgot Password Link
                                      if (_loginType == LoginType.email &&
                                          !_showOtpField)
                                        _buildForgotPasswordLink(),

                                      const SizedBox(height: 12),

                                      // Login Button (primary)
                                      _buildLoginButton(),

                                      const SizedBox(height: 12),

                                      // Social Login Section with subtle divider
                                      _buildSocialLoginSection(),

                                      const SizedBox(height: 12),

                                      // Don't have an account? then prominent Create Account button
                                      const SizedBox(height: 6),
                                      Text(
                                        "Don't have an account?",
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.95),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, Routes.signup);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade600,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Divider above Admin Login for separation
                                      Divider(
                                        thickness: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 8),
                                      // Doctor Sign In shortcut
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, Routes.doctorLogin);
                                          },
                                          icon: Icon(
                                            Icons.medical_services_rounded,
                                            color: Colors.teal.shade600,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'Doctor Sign In',
                                            style: TextStyle(
                                              color: Colors.teal.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // Doctor Sign Up shortcut
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              Routes.doctorSignup,
                                            );
                                          },
                                          icon: Icon(
                                            Icons.person_add_alt_1_rounded,
                                            color: Colors.teal.shade600,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'Doctor Sign Up',
                                            style: TextStyle(
                                              color: Colors.teal.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ),

                                      // Admin Login button (secondary)
                                      Center(
                                        child: TextButton.icon(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                                context, Routes.adminLogin);
                                          },
                                          icon: Icon(
                                            Icons.admin_panel_settings_rounded,
                                            color: Colors.purple.shade600,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'Admin Login',
                                            style: TextStyle(
                                              color: Colors.purple.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
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
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context, bool isWeb) {
    return Column(
      children: [
        Text(
          _isDoctorLogin ? 'Doctor Portal' : 'Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.blue.shade700,
                fontSize: isWeb ? 32 : 28,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _isDoctorLogin
              ? 'Sign in to manage your practice and patient care'
              : 'Sign in to continue your healthcare journey',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: isWeb ? 16 : 14,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildToggleSegment(
            LoginType.email,
            'Email Login',
            Icons.email_rounded,
          ),
          _buildToggleSegment(
            LoginType.phone,
            'Phone Login',
            Icons.phone_iphone_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSegment(LoginType type, String label, IconData icon) {
    final isSelected = _loginType == type;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(color: Colors.blue.shade100, width: 1)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _loginType = type;
                _showOtpField = false;
                _passwordController.clear();
                _otpController.clear();
                _emailPhoneController.clear();
              });
              _formKey.currentState?.reset();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? Colors.blue.shade600
                        : Colors.grey.shade500,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey.shade600,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Column(
        key: ValueKey('${_loginType}_$_showOtpField'),
        children: [
          if (_loginType == LoginType.email)
            _buildEnhancedTextField(
              controller: _emailPhoneController,
              label: 'Email Address',
              hint: 'your@email.com',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            )
          else
            _buildPhoneNumberField(),
          const SizedBox(height: 16),
          if (_loginType == LoginType.email && !_showOtpField)
            _buildEnhancedTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_rounded,
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.grey.shade600,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
              validator: _passwordValidator,
            )
          else if (_loginType == LoginType.phone && _showOtpField)
            _buildOtpSection(),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              // Country Code Selector
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    onTap: _showCountryCodeDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedCountry.flag,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCountry.dialCode,
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Colors.grey.shade500,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Phone Number Input
              Expanded(
                child: TextFormField(
                  controller: _emailPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., 17XXXXXXXX',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 16,
                    ),
                    counterText: '',
                    errorStyle: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  validator: _phoneValidator,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: _isLoading ? null : _resetPassword,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.blue.shade500,
          size: 20,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue.shade500,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.red.shade600,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        counterText: '',
        errorStyle: TextStyle(
          color: Colors.red.shade600,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOtpSection() {
    return Column(
      children: [
        _buildEnhancedTextField(
          controller: _otpController,
          label: 'Enter 6-Digit OTP',
          icon: Icons.sms_rounded,
          keyboardType: TextInputType.number,
          maxLength: 6,
          validator: _otpValidator,
        ),
        const SizedBox(height: 12),
        if (_verificationId != null)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _resendTimer > 0
                ? Text(
                    'Resend code in $_resendTimer seconds',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : TextButton(
                    onPressed: _isLoading ? null : _sendPhoneOTP,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Resend OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isLoading ? null : _login,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade600,
                  Colors.blue.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _loginType == LoginType.email || !_showOtpField
                              ? 'Sign In'
                              : 'Verify OTP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildSocialButton(
                onTap: _signInWithGoogle,
                iconPath: 'assets/images/google.png',
                backgroundColor: Colors.white,
                borderColor: Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required String iconPath,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isLoading ? null : onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Center(
            child: Image.asset(
              iconPath,
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.g_mobiledata,
                  size: 20,
                  color: Colors.black,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Sign up and admin widget helpers removed — replaced by prominent buttons
}
