import 'package:flutter/material.dart';
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
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:provider/provider.dart';

/// Wraps a widget with all necessary providers for testing.
///
/// This helper function sets up a test environment that mirrors the
/// provider configuration in `main.dart`, allowing widgets to be
/// tested in isolation.
Widget createTestableWidget({required Widget child}) {
  return MultiProvider(
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
      // Mocking OpenAIRemoteDataSource as it might need a real API key
      Provider<OpenAIRemoteDataSource>(
        create: (context) => OpenAIRemoteDataSource(apiKey: 'test_api_key'),
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
    child: MaterialApp(
      home: child,
    ),
  );
}
