import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memora/data/datasources/openai_remote_data_source.dart';
import 'package:memora/domain/usecases/chat_usecases.dart';
import 'package:memora/domain/usecases/notion_usecases.dart';
import 'package:memora/domain/usecases/openai_usecases.dart';
import 'package:memora/domain/usecases/task_usecases.dart';
import 'package:memora/domain/usecases/user_usecases.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/repositories/chat_repository.dart';
import 'package:memora/repositories/notion_auth_repository.dart';
import 'package:memora/repositories/notion_database_repository.dart';
import 'package:memora/repositories/notion_repository.dart';
import 'package:memora/repositories/openai_api_key_repository.dart';
import 'package:memora/repositories/openai_repository.dart';
import 'package:memora/repositories/task_repository.dart';
import 'package:memora/screens/splash_screen.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(
    MultiProvider(
      providers: [
        // Foundational Services & Repositories
        Provider<LocalStorageService>(create: (_) => LocalStorageService()),
        Provider<NotionAuthRepository>(create: (_) => NotionAuthRepository()),
        Provider<NotionDatabaseRepository>(
          create: (_) => NotionDatabaseRepository(),
        ),
        Provider<OpenAIApiKeyRepository>(
          create: (context) =>
              OpenAIApiKeyRepository(context.read<LocalStorageService>()),
        ),
        Provider<NotionRepository>(
          create: (context) => NotionRepository(
            authRepository: context.read<NotionAuthRepository>(),
          ),
        ),
        Provider<OpenAIRemoteDataSource>(
          create: (context) => OpenAIRemoteDataSource(
            apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
          ),
        ),
        Provider<OpenAIRepository>(
          create: (context) => OpenAIRepository(
            remoteDataSource: context.read<OpenAIRemoteDataSource>(),
            apiKeyRepository: context.read<OpenAIApiKeyRepository>(),
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

        // Usecase Classes
        Provider<NotionUsecases>(
          create: (context) => NotionUsecases(
            notionAuthRepository: context.read<NotionAuthRepository>(),
            notionDatabaseRepository: context.read<NotionDatabaseRepository>(),
            notionRepository: context.read<NotionRepository>(),
          ),
        ),
        Provider<OpenAIUsecases>(
          create: (context) => OpenAIUsecases(
            apiKeyRepository: context.read<OpenAIApiKeyRepository>(),
            openAIRepository: context.read<OpenAIRepository>(),
          ),
        ),
        Provider<ChatUsecases>(
          create: (context) => ChatUsecases(context.read<ChatRepository>()),
        ),
        Provider<TaskUsecases>(
          create: (context) => TaskUsecases(context.read<TaskRepository>()),
        ),
        Provider<UserUsecases>(
          create: (context) =>
              UserUsecases(context.read<LocalStorageService>()),
        ),

        // App-level Services
        Provider<OpenAIService>(
          create: (context) => OpenAIService(context.read<OpenAIUsecases>()),
        ),
        Provider<ChatService>(
          create: (context) => ChatService(context.read<ChatUsecases>()),
        ),

        // ChangeNotifierProviders (UI-level state)
        ChangeNotifierProvider(
          create: (context) => NotionProvider(
            notionUsecases: context.read<NotionUsecases>(),
            openAIUsecases: context.read<OpenAIUsecases>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              TaskProvider(taskUsecases: context.read<TaskUsecases>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              UserProvider(userUsecases: context.read<UserUsecases>()),
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
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
