import 'package:flutter/material.dart';
import 'package:memora/domain/usecases/user_usecases.dart';
import 'package:memora/screens/home_screen.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  String? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildWelcomePage(), _buildLevelSelectionPage()],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome to Memora!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'To personalize your experience, please select your learning level.',
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              );
            },
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select Your Level',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildLevelOption('beginner', 'Beginner', '3 sessions/day'),
          _buildLevelOption('intermediate', 'Intermediate', '5 sessions/day'),
          _buildLevelOption('expert', 'Expert', '7 sessions/day'),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _selectedLevel == null ? null : _saveLevel,
            child: const Text('Save and Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelOption(String level, String title, String subtitle) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: level,
      groupValue: _selectedLevel,
      onChanged: (value) {
        setState(() {
          _selectedLevel = value;
        });
      },
    );
  }

  void _saveLevel() async {
    if (_selectedLevel != null) {
      final userUsecases = Provider.of<UserUsecases>(context, listen: false);
      // Note: This assumes a method to get the current user ID exists.
      // For now, we'll use a placeholder ID.
      // In a real app, you'd get this from your auth solution.
      const userId = 'anonymous_user'; // Placeholder
      await userUsecases.saveUserLevel(userId, _selectedLevel!);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }
}
