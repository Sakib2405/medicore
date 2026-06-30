// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/widgets/common/logo_widget.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    // Wait for animations to complete
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if user is logged in
      final bool isLoggedIn = authProvider.isLoggedIn;

      if (isLoggedIn) {
        // Navigate to appropriate home based on user role
        final user = authProvider.currentUser;
        if (user?.role == 'admin') {
          Navigator.pushReplacementNamed(context, Routes.adminHome);
        } else if (user?.isDoctor == true) {
          if (user?.isUserVerified == true) {
            Navigator.pushReplacementNamed(context, Routes.doctorHome);
          } else {
            Navigator.pushReplacementNamed(
              context,
              Routes.doctorApprovalPending,
            );
          }
        } else {
          Navigator.pushReplacementNamed(context, Routes.patientHome);
        }
      } else {
        // Navigate to login screen
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    } catch (error) {
      // If any error occurs, navigate to login screen
      Navigator.pushReplacementNamed(context, Routes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with Container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20.0,
                      spreadRadius: 5.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: AppLogo(
                    height: 80,
                    width: 80,
                    lightColor: Theme.of(context).colorScheme.primary,
                    darkColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // App Name
              Text(
                'MediCore',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 8),

              // Tagline
              Text(
                'Your Health Companion',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),

              // Loading Indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
