// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:medicore/providers/notification_provider.dart';

// Top-level background handler (must be a global function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI here; background notifications are displayed by Android if proper channel exists.
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.high,
  );

  bool _initialized = false;

  Future<void> init(BuildContext context) async {
    if (_initialized) return;

    // Android: create channel
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _local.initialize(initSettings,
        onDidReceiveNotificationResponse: (details) {
      // Handle navigation when user taps a local notification
      try {
        final payloadStr = details.payload;
        if (payloadStr != null && payloadStr.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(payloadStr);
          _navigateFromData(context, data);
        } else {
          _navigateToInbox(context);
        }
      } catch (_) {
        _navigateToInbox(context);
      }
    });

    // Create channel on Android
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Request FCM permission (Android 13+ and iOS)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Ensure foreground notifications show on iOS
    await _messaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    // Get FCM token and register to user profile
    final token = await _messaging.getToken();
    if (token != null) {
      // ignore: avoid_print
      print('FCM token: $token');
      await _registerToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      // ignore: avoid_print
      print('FCM token refreshed: $newToken');
      await _registerToken(newToken);
    });

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      final android = notification?.android;

      // Update provider so UI badge can react
      final notifProv = _tryGetNotifProvider(context);
      if (notification != null && notifProv != null) {
        notifProv.addNotification(
          AppNotification(
            title: notification.title ?? 'Notification',
            body: notification.body ?? '',
            data: message.data.isEmpty
                ? null
                : Map<String, dynamic>.from(message.data),
          ),
        );
      }

      // Show local notification (foreground)
      if (notification != null) {
        await _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
          // Encode data as JSON so we can parse on tap
          payload: jsonEncode(message.data),
        );
      }
    });

    // Handle notification tapped when app in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final data = message.data;
      if (data.isNotEmpty) {
        _navigateFromData(context, Map<String, dynamic>.from(data));
      } else {
        _navigateToInbox(context);
      }
    });

    // If the app was launched by tapping a notification (terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final data = initialMessage.data;
      if (data.isNotEmpty) {
        _navigateFromData(context, Map<String, dynamic>.from(data));
      } else {
        _navigateToInbox(context);
      }
    }

    _initialized = true;
  }

  // Show an immediate local notification (foreground or background)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload?.toString(),
    );
  }

  // Provider lookup without requiring widgets in background handlers
  NotificationProvider? _tryGetNotifProvider(BuildContext context) {
    try {
      return Provider.of<NotificationProvider>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  // Register/store FCM token to the logged-in user's Firestore document
  Future<void> _registerToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final users =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await users.set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Best-effort only
    }
  }

  void _navigateFromData(BuildContext context, Map<String, dynamic> data) {
    // Expected keys: route or type + payload
    final route = data['route'] as String?;
    if (route != null && route.isNotEmpty) {
      Navigator.pushNamed(context, route, arguments: data['args']);
      return;
    }

    final type = data['type'] as String? ?? 'general';
    final payload = (data['payload'] is Map)
        ? Map<String, dynamic>.from(data['payload'] as Map)
        : <String, dynamic>{};

    switch (type) {
      case 'appointment':
        final id = payload['appointmentId'] as String?;
        if (id != null) {
          Navigator.pushNamed(context, '/appointment-detail', arguments: id);
        } else {
          _navigateToInbox(context);
        }
        break;
      case 'order':
        final id = payload['orderId'] as String?;
        // Route to orders list; detail routing may be within that screen
        Navigator.pushNamed(context, '/my-orders', arguments: id);
        break;
      default:
        _navigateToInbox(context);
    }
  }

  void _navigateToInbox(BuildContext context) {
    Navigator.pushNamed(context, '/notifications');
  }
}
