// lib/main.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medicore/config/env.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:medicore/app.dart';
import 'package:medicore/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, kIsWeb;
import 'package:medicore/providers/auth_provider.dart';
import 'package:medicore/providers/doctor_provider.dart';
import 'package:medicore/providers/theme_provider.dart';
import 'package:medicore/providers/appointment_provider.dart';
import 'package:medicore/providers/medicine_provider.dart';
import 'package:medicore/providers/cart_provider.dart';
import 'package:medicore/providers/chat_provider.dart';
import 'package:medicore/providers/health_ai_provider.dart';
import 'package:medicore/providers/locale_provider.dart';
import 'package:medicore/providers/order_provider.dart';
import 'package:medicore/providers/patient_provider.dart';
import 'package:medicore/providers/ai_provider.dart';
import 'package:medicore/providers/hospital_provider.dart';
import 'package:medicore/utils/sample_data_generator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:medicore/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {

    await dotenv.load(fileName: '.env');
    await Env.initialize();
    print('[Env] successUrl=${Env.env.successUrl}');
    print('[Env] failUrl=${Env.env.failUrl}');
    print('[Env] cancelUrl=${Env.env.cancelUrl}');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');

    
    if (!kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        // ignore: deprecated_member_use
        androidProvider: kReleaseMode
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
        // ignore: deprecated_member_use
        appleProvider:
            kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
      );
    }

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Check and generate sample data if needed (for development)
    await _initializeSampleData();
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        // Theme & Locale Providers (should be first)
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),

        // Auth & User Providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),

        // Core Feature Providers
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),

        // Medicine & Shopping Providers
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),

        // AI & Chat Providers
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => HealthAIProvider()),
      ],
      child: const App(),
    ),
  );
}

Future<void> _initializeSampleData() async {
  try {
    final sampleDataGenerator = SampleDataGenerator();

    // Check if sample data already exists
    final dataExists = await sampleDataGenerator.checkSampleDataExists();

    if (!dataExists) {
      print('Generating sample data for first time use...');
      await sampleDataGenerator.generateSampleData();
      print('Sample data generated successfully!');
    } else {
      print('Sample data already exists. Skipping generation.');
    }
  } catch (e) {
    print('Error initializing sample data: $e');
    // Don't crash the app if sample data generation fails
  }
}
