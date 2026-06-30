// widgets/common/logo_widget.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double height;
  final double width;
  final Color? lightColor;
  final Color? darkColor;

  const AppLogo({
    super.key,
    this.height = 100,
    this.width = 100,
    this.lightColor,
    this.darkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
      ),
      child: Image.asset(
        'assets/images/logo.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Enhanced fallback design if image fails to load
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  lightColor ?? Colors.blue.shade700,
                  darkColor ?? Colors.purple.shade600,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (lightColor ?? Colors.blue.shade700).withOpacity(0.3),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.medical_services_rounded,
                size: height * 0.5,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
