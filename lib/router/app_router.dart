import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/router/auth_notifier.dart';
import 'package:memora/router/router_refresh_notifier.dart';
import 'package:memora/screens/main_shell.dart';

import 'app_routes.dart';

GoRouter createRouter(
  RouterRefreshNotifier refreshNotifier,
  AuthNotifier authNotifier,
  UserProvider userProvider,
) {
  final redirectLogic = RedirectLogic(
    authNotifier: authNotifier,
    userProvider: userProvider,
  );

  final routes = <RouteBase>[
    AppRoutes.splashRoute,
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // 하단 바
        AppShellRoutes.reviewBranch,
        AppShellRoutes.homeBranch,
        AppShellRoutes.rankingBranch,

        // 기본 경로
        AppShellRoutes.heatmapBranch,
        AppShellRoutes.profileBranch,
        AppShellRoutes.chatBranch,
        AppShellRoutes.loginBranch,
        AppShellRoutes.onboardingBranch,
        AppShellRoutes.settingsBranch,
      ],
    ),
  ];

  return GoRouter(
    refreshListenable: refreshNotifier,
    initialLocation: AppRoutes.home,
    routes: routes,
    redirect: redirectLogic.redirect,
  );
}

class RedirectLogic {
  final AuthNotifier authNotifier;
  final UserProvider userProvider;

  RedirectLogic({required this.authNotifier, required this.userProvider});

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = authNotifier.user != null;
    final isLoading = userProvider.isLoading;
    final hasProfile = userProvider.isProfileComplete;

    final onSplash = state.matchedLocation == AppRoutes.splash;
    final onLogin = state.matchedLocation == AppRoutes.login;
    final onOnboarding = state.matchedLocation == AppRoutes.onboarding;

    if (isLoading) {
      return onSplash ? null : AppRoutes.splash;
    }
    if (!isLoggedIn) {
      return onLogin ? null : AppRoutes.login;
    }
    if (!hasProfile) {
      return onOnboarding ? null : AppRoutes.onboarding;
    }
    if (onSplash || onLogin || onOnboarding) {
      return AppRoutes.home;
    }
    return null;
  }
}
