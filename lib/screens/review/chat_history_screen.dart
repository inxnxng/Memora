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
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('삭제되었습니다')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')));
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
        content: const Text('모든 채팅 기록을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('전체 삭제'),
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
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('모든 기록이 삭제되었습니다')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')));
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: _isSelectionMode ? '기록 선택' : '이전 복습 대화',
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _deleteAllSessions,
              tooltip: '전체 삭제',
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: _toggleSelectionMode,
              tooltip: '선택 취소',
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              onPressed: _toggleSelectionMode,
              tooltip: '삭제할 기록 선택',
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text('불러오기에 실패했습니다', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: theme.colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '저장된 대화가 없습니다',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TIL 복습에서 대화를 시작하면\n여기에서 다시 볼 수 있습니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final sessions = snapshot.data!;
          sessions.sort(
            (a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp),
          );

          return RefreshIndicator(
            onRefresh: () async => _loadChatSessions(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final isSelected = _selectedChatIds.contains(session.chatId);
                final dateStr = DateFormat(
                  'M/d (E) HH:mm',
                  'ko',
                ).format(session.lastMessageTimestamp);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          )
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
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
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            if (_isSelectionMode)
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    if (value != null) {
                                      _onSessionSelected(session.chatId, value);
                                    }
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.pageTitle,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 14,
                                        color: theme.colorScheme.outline,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        dateStr,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.outline,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!_isSelectionMode)
                              Icon(
                                Icons.chevron_right_rounded,
                                color: theme.colorScheme.outline,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _isSelectionMode && _selectedChatIds.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: _deleteSelectedSessions,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text('선택한 ${_selectedChatIds.length}개 삭제'),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
