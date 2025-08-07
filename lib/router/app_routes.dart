// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

import 'package:go_router/go_router.dart';
import 'package:memora/screens/heatmap/heatmap_screen.dart';
import 'package:memora/screens/home_screen.dart';
import 'package:memora/screens/login_screen.dart';
import 'package:memora/screens/onboarding/onboarding_screen.dart';
import 'package:memora/screens/profile/change_level_screen.dart';
import 'package:memora/screens/profile/profile_screen.dart';
import 'package:memora/screens/ranking/ranking_screen.dart';
import 'package:memora/screens/review/chat_history_screen.dart';
import 'package:memora/screens/review/notion_page_viewer_screen.dart';
import 'package:memora/screens/review/notion_quiz_chat_screen.dart';
import 'package:memora/screens/review/quiz_screen.dart';
import 'package:memora/screens/review/til_review_selection_screen.dart';
import 'package:memora/screens/settings/gemini_settings_screen.dart';
import 'package:memora/screens/settings/heatmap_color_settings_screen.dart';
import 'package:memora/screens/settings/notification_settings_screen.dart';
import 'package:memora/screens/settings/notion_settings_screen.dart';
import 'package:memora/screens/settings/openai_settings_screen.dart';
import 'package:memora/screens/settings/settings_screen.dart';
import 'package:memora/screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String review = '/review';
  static const String notionPage = 'notion-page/:pageId';
  static const String quiz = 'quiz';
  static const String quizChat = 'chat';
  static const String chatHistory = 'history';
  static const String ranking = '/ranking';
  static const String home = '/home';
  static const String heatmap = '/heatmap';
  static const String profile = '/profile';
  static const String changeLevel = 'change-level';
  static const String settings = '/settings';
  static const String heatmapColorSettings = 'heatmap-color';
  static const String notionSettings = 'notion';
  static const String openaiSettings = 'openai';
  static const String geminiSettings = 'gemini';
  static const String notificationSettings = 'notifications';

  static GoRoute get splashRoute =>
      GoRoute(path: splash, builder: (context, state) => const SplashScreen());

  static GoRoute get loginRoute =>
      GoRoute(path: login, builder: (context, state) => const LoginScreen());

  static GoRoute get onboardingRoute => GoRoute(
    path: onboarding,
    builder: (context, state) => const OnboardingScreen(),
  );

  static GoRoute get settingsRoute => GoRoute(
    path: settings,
    builder: (context, state) => const SettingsScreen(),
    routes: [
      GoRoute(
        path: heatmapColorSettings,
        builder: (context, state) => const HeatmapColorSettingsScreen(),
      ),
      GoRoute(
        path: notionSettings,
        builder: (context, state) => const NotionSettingsScreen(),
      ),
      GoRoute(
        path: openaiSettings,
        builder: (context, state) => const OpenaiSettingsScreen(),
      ),
      GoRoute(
        path: geminiSettings,
        builder: (context, state) => const GeminiSettingsScreen(),
      ),
      GoRoute(
        path: notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
    ],
  );
}

class AppShellRoutes {
  static StatefulShellBranch get reviewBranch => StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.review,
        builder: (context, state) => const TilReviewSelectionScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.chatHistory,
            builder: (context, state) => const ChatHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.notionPage,
            builder: (context, state) {
              final pageId = state.pathParameters['pageId']!;
              final pageTitle = state.uri.queryParameters['pageTitle']!;
              final databaseName = state.uri.queryParameters['databaseName']!;
              return NotionPageViewerScreen(
                pageId: pageId,
                pageTitle: pageTitle,
                databaseName: databaseName,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.quiz,
            builder: (context, state) => const QuizScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.quizChat,
                builder: (context, state) {
                  final extra = state.extra as Map<String, String>;
                  final pageTitle = extra['pageTitle']!;
                  final pageContent = extra['pageContent']!;
                  final databaseName = extra['databaseName']!;
                  return NotionQuizChatScreen(
                    pageTitle: pageTitle,
                    pageContent: pageContent,
                    databaseName: databaseName,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );

  static StatefulShellBranch get rankingBranch => StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.ranking,
        builder: (context, state) => const RankingScreen(),
      ),
    ],
  );

  static StatefulShellBranch get homeBranch => StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );

  static StatefulShellBranch get heatmapBranch => StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.heatmap,
        builder: (context, state) => const HeatmapScreen(),
      ),
    ],
  );

  static StatefulShellBranch get profileBranch => StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.changeLevel,
            builder: (context, state) => const ChangeLevelScreen(),
          ),
        ],
      ),
    ],
  );
}
