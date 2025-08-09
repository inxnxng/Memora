import 'package:memora/models/notion_database.dart';
import 'package:memora/models/notion_page.dart';

class NotionRouteExtra {
  final String? databaseName;
  final List<NotionPage>? pages;
  final NotionPage? page;
  final NotionDatabase? database;
  final String? pageId;
  final String? pageTitle;
  final String? chatId; // New: For existing chat sessions
  final bool isExistingChat; // New: To indicate if it's an existing chat

  NotionRouteExtra({
    this.databaseName,
    this.pages,
    this.page,
    this.database,
    this.pageId,
    this.pageTitle,
    this.chatId,
    this.isExistingChat = false, // Default to false
  });
}
