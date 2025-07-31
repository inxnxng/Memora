import 'package:flutter/material.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/screens/home_screen.dart';
import 'package:memora/screens/onboarding/onboarding_screen.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return _buildSplashScreenUI(context);
        }

        // After loading, check the user level.
        if (userProvider.userLevel == null) {
          // If no level, navigate to Onboarding.
          return const OnboardingScreen();
        } else {
          // If level exists, navigate to Home.
          return const HomeScreen();
        }
      },
    );
  }

  Widget _buildSplashScreenUI(BuildContext context) {
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
