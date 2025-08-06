import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:memora/config/provider_setup.dart';
import 'package:memora/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderContainer());
}
