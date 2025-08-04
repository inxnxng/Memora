import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      // 1. Request permission
      await _firebaseMessaging.requestPermission();

      // 2. Get the FCM token.
      String? fcmToken;
      try {
        fcmToken = await _firebaseMessaging.getToken();
      } on FirebaseException catch (e) {
        if (kDebugMode) {
          print('Failed to get FCM token: ${e.code}');
        }
      }

      if (kDebugMode) {
        print('FCM Token: $fcmToken');
      }
      if (fcmToken != null) {
        await _saveTokenToDatabase(fcmToken);
      }

      // 3. Listen for token refreshes. This will catch the token if it wasn't ready initially.
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);

      // 4. Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'High Importance Notifications',
                channelDescription:
                    'This channel is used for important notifications.',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    }
  }

  Future<void> setNotification(bool isEnabled, TimeOfDay time) async {
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', isEnabled);
      await prefs.setInt('notification_hour', time.hour);
      await prefs.setInt('notification_minute', time.minute);

      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'notificationEnabled': isEnabled,
          'notificationHour': time.hour,
          'notificationMinute': time.minute,
        }, SetOptions(merge: true));
      }
    }
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notifications_enabled') ?? false;
      final hour = prefs.getInt('notification_hour') ?? 21;
      final minute = prefs.getInt('notification_minute') ?? 0;
      return {'isEnabled': isEnabled, 'hour': hour, 'minute': minute};
    }
    return {'isEnabled': false, 'hour': 21, 'minute': 0};
  }
}
