// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:medicore/config/routes.dart';
import 'package:medicore/providers/ai_provider.dart';
import 'package:medicore/providers/appointment_provider.dart';
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/providers/medicine_provider.dart';
import 'package:medicore/providers/cart_provider.dart';
import 'package:medicore/providers/chat_provider.dart';
import 'package:medicore/providers/doctor_provider.dart';
import 'package:medicore/providers/health_ai_provider.dart';
import 'package:medicore/providers/locale_provider.dart';
import 'package:medicore/providers/order_provider.dart';
import 'package:medicore/providers/patient_provider.dart';
import 'package:medicore/providers/theme_provider.dart';
import 'package:medicore/providers/hospital_provider.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/notification_provider.dart';
import 'package:medicore/services/push_notification_service.dart';
// Removed: 'dart:async' was only used for AppLinks stream
// AppLinks removed

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme & Localization
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),

        // Authentication & User Management
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),

        // Core Features
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),

        // AI & Chat Services
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => HealthAIProvider()),

        // Notifications
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: _AppWrapper(),
    );
  }
}

class _AppWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        // Ensure push notifications are initialized once with context
        return _Bootstrapper(
          child: MaterialApp(
            title: 'MediCore - Your Health Companion',

            // Theme Configuration
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,

            // Localization Configuration
            locale: localeProvider.locale,
            supportedLocales: LocaleProvider.supportedLocales,
            localizationsDelegates: const [
              // Add your localization delegates here if needed
            ],

            // App Configuration
            debugShowCheckedModeBanner: false,
            initialRoute: Routes.splash,
            onGenerateRoute: Routes.onGenerateRoute,
            routes: Routes.routes,

            // Error Handling for unknown routes - FIXED PIXEL OVERFLOW
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Page Not Found'),
                    backgroundColor: Colors.red,
                  ),
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Page Not Found',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'The requested page "${settings.name}" was not found.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  Routes.splash,
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Go to Home'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },

            // Builder for global app configuration with overflow protection
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0, // Prevent text scaling issues
                ),
                child: child!,
              );
            },

            // Scroll behavior customization
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(),
            ),
          ),
        );
      },
    );
  }
}

class _Bootstrapper extends StatefulWidget {
  final Widget child;
  const _Bootstrapper({required this.child});

  @override
  State<_Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<_Bootstrapper> {
  bool _initialized = false;
  // Deep link handling removed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      PushNotificationService.instance.init(context);
      _initialized = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
