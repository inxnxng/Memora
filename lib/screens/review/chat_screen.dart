import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/prompt_constants.dart';
import 'package:memora/models/ai_provider.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/models/notion_page.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/repositories/chat/chat_repository.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/gemini_service.dart';
import 'package:memora/services/notion_service.dart'; // Added
import 'package:memora/services/openai_service.dart';
import 'package:memora/widgets/chat_input_field.dart';
import 'package:memora/widgets/chat_messages_list.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final List<NotionPage>? pages; // Made optional
  final String? databaseName;
  final String? chatId; // New
  final String? pageTitle; // New
  final bool isExistingChat; // New

  const ChatScreen({
    super.key,
    this.pages,
    this.databaseName,
    this.chatId,
    this.pageTitle,
    this.isExistingChat = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final OpenAIService _openAIService;
  late final GeminiService _geminiService;
  late final ChatService _chatService;
  late final NotionService _notionService; // Added
  late final UserProvider _userProvider;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Stream<List<ChatMessage>>? _chatMessagesStream;
  late Future<void> _initFuture;

  late String _chatId;
  late String _pageTitles;
  late String _pageContents;
  bool _apiKeyChecked = false;
  bool _apiKeyValid = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _openAIService = Provider.of<OpenAIService>(context, listen: false);
    _geminiService = Provider.of<GeminiService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _notionService = Provider.of<NotionService>(context, listen: false);
    _userProvider = Provider.of<UserProvider>(context, listen: false);

    _initFuture = _initAsyncData();
  }

  Future<void> _initAsyncData() async {
    try {
      if (widget.isExistingChat) {
        _chatId = widget.chatId!;
        _pageTitles = widget.pageTitle!;
        final pageIds = ChatRepository.parsePageIdsFromChatId(widget.chatId!);
        final contents = await Future.wait(
          pageIds.map((id) => _notionService.renderNotionDbAsMarkdown(id)),
        );
        _pageContents = contents.join('\n\n---\n\n');
      } else {
        _pageTitles = widget.pages?.map((p) => p.title).join(', ') ?? '';
        _pageContents =
            widget.pages?.map((p) => p.content).join('\n\n---\n\n') ?? '';
        _chatId = (widget.pages != null && widget.pages!.isNotEmpty)
            ? ChatRepository.generateChatId(
                widget.pages!.map((p) => p.id).toList(),
              )
            : DateTime.now().millisecondsSinceEpoch.toString();
      }
      _chatMessagesStream = _chatService.getMessages(_chatId);

      // 선호 AI 모델에 맞는 API 키만 검사
      final preferred = _userProvider.preferredAi;
      debugPrint(
        '[ChatScreen] _initAsyncData: 선호 AI preferred=${preferred.name}',
      );
      final preferredKeyValid = preferred == AiProvider.openai
          ? await _openAIService.checkApiKeyAvailability()
          : await _geminiService.checkApiKeyAvailability();
      debugPrint(
        '[ChatScreen] _initAsyncData: API 키 검사 결과 preferredKeyValid=$preferredKeyValid',
      );

      if (mounted) {
        setState(() {
          _apiKeyChecked = true;
          _apiKeyValid = preferredKeyValid;
        });
        if (!_apiKeyValid) {
          debugPrint('[ChatScreen] _initAsyncData: 키 유효하지 않음 → 팝업 표시');
          final goSettings = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('API 키 필요'),
              content: Text(
                '선호하신 ${preferred.name} API 키가 없거나 유효하지 않습니다.\n설정에서 유효한 키를 등록해 주세요.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('나중에'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('설정으로 이동'),
                ),
              ],
            ),
          );
          if (goSettings == true && mounted) {
            context.push(AppRoutes.settings).then((_) async {
              if (!mounted) return;
              final recheck = _userProvider.preferredAi == AiProvider.openai
                  ? await _openAIService.checkApiKeyAvailability()
                  : await _geminiService.checkApiKeyAvailability();
              if (mounted) {
                setState(() => _apiKeyValid = recheck);
              }
            });
          }
        }
      }
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _apiKeyChecked = true;
          _initError = e.toString().replaceFirst('Exception: ', '');
        });
        debugPrint('ChatScreen init error: $e\n$st');
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _userProvider.recordLearningSession();
    super.dispose();
  }

  Future<void> _checkApiKeysAndSendMessage(String text) async {
    final preferred = _userProvider.preferredAi;
    debugPrint(
      '[ChatScreen] _checkApiKeysAndSendMessage: preferred=${preferred.name}',
    );
    final preferredKeyValid = preferred == AiProvider.openai
        ? await _openAIService.checkApiKeyAvailability()
        : await _geminiService.checkApiKeyAvailability();
    debugPrint(
      '[ChatScreen] _checkApiKeysAndSendMessage: preferredKeyValid=$preferredKeyValid',
    );

    if (!preferredKeyValid) {
      debugPrint('[ChatScreen] _checkApiKeysAndSendMessage: 키 없음/무효 → 설정으로 유도');
      if (mounted) {
        context.push(AppRoutes.settings);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '선호하신 ${preferred.name} API 키가 없거나 사용할 수 없습니다. 설정에서 등록해 주세요.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    await _sendMessage(text);
    if (mounted) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    _textController.clear();

    // 첫 사용자 메시지인 경우: 환영 메시지를 먼저 저장한 뒤 사용자 메시지 저장 (채팅 기록·세션은 이때부터 생성)
    final history = await _chatService.getMessages(_chatId).first;
    final hasUserMessage = history.any((m) => m.sender == MessageSender.user);
    if (!hasUserMessage && !widget.isExistingChat) {
      final welcomeMessage = ChatMessage(
        content: PromptConstants.welcomeMessage(_pageTitles),
        sender: MessageSender.system,
        timestamp: DateTime.now(),
      );
      await _chatService.sendMessage(_chatId, welcomeMessage);
    }

    final userMessage = ChatMessage(
      content: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    await _chatService.sendMessage(
      _chatId,
      userMessage,
      pageTitle: _pageTitles,
      databaseName: widget.databaseName,
    );

    _handleAiResponse();
  }

  static bool _isApiKeyError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('api key not valid') ||
        lower.contains('valid api key') ||
        lower.contains('invalid api key') ||
        lower.contains('api key is invalid') ||
        (lower.contains('authentication') && lower.contains('key'));
  }

  Future<void> _handleApiKeyErrorAndNavigateToSettings() async {
    final preferred = _userProvider.preferredAi;
    if (preferred == AiProvider.openai) {
      await _openAIService.markKeyInvalid();
    } else {
      await _geminiService.markKeyInvalid();
    }
    if (!mounted) return;
    setState(() => _apiKeyValid = false);

    final goSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('API 키 오류'),
        content: const Text('등록된 API 키가 유효하지 않습니다.\n설정에서 유효한 키를 다시 등록해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('나중에'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
    if (goSettings == true && mounted) {
      context.push(AppRoutes.settings);
    }
  }

  void _handleAiResponse() async {
    try {
      final preferred = _userProvider.preferredAi;
      final hasOpenAIKey = await _openAIService.checkApiKeyAvailability();
      final hasGeminiKey = await _geminiService.checkApiKeyAvailability();
      debugPrint(
        '[ChatScreen] _handleAiResponse: preferred=${preferred.name} '
        'hasOpenAI=$hasOpenAIKey hasGemini=$hasGeminiKey',
      );

      final history = await _chatService.getMessages(_chatId).first;
      final messagesForApi = _chatService.buildPromptForAI(
        history,
        _pageContents,
        _pageTitles,
      );

      final bool useStreaming = !widget.isExistingChat;

      if (useStreaming) {
        // 신규 채팅: 스트리밍으로 응답 표시
        final Stream<String> stream;
        if (preferred == AiProvider.openai && hasOpenAIKey) {
          stream = _openAIService.generateTrainingContentStream(messagesForApi);
        } else if (preferred == AiProvider.gemini && hasGeminiKey) {
          stream = _geminiService.generateQuizFromText(messagesForApi);
        } else {
          throw Exception(
            '선호하신 ${preferred.name} API 키가 없거나 사용할 수 없습니다. 설정에서 확인해 주세요.',
          );
        }
        String fullResponse = "";
        stream.listen(
          (contentChunk) {
            fullResponse += contentChunk;
          },
          onDone: () async {
            final finalResponse = fullResponse.trim();
            if (finalResponse.isNotEmpty) {
              final aiMessage = ChatMessage(
                content: finalResponse,
                sender: MessageSender.ai,
                timestamp: DateTime.now(),
              );
              await _chatService.sendMessage(_chatId, aiMessage);
            }
          },
          onError: (error) async {
            final msg = error.toString();
            debugPrint('[ChatScreen] _handleAiResponse stream onError: $msg');
            if (_isApiKeyError(msg)) {
              await _handleApiKeyErrorAndNavigateToSettings();
              return;
            }
            if (mounted) {
              _showErrorPopup('응답 생성 중 오류가 발생했습니다.', msg);
            }
          },
        );
      } else {
        // 기존 채팅: 스트리밍 없이 한 번에 응답 수신
        String fullResponse;
        if (preferred == AiProvider.openai && hasOpenAIKey) {
          fullResponse = await _openAIService.generateTrainingContent(
            messagesForApi,
          );
        } else if (preferred == AiProvider.gemini && hasGeminiKey) {
          final stream = _geminiService.generateQuizFromText(messagesForApi);
          fullResponse = await stream.fold<String>('', (a, b) => a + b);
        } else {
          throw Exception(
            '선호하신 ${preferred.name} API 키가 없거나 사용할 수 없습니다. 설정에서 확인해 주세요.',
          );
        }
        final finalResponse = fullResponse.trim();
        if (finalResponse.isNotEmpty && mounted) {
          final aiMessage = ChatMessage(
            content: finalResponse,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
          await _chatService.sendMessage(_chatId, aiMessage);
        }
      }
    } catch (e, st) {
      final msg = e.toString();
      debugPrint('[ChatScreen] _handleAiResponse catch: $msg\n$st');
      if (_isApiKeyError(msg)) {
        await _handleApiKeyErrorAndNavigateToSettings();
        return;
      }
      if (mounted) {
        _showErrorPopup('오류가 발생했습니다.', msg);
      }
    }
  }

  void _showErrorPopup(String title, String detail) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(detail)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _completeStudy() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider
        .addStudyRecordForToday(
          databaseName: widget.databaseName,
          title: _pageTitles,
        )
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('오늘의 학습이 기록되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('학습 기록에 실패했습니다: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '복습 채팅하기',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _pageTitles.length > 28
                  ? '${_pageTitles.substring(0, 25)}...'
                  : _pageTitles,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _completeStudy,
            tooltip: '학습 완료',
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_initError != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _initError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('돌아가기'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text('오류가 발생했습니다.', textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('돌아가기'),
                    ),
                  ],
                ),
              ),
            );
          }
          {
            return Column(
              children: [
                if (_apiKeyChecked && !_apiKeyValid)
                  Material(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.key_off,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer
                                  .withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '선호하신 ${_userProvider.preferredAi.name} API 키를 등록해 주세요.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(AppRoutes.settings),
                              child: const Text('설정으로 이동'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _focusNode.unfocus(),
                    behavior: HitTestBehavior.translucent,
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: _chatMessagesStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            (snapshot.data?.isEmpty ?? true)) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 40,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('메시지를 불러오지 못했습니다.'),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${snapshot.error}',
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final storedMessages = snapshot.data ?? [];
                        // 새 채팅이고 저장된 메시지가 없을 때만 UI에 환영 메시지 표시 (저장하지 않음)
                        final messages =
                            (!widget.isExistingChat && storedMessages.isEmpty)
                            ? [
                                ChatMessage(
                                  content: PromptConstants.welcomeMessage(
                                    _pageTitles,
                                  ),
                                  sender: MessageSender.system,
                                  timestamp: DateTime.now(),
                                ),
                              ]
                            : storedMessages;

                        return Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _focusNode.unfocus(),
                                behavior: HitTestBehavior.translucent,
                                child: ChatMessagesList(messages: messages),
                              ),
                            ),
                            ChatInputField(
                              controller: _textController,
                              focusNode: _focusNode,
                              onSendPressed: _apiKeyValid
                                  ? () => _checkApiKeysAndSendMessage(
                                      _textController.text,
                                    )
                                  : () {
                                      context.push(AppRoutes.settings);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '선호하신 ${_userProvider.preferredAi.name} API 키를 설정에서 등록해 주세요.',
                                          ),
                                        ),
                                      );
                                    },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
