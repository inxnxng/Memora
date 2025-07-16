/*import 'package:firebase_core/firebase_core.dart';*/
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memora/data/datasources/openai_remote_data_source.dart';
import 'package:memora/data/repositories/chat_repository_impl.dart';
import 'package:memora/data/repositories/notion_auth_repository_impl.dart';
import 'package:memora/data/repositories/notion_database_repository_impl.dart';
import 'package:memora/data/repositories/notion_repository_impl.dart';
import 'package:memora/data/repositories/openai_api_key_repository_impl.dart';
import 'package:memora/data/repositories/openai_repository_impl.dart';
import 'package:memora/data/repositories/task_repository_impl.dart';
import 'package:memora/domain/repositories/chat_repository.dart';
import 'package:memora/domain/repositories/notion_auth_repository.dart';
import 'package:memora/domain/repositories/notion_database_repository.dart';
import 'package:memora/domain/repositories/notion_repository.dart';
import 'package:memora/domain/repositories/openai_api_key_repository.dart';
import 'package:memora/domain/repositories/openai_repository.dart';
import 'package:memora/domain/repositories/task_repository.dart';
import 'package:memora/domain/usecases/check_openai_api_key_availability.dart';
import 'package:memora/domain/usecases/clear_chat_history.dart';
import 'package:memora/domain/usecases/clear_notion_api_token.dart';
import 'package:memora/domain/usecases/clear_notion_database_info.dart';
import 'package:memora/domain/usecases/create_quiz_from_text.dart';
import 'package:memora/domain/usecases/fetch_tasks.dart';
import 'package:memora/domain/usecases/generate_training_content.dart';
import 'package:memora/domain/usecases/get_database_info.dart';
import 'package:memora/domain/usecases/get_notion_api_token.dart';
import 'package:memora/domain/usecases/get_notion_database.dart';
import 'package:memora/domain/usecases/get_notion_database_id.dart';
import 'package:memora/domain/usecases/get_notion_database_title.dart';
import 'package:memora/domain/usecases/get_notion_info.dart';
import 'package:memora/domain/usecases/get_openai_api_key.dart';
import 'package:memora/domain/usecases/get_page_content.dart';
import 'package:memora/domain/usecases/get_pages_from_db.dart';
import 'package:memora/domain/usecases/get_quiz_data_from_db.dart';
import 'package:memora/domain/usecases/get_roadmap_tasks_from_db.dart';
import 'package:memora/domain/usecases/load_chat_history.dart';
import 'package:memora/domain/usecases/load_last_trained_date.dart';
import 'package:memora/domain/usecases/save_chat_history.dart';
import 'package:memora/domain/usecases/save_last_trained_date.dart';
import 'package:memora/domain/usecases/save_notion_api_token.dart';
import 'package:memora/domain/usecases/save_notion_database.dart';
import 'package:memora/domain/usecases/save_notion_database_id.dart';
import 'package:memora/domain/usecases/save_notion_database_title.dart';
import 'package:memora/domain/usecases/save_openai_api_key.dart';
import 'package:memora/domain/usecases/search_notion_databases.dart';
import 'package:memora/domain/usecases/toggle_task_completion.dart';
import 'package:memora/providers/notion_provider.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/screens/home_screen.dart';
import 'package:memora/services/chat_service.dart';
/*import 'package:memora/services/firebase_service.dart';*/
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  /*await Firebase.initializeApp();*/

  runApp(
    MultiProvider(
      providers: [
        Provider<LocalStorageService>(create: (_) => LocalStorageService()),
        // OpenAI API Key related
        Provider<OpenAIApiKeyRepository>(
          create: (context) =>
              OpenAIApiKeyRepositoryImpl(context.read<LocalStorageService>()),
        ),
        Provider<GetOpenAIApiKey>(
          create: (context) =>
              GetOpenAIApiKey(context.read<OpenAIApiKeyRepository>()),
        ),
        Provider<SaveOpenAIApiKey>(
          create: (context) =>
              SaveOpenAIApiKey(context.read<OpenAIApiKeyRepository>()),
        ),
        Provider<CheckOpenAIApiKeyAvailability>(
          create: (context) => CheckOpenAIApiKeyAvailability(
            context.read<OpenAIApiKeyRepository>(),
          ),
        ),
        // OpenAI API interaction related
        Provider<OpenAIRemoteDataSource>(
          create: (context) => OpenAIRemoteDataSource(
            apiKey: dotenv.env['OPENAI_API_KEY'] ?? '',
          ),
        ),
        Provider<OpenAIRepository>(
          create: (context) => OpenAIRepositoryImpl(
            remoteDataSource: context.read<OpenAIRemoteDataSource>(),
            apiKeyRepository: context.read<OpenAIApiKeyRepository>(),
          ),
        ),
        Provider<GenerateTrainingContent>(
          create: (context) =>
              GenerateTrainingContent(context.read<OpenAIRepository>()),
        ),
        Provider<CreateQuizFromText>(
          create: (context) =>
              CreateQuizFromText(context.read<OpenAIRepository>()),
        ),
        Provider<OpenAIService>(
          create: (context) => OpenAIService(
            context.read<GenerateTrainingContent>(),
            context.read<CreateQuizFromText>(),
          ),
        ),
        // Notion Auth related
        Provider<NotionAuthRepository>(
          create: (_) => NotionAuthRepositoryImpl(),
        ),
        Provider<GetNotionApiToken>(
          create: (context) =>
              GetNotionApiToken(context.read<NotionAuthRepository>()),
        ),
        Provider<SaveNotionApiToken>(
          create: (context) =>
              SaveNotionApiToken(context.read<NotionAuthRepository>()),
        ),
        Provider<ClearNotionApiToken>(
          create: (context) =>
              ClearNotionApiToken(context.read<NotionAuthRepository>()),
        ),
        // Notion Database related
        Provider<NotionDatabaseRepository>(
          create: (_) => NotionDatabaseRepositoryImpl(),
        ),
        Provider<GetNotionDatabaseId>(
          create: (context) =>
              GetNotionDatabaseId(context.read<NotionDatabaseRepository>()),
        ),
        Provider<SaveNotionDatabaseId>(
          create: (context) =>
              SaveNotionDatabaseId(context.read<NotionDatabaseRepository>()),
        ),
        Provider<GetNotionDatabaseTitle>(
          create: (context) =>
              GetNotionDatabaseTitle(context.read<NotionDatabaseRepository>()),
        ),
        Provider<SaveNotionDatabaseTitle>(
          create: (context) =>
              SaveNotionDatabaseTitle(context.read<NotionDatabaseRepository>()),
        ),
        Provider<GetNotionDatabase>(
          create: (context) =>
              GetNotionDatabase(context.read<NotionDatabaseRepository>()),
        ),
        Provider<SaveNotionDatabase>(
          create: (context) =>
              SaveNotionDatabase(context.read<NotionDatabaseRepository>()),
        ),
        Provider<ClearNotionDatabaseInfo>(
          create: (context) =>
              ClearNotionDatabaseInfo(context.read<NotionDatabaseRepository>()),
        ),
        Provider<GetNotionInfo>(
          create: (context) =>
              GetNotionInfo(context.read<NotionDatabaseRepository>()),
        ),
        // Notion API interaction related
        Provider<NotionRepository>(
          create: (context) => NotionRepositoryImpl(
            authRepository: context.read<NotionAuthRepository>(),
          ),
        ),
        Provider<GetPagesFromDB>(
          create: (context) => GetPagesFromDB(context.read<NotionRepository>()),
        ),
        Provider<GetDatabaseInfo>(
          create: (context) =>
              GetDatabaseInfo(context.read<NotionRepository>()),
        ),
        Provider<GetPageContent>(
          create: (context) => GetPageContent(context.read<NotionRepository>()),
        ),
        Provider<SearchNotionDatabases>(
          create: (context) =>
              SearchNotionDatabases(context.read<NotionRepository>()),
        ),
        Provider<GetRoadmapTasksFromDB>(
          create: (context) =>
              GetRoadmapTasksFromDB(context.read<NotionRepository>()),
        ),
        Provider<GetQuizDataFromDB>(
          create: (context) =>
              GetQuizDataFromDB(context.read<NotionRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => NotionProvider(
            saveNotionApiToken: context.read<SaveNotionApiToken>(),
            clearNotionApiToken: context.read<ClearNotionApiToken>(),
            saveNotionDatabaseId: context.read<SaveNotionDatabaseId>(),
            saveNotionDatabaseTitle: context.read<SaveNotionDatabaseTitle>(),
            saveNotionDatabase: context.read<SaveNotionDatabase>(),
            clearNotionDatabaseInfo: context.read<ClearNotionDatabaseInfo>(),
            getNotionInfo: context.read<GetNotionInfo>(),
            getPagesFromDB: context.read<GetPagesFromDB>(),
            getDatabaseInfo: context.read<GetDatabaseInfo>(),
            getPageContent: context.read<GetPageContent>(),
            searchNotionDatabases: context.read<SearchNotionDatabases>(),
            getRoadmapTasksFromDB: context.read<GetRoadmapTasksFromDB>(),
            createQuizFromText: context.read<CreateQuizFromText>(),
          ),
        ),
        // Task related
        Provider<TaskRepository>(
          create: (context) => TaskRepositoryImpl(
            context.read<NotionRepository>(),
            context.read<LocalStorageService>(),
          ),
        ),
        Provider<FetchTasks>(
          create: (context) => FetchTasks(context.read<TaskRepository>()),
        ),
        Provider<ToggleTaskCompletion>(
          create: (context) =>
              ToggleTaskCompletion(context.read<TaskRepository>()),
        ),
        Provider<LoadLastTrainedDate>(
          create: (context) =>
              LoadLastTrainedDate(context.read<TaskRepository>()),
        ),
        Provider<SaveLastTrainedDate>(
          create: (context) =>
              SaveLastTrainedDate(context.read<TaskRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(
            fetchTasksUseCase: context.read<FetchTasks>(),
            toggleTaskCompletionUseCase: context.read<ToggleTaskCompletion>(),
            loadLastTrainedDateUseCase: context.read<LoadLastTrainedDate>(),
          ),
        ),
        // Chat related
        Provider<ChatRepository>(
          create: (context) =>
              ChatRepositoryImpl(context.read<LocalStorageService>()),
        ),
        Provider<LoadChatHistory>(
          create: (context) => LoadChatHistory(context.read<ChatRepository>()),
        ),
        Provider<SaveChatHistory>(
          create: (context) => SaveChatHistory(context.read<ChatRepository>()),
        ),
        Provider<ClearChatHistory>(
          create: (context) => ClearChatHistory(context.read<ChatRepository>()),
        ),
        Provider<ChatService>(
          create: (context) => ChatService(
            context.read<LoadChatHistory>(),
            context.read<SaveChatHistory>(),
            context.read<ClearChatHistory>(),
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
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
