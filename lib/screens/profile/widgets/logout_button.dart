import 'package:flutter/material.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/services/auth_service.dart';
import 'package:provider/provider.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: () async {
        await context.read<AuthService>().signOut();
      },
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        AppStrings.logout,
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
