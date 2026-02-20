import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memora/models/chat_session.dart';
import 'package:memora/models/notion_route_extra.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  late Future<List<ChatSession>> _sessionsFuture;
  bool _isSelectionMode = false;
  final Set<String> _selectedChatIds = {};

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  void _loadChatSessions() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    setState(() {
      _sessionsFuture = chatService.getAllChatSessions();
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedChatIds.clear();
      }
    });
  }

  void _onSessionSelected(String chatId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedChatIds.add(chatId);
      } else {
        _selectedChatIds.remove(chatId);
      }
    });
  }

  Future<void> _deleteSelectedSessions() async {
    if (_selectedChatIds.isEmpty) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    final count = _selectedChatIds.length;

    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('선택 항목 삭제'),
        content: Text('$count개의 채팅 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제하기'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await chatService.deleteChatSessions(_selectedChatIds.toList());
        _selectedChatIds.clear();
        _loadChatSessions();
        if (_isSelectionMode) {
          _toggleSelectionMode();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteAllSessions() async {
    final chatService = Provider.of<ChatService>(context, listen: false);

    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 삭제'),
        content: const Text('모든 채팅 기록을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('전체 삭제'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await chatService.deleteAllChatSessions();
        _selectedChatIds.clear();
        _isSelectionMode = false;
        _loadChatSessions();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
          );
        }
      }
    }
  }

  void _navigateToChat(ChatSession session) {
    final extra = NotionRouteExtra(
      chatId: session.chatId,
      pageTitle: session.pageTitle,
      databaseName: session.databaseName,
      isExistingChat: true,
    );
    context.push(AppRoutes.chat, extra: extra);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '채팅 기록',
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _deleteAllSessions,
              tooltip: '전체 삭제',
            ),
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.edit_note),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? '선택 취소' : '기록 선택',
          ),
        ],
      ),
      body: FutureBuilder<List<ChatSession>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('채팅 기록이 없습니다.'));
          }

          final sessions = snapshot.data!;
          sessions.sort(
            (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
          );

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isSelected = _selectedChatIds.contains(session.chatId);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                child: ListTile(
                  leading: _isSelectionMode
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            if (value != null) {
                              _onSessionSelected(session.chatId, value);
                            }
                          },
                        )
                      : const Icon(Icons.chat_bubble_outline),
                  title: Text(
                    session.pageTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '마지막 메시지: ${DateFormat('yy/MM/dd HH:mm').format(session.lastMessageTimestamp)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _isSelectionMode
                      ? null
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    if (_isSelectionMode) {
                      _onSessionSelected(session.chatId, !isSelected);
                    } else {
                      _navigateToChat(session);
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      _toggleSelectionMode();
                      _onSessionSelected(session.chatId, true);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isSelectionMode && _selectedChatIds.isNotEmpty
          ? FloatingActionButton(
              onPressed: _deleteSelectedSessions,
              tooltip: '선택 항목 삭제',
              child: const Icon(Icons.delete_outline),
            )
          : null,
    );
  }
}
