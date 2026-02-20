// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

import 'package:go_router/go_router.dart';
import 'package:memora/constants/app_strings.dart';
import 'package:memora/models/notion_route_extra.dart';
import 'package:memora/screens/heatmap/heatmap_screen.dart';
import 'package:memora/screens/home_screen.dart';
import 'package:memora/screens/login_screen.dart';
import 'package:memora/screens/onboarding/onboarding_screen.dart';
import 'package:memora/screens/profile/change_level_screen.dart';
import 'package:memora/screens/profile/profile_screen.dart';
import 'package:memora/screens/ranking/ranking_screen.dart';
import 'package:memora/screens/review/chat_history_screen.dart';
import 'package:memora/screens/review/chat_screen.dart';
import 'package:memora/screens/review/notion_page_viewer_screen.dart';
import 'package:memora/screens/review/review_selection_screen.dart';
import 'package:memora/screens/settings/ai_model_settings_screen.dart';
import 'package:memora/screens/settings/gemini_settings_screen.dart';
import 'package:memora/screens/settings/heatmap_color_settings_screen.dart';
import 'package:memora/screens/settings/notion_settings_screen.dart';
import 'package:memora/screens/settings/openai_settings_screen.dart';
import 'package:memora/screens/settings/settings_screen.dart';
import 'package:memora/screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';

  static const String ranking = '/ranking';
  static const String home = '/home';
  static const String heatmap = '/heatmap';
  static const String profile = '/profile';
  static const String changeLevel = 'change-level';

  static const String review = '/review';
  static const String notionPage = 'notion-page';
  static const String chatHistory = 'chatHistory';

  static const String chat = '/chat';

  static const String settings = '/settings';
  static const String heatmapColorSettings = 'heatmap-color';
  static const String notionSettings = 'notion';
  static const String openaiSettings = 'openai';
  static const String geminiSettings = 'gemini';
  static const String aiModelSettings = 'ai-model';

  static GoRoute get splashRoute =>
      GoRoute(path: splash, builder: (context, state) => const SplashScreen());
}

class AppShellRoutes {
  static final StatefulShellBranch reviewBranch = StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.review,
        builder: (context, state) => const ReviewSelectionScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.notionPage,
            builder: (context, state) {
              final routeExtra = state.extra as NotionRouteExtra;
              final pageId = routeExtra.pageId ?? '';
              final pageTitle = routeExtra.pageTitle ?? '';
              final url = routeExtra.url;
              final databaseName =
                  routeExtra.databaseName ?? AppStrings.unknownDb;
              return NotionPageViewerScreen(
                pageId: pageId,
                pageTitle: pageTitle,
                databaseName: databaseName,
                url: url,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.chatHistory,
            builder: (context, state) => const ChatHistoryScreen(),
          ),
        ],
      ),
    ],
  );
  static final StatefulShellBranch loginBranch = StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
  static final StatefulShellBranch onboardingBranch = StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
  //chat
  static final StatefulShellBranch chatBranch = StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final routeExtra = state.extra as NotionRouteExtra;
          return ChatScreen(
            pages: routeExtra.pages ?? [],
            databaseName: routeExtra.databaseName ?? AppStrings.unknownDb,
          );
        },
      ),
    ],
  );
  // ranking
  static final StatefulShellBranch rankingBranch = StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.ranking,
        builder: (context, state) => const RankingScreen(),
      ),
    ],
  );

  // home
  static final StatefulShellBranch homeBranch = StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );

  // heatmap
  static final StatefulShellBranch heatmapBranch = StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.heatmap,
        builder: (context, state) => const HeatmapScreen(),
      ),
    ],
  );

  // profile
  static final StatefulShellBranch profileBranch = StatefulShellBranch(
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

  //settings
  static final StatefulShellBranch settingsBranch = StatefulShellBranch(
    routes: [
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.heatmapColorSettings,
            builder: (context, state) => const HeatmapColorSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.notionSettings,
            builder: (context, state) => const NotionSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.openaiSettings,
            builder: (context, state) => const OpenaiSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.geminiSettings,
            builder: (context, state) => const GeminiSettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.aiModelSettings,
            builder: (context, state) => const AiModelSettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
