import 'package:flutter/material.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/providers/user_provider.dart';

class ProfileCard extends StatelessWidget {
  final UserProvider userProvider;

  const ProfileCard({super.key, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (userProvider.photoURL != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(userProvider.photoURL!),
              ),
            const SizedBox(height: 16),
            Text(
              userProvider.displayName ?? AppStrings.noName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (userProvider.email != null)
              Text(
                userProvider.email!,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfileStat(
                  '${userProvider.streakCount}',
                  AppStrings.streak,
                ),
                _buildProfileStat(
                  userProvider.userLevel?.displayName ?? AppStrings.notSet,
                  AppStrings.proficiency,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
