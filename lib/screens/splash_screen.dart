import 'package:flutter/material.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/screens/home_screen.dart';
import 'package:memora/screens/onboarding/onboarding_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // Start initialization when the widget is first created.
    _initFuture = Provider.of<UserProvider>(
      context,
      listen: false,
    ).initializeUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // After initialization, check the user level.
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          if (userProvider.userLevel == null) {
            // If no level, navigate to Onboarding.
            return const OnboardingScreen();
          } else {
            // If level exists, navigate to Home.
            return const HomeScreen();
          }
        }

        // While initializing, show the splash screen UI.
        return _buildSplashScreenUI();
      },
    );
  }

  Widget _buildSplashScreenUI() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: isDarkMode
                ? [Colors.grey[900]!, Colors.black]
                : [Colors.white, theme.scaffoldBackgroundColor],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 150),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
