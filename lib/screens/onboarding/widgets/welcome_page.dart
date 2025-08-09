import 'package:flutter/material.dart';
import 'package:memora/constants/app_strings.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNextPage;

  const WelcomePage({super.key, required this.onNextPage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Memora에 오신 것을',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Text(
            '환영합니다!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            '더 나은 사용을 위해,',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const Text(
            '당신의 학습 레벨을 선택해주세요.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: onNextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(AppStrings.getStarted),
          ),
        ],
      ),
    );
  }
}
