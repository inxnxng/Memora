import 'package:flutter/material.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/services/auth_service.dart';
import 'package:provider/provider.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await context.read<AuthService>().signOut();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text(AppStrings.logout),
    );
  }
}
