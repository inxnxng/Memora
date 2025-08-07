import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/router/app_router.dart';
import 'package:memora/router/auth_notifier.dart';
import 'package:memora/router/router_refresh_notifier.dart';
import 'package:memora/services/notification_service.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  late final RouterRefreshNotifier _refreshNotifier;

  @override
  void initState() {
    super.initState();
    context.read<NotificationService>().initialize();
    context.read<NotionProvider>().initialize();
    final authNotifier = context.read<AuthNotifier>();
    final userProvider = context.read<UserProvider>();
    _refreshNotifier = RouterRefreshNotifier(authNotifier, userProvider);
    _router = createRouter(_refreshNotifier, authNotifier, userProvider);
  }

  @override
  void dispose() {
    _refreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Memora',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.getTextTheme('Noto Sans KR'),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.getTextTheme(
          'Noto Sans KR',
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[900],
        dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]),
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
    );
  }
}
