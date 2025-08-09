import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/services/auth_service.dart';
import 'package:provider/provider.dart';

/// A custom exception for authentication errors.
class AuthServiceException implements Exception {
  final String message;
  AuthServiceException(this.message);

  @override
  String toString() => message;
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    final authService = context.read<AuthService>();
    try {
      await authService.signInWithGoogle();
    } on AuthServiceException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));

        context.go(AppRoutes.home);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.loginFailed)));
      }
    }
  }

  Future<void> _signInWithGitHub(BuildContext context) async {
    final authService = context.read<AuthService>();
    try {
      await authService.signInWithGitHub();
    } on AuthServiceException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));

        context.go(AppRoutes.home);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.loginFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoPng = isDarkMode
        ? 'assets/images/login/logo_dark_transparent.png'
        : 'assets/images/login/logo_light_transparent.png';
    final googleButtonAsset = isDarkMode
        ? 'assets/images/login/ios_dark_sq_SU.svg'
        : 'assets/images/login/ios_neutral_sq_SU.svg';
    final githubButtonAsset = isDarkMode
        ? 'assets/images/login/github_dark.svg'
        : 'assets/images/login/github_light.svg';

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.loginTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Image.asset(logoPng, height: 200, width: 200),
                  const SizedBox(height: 16),
                  const Text(
                    'Memora',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '당신의 노트를 AI 퀴즈로!',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () => _signInWithGoogle(context),
                    child: SvgPicture.asset(googleButtonAsset, height: 44),
                  ),
                ),
                const SizedBox(height: 16),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: () => _signInWithGitHub(context),
                    child: SvgPicture.asset(githubButtonAsset, height: 44),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
