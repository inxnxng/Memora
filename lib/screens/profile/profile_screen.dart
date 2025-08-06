import 'package:flutter/material.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/screens/profile/widgets/edit_profile_card.dart';
import 'package:memora/screens/profile/widgets/logout_button.dart';
import 'package:memora/screens/profile/widgets/profile_card.dart';
import 'package:memora/screens/profile/widgets/ranking_card.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: AppStrings.profileTitle),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileCard(userProvider: userProvider),
                  const SizedBox(height: 20),
                  RankingCard(userRank: userProvider.userRank),
                  const SizedBox(height: 20),
                  const EditProfileCard(),
                  const SizedBox(height: 40),
                  const LogoutButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}