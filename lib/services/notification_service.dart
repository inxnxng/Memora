import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memora/utils/platform_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    if (!PlatformUtils.isApple) {
      await _firebaseMessaging.requestPermission();
      String? fcmToken;
      try {
        fcmToken = await _firebaseMessaging.getToken(
          vapidKey:
              'BAKDXCQfXzOOKQgMEnCs9e5RQjVmB1YP1FL7a0wG3ghaQXacQFQt_m6MuukLSW7VB3c8Rr8mEbgMjNz7TncsSYU',
        );
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
      _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  Future<void> setNotification(bool isEnabled, TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', isEnabled);
    await prefs.setInt('notification_hour', time.hour);
    await prefs.setInt('notification_minute', time.minute);

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'notificationEnabled': isEnabled,
          'notificationHour': time.hour,
          'notificationMinute': time.minute,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving notification settings to Firestore: $e');
    }
  }

  Future<Map<String, dynamic>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('notifications_enabled') ?? false;
    final hour = prefs.getInt('notification_hour') ?? 21;
    final minute = prefs.getInt('notification_minute') ?? 0;
    return {'isEnabled': isEnabled, 'hour': hour, 'minute': minute};
  }
}
