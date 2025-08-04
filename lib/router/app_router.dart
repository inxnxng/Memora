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
  final routes = <RouteBase>[
    AppRoutes.splashRoute,
    AppRoutes.loginRoute,
    AppRoutes.onboardingRoute,
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        AppShellRoutes.reviewBranch,
        AppShellRoutes.homeBranch,
        AppShellRoutes.profileBranch,
      ],
    ),
    AppRoutes.settingsRoute,
  ];

  return GoRouter(
    refreshListenable: refreshNotifier,
    initialLocation: AppRoutes.splash,
    routes: routes,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authNotifier.user != null;
      final isLoading = userProvider.isLoading;
      final hasProfile = userProvider.isProfileComplete;

      final onSplash = state.matchedLocation == AppRoutes.splash;
      final onLogin = state.matchedLocation == AppRoutes.login;
      final onOnboarding = state.matchedLocation == AppRoutes.onboarding;

      // If the app is still loading, show the splash screen.
      // A brief moment of loading is expected when the app starts.
      if (isLoading) {
        return onSplash ? null : AppRoutes.splash;
      }

      // If the user is not logged in, they must go to the login screen.
      if (!isLoggedIn) {
        return onLogin ? null : AppRoutes.login;
      }

      // At this point, the user is logged in and data has been loaded.
      // If they don't have a profile, they must go to onboarding.
      if (!hasProfile) {
        return onOnboarding ? null : AppRoutes.onboarding;
      }

      // If the user is logged in and has a profile, but is currently on
      // the splash, login, or onboarding screen, redirect them to home.
      if (onSplash || onLogin || onOnboarding) {
        return AppRoutes.home;
      }

      // No redirect needed.
      return null;
    },
  );
}
