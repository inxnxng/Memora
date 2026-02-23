import 'package:memora/models/notion_database.dart';
import 'package:memora/models/notion_page.dart';

class NotionRouteExtra {
  final String? databaseName;
  final List<NotionPage>? pages;
  final NotionPage? page;
  final NotionDatabase? database;
  final String? pageId;
  final String? pageTitle;
  final String? url;
  final String? chatId; // New: For existing chat sessions
  final bool isExistingChat; // New: To indicate if it's an existing chat
  /// 학습 현황에서 들어온 경우 등, 이미 학습 완료된 페이지로 간주하고 완료 상태로 표시
  final bool alreadyCompleted;

  NotionRouteExtra({
    this.databaseName,
    this.pages,
    this.page,
    this.database,
    this.pageId,
    this.pageTitle,
    this.url,
    this.chatId,
    this.isExistingChat = false,
    this.alreadyCompleted = false,
  });
}
