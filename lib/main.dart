import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memora/data/datasources/openai_remote_data_source.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/repositories/chat/chat_repository.dart';
import 'package:memora/repositories/notion/notion_auth_repository.dart';
import 'package:memora/repositories/notion/notion_database_repository.dart';
import 'package:memora/repositories/notion/notion_repository.dart';
import 'package:memora/repositories/openai/openai_auth_repository.dart';
import 'package:memora/repositories/openai/openai_repository.dart';
import 'package:memora/repositories/task/task_repository.dart';
import 'package:memora/repositories/user/user_repository.dart';
import 'package:memora/screens/auth_gate.dart';
import 'package:memora/services/auth_service.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/services/notion_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/services/settings_service.dart';
import 'package:memora/services/task_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        // Foundational Services & Repositories
        Provider<LocalStorageService>(create: (_) => LocalStorageService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<SettingsService>(
          create: (context) =>
              SettingsService(context.read<LocalStorageService>()),
        ),
        Provider<NotionAuthRepository>(
          create: (context) =>
              NotionAuthRepository(context.read<LocalStorageService>()),
        ),
        Provider<NotionDatabaseRepository>(
          create: (_) => NotionDatabaseRepository(),
        ),
        Provider<NotionRepository>(
          create: (context) => NotionRepository(
            notionAuthRepository: context.read<NotionAuthRepository>(),
          ),
        ),

        Provider<OpenAIAuthRepository>(
          create: (context) =>
              OpenAIAuthRepository(context.read<LocalStorageService>()),
        ),
        Provider<OpenAIRemoteDataSource>(
          create: (context) => OpenAIRemoteDataSource(),
        ),
        Provider<OpenAIRepository>(
          create: (context) => OpenAIRepository(
            remoteDataSource: context.read<OpenAIRemoteDataSource>(),
            authRepository: context.read<OpenAIAuthRepository>(),
          ),
        ),
        Provider<TaskRepository>(
          create: (context) => TaskRepository(
            context.read<NotionRepository>(),
            context.read<LocalStorageService>(),
          ),
        ),
        Provider<ChatRepository>(
          create: (context) =>
              ChatRepository(context.read<LocalStorageService>()),
        ),
        Provider<UserRepository>(
          create: (context) =>
              UserRepository(context.read<LocalStorageService>()),
        ),

        // Business Logic Services
        Provider<NotionService>(
          create: (context) => NotionService(
            notionAuthRepository: context.read<NotionAuthRepository>(),
            notionDatabaseRepository: context.read<NotionDatabaseRepository>(),
            notionRepository: context.read<NotionRepository>(),
          ),
        ),
        Provider<OpenAIService>(
          create: (context) => OpenAIService(
            openAIAuthRepository: context.read<OpenAIAuthRepository>(),
            openAIRepository: context.read<OpenAIRepository>(),
          ),
        ),
        Provider<ChatService>(
          create: (context) => ChatService(context.read<ChatRepository>()),
        ),
        Provider<TaskService>(
          create: (context) => TaskService(context.read<TaskRepository>()),
        ),

        // ChangeNotifierProviders (UI-level state)
        ChangeNotifierProvider(
          create: (context) =>
              UserProvider(userRepository: context.read<UserRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => NotionProvider(
            notionService: context.read<NotionService>(),
            openAIService: context.read<OpenAIService>(),
          )..initialize(),
        ),
        ChangeNotifierProxyProvider<NotionProvider, TaskProvider>(
          create: (context) => TaskProvider(
            taskService: context.read<TaskService>(),
            notionDatabaseId: null, // Initial value
          ),
          update: (context, notionProvider, previousTaskProvider) =>
              TaskProvider(
                taskService: context.read<TaskService>(),
                notionDatabaseId: notionProvider.databaseId,
              ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
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
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}
