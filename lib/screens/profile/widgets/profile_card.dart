import 'package:flutter/material.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/providers/user_provider.dart';

class ProfileCard extends StatelessWidget {
  final UserProvider userProvider;

  const ProfileCard({super.key, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage:
                  userProvider.photoURL != null &&
                      userProvider.photoURL!.isNotEmpty
                  ? NetworkImage(userProvider.photoURL!)
                  : null,
              child:
                  userProvider.photoURL == null ||
                      userProvider.photoURL!.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 40,
                      color: theme.colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              userProvider.displayName ?? AppStrings.noName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (userProvider.email != null &&
                userProvider.email!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                userProvider.email!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileStat(
                  context,
                  '${userProvider.streakCount}',
                  AppStrings.streak,
                  Icons.local_fire_department_outlined,
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: theme.colorScheme.outlineVariant,
                ),
                _buildProfileStat(
                  context,
                  userProvider.userLevel?.displayName ?? AppStrings.notSet,
                  AppStrings.proficiency,
                  Icons.trending_up_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
