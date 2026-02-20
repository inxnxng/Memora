import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memora/config/provider_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables. 
  // We use try-catch because .env might be missing in some environments, 
  // and we have fallbacks in the code.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or failed to load. Using fallbacks.");
  }

  await Firebase.initializeApp(
    //options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(const ProviderContainer());
}
