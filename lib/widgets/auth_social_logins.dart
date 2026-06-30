import 'package:flutter/material.dart';

class AuthSocialLogins extends StatelessWidget {
  final Function(String provider) onLogin;
  const AuthSocialLogins({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => onLogin('google'),
          icon: Image.asset('assets/google_logo.png', height: 24),
          label: const Text('Sign in with Google'),
        ),
        // Facebook sign-in removed per request
      ],
    );
  }
}
