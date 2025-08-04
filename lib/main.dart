import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:memora/config/provider_setup.dart';
import 'package:memora/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize NotificationService
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const ProviderContainer());
}
