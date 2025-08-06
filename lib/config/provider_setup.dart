import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:memora/app.dart';
import 'package:memora/data/datasources/notion_remote_data_source.dart';
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
import 'package:memora/repositories/ranking/ranking_repository.dart';
import 'package:memora/repositories/task/task_repository.dart';
import 'package:memora/repositories/user/user_repository.dart';
import 'package:memora/router/auth_notifier.dart';
import 'package:memora/services/auth_service.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/firebase_service.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/services/notification_service.dart';
import 'package:memora/services/notion_service.dart';
import 'package:memora/services/notion_to_markdown_converter.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/services/settings_service.dart';
import 'package:memora/services/task_service.dart';
import 'package:provider/provider.dart';

class ProviderContainer extends StatelessWidget {
  const ProviderContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Foundational Services & Repositories
        Provider<NotificationService>(
          create: (_) => NotificationService()..initialize(),
        ),
        Provider<LocalStorageService>(create: (_) => LocalStorageService()),
        Provider<AuthService>(
          create: (context) => AuthService(
            context.read<UserRepository>(),
            userRepository: context.read<UserRepository>(),
          ),
        ),
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
        Provider<NotionRemoteDataSource>(
          create: (_) => NotionRemoteDataSource(),
        ),
        Provider<NotionRepository>(
          create: (context) => NotionRepository(
            notionAuthRepository: context.read<NotionAuthRepository>(),
            remoteDataSource: context.read<NotionRemoteDataSource>(),
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
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        Provider<TaskRepository>(
          create: (context) => TaskRepository(
            context.read<NotionRepository>(),
            context.read<LocalStorageService>(),
          ),
        ),
        Provider<ChatRepository>(
          create: (context) => ChatRepository(context.read<FirebaseService>()),
        ),
        Provider<UserRepository>(
          create: (context) => UserRepository(
            context.read<LocalStorageService>(),
            FirebaseFirestore.instance,
          ),
        ),
        Provider<RankingRepository>(
          create: (context) => RankingRepository(FirebaseFirestore.instance),
        ),

        // Business Logic Services
        Provider<NotionToMarkdownConverter>(
          create: (_) => NotionToMarkdownConverter(),
        ),
        Provider<NotionService>(
          create: (context) => NotionService(
            notionAuthRepository: context.read<NotionAuthRepository>(),
            notionDatabaseRepository: context.read<NotionDatabaseRepository>(),
            notionRepository: context.read<NotionRepository>(),
            notionToMarkdownConverter: context
                .read<NotionToMarkdownConverter>(),
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
        ChangeNotifierProvider<AuthNotifier>(create: (_) => AuthNotifier()),
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(
            userRepository: context.read<UserRepository>(),
            rankingRepository: context.read<RankingRepository>(),
          ),
        ),
        ChangeNotifierProvider<NotionProvider>(
          create: (context) => NotionProvider(
            notionService: context.read<NotionService>(),
            openAIService: context.read<OpenAIService>(),
          )..initialize(),
        ),
        ChangeNotifierProxyProvider<NotionProvider, TaskProvider>(
          create: (context) => TaskProvider(
            taskService: context.read<TaskService>(),
            settingsService: context.read<SettingsService>(),
            notionDatabaseId: null,
          ),
          update: (context, notionProvider, previousTaskProvider) =>
              TaskProvider(
                taskService: context.read<TaskService>(),
                settingsService: context.read<SettingsService>(),
                notionDatabaseId: notionProvider.databaseId,
              ),
        ),
      ],
      child: const MyApp(),
    );
  }
}
