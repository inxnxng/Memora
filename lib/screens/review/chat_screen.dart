import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/prompt_constants.dart';
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
import 'package:memora/widgets/common_app_bar.dart';
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

  late final Stream<List<ChatMessage>> _chatMessagesStream;
  late Future<void> _initFuture; // Changed to late, not late final

  late String _chatId;
  late String _pageTitles;
  late String _pageContents;

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
    if (widget.isExistingChat) {
      _chatId = widget.chatId!;
      _pageTitles = widget.pageTitle!;
      final pageIds = widget.chatId!.split('-');
      final contents = <String>[];
      for (final id in pageIds) {
        final fetchedPage = await _notionService.fetchPageById(id);
        if (fetchedPage != null) {
          contents.add(fetchedPage.content);
        }
      }
      _pageContents = contents.join('\n\n---\n\n');
    } else {
      _pageTitles = widget.pages!.map((p) => p.title).join(', ');
      _pageContents = widget.pages!.map((p) => p.content).join('\n\n---\n\n');
      _chatId = ChatRepository.generateChatId(
        widget.pages!.map((p) => p.id).toList(),
      );
    }

    _chatMessagesStream = _chatService.getMessages(_chatId);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _userProvider.recordLearningSession();
    super.dispose();
  }

  Future<void> _checkApiKeysAndSendMessage(String text) async {
    final hasOpenAIKey = await _openAIService.checkApiKeyAvailability();
    final hasGeminiKey = await _geminiService.checkApiKeyAvailability();

    if (!hasOpenAIKey && !hasGeminiKey) {
      if (mounted) {
        _showApiKeyRequiredDialog();
      }
    } else {
      await _sendMessage(text);
      if (mounted) {
        _focusNode.requestFocus();
      }
    }
  }

  void _showApiKeyRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 키 필요'),
        content: const Text(
          'OpenAI 또는 Gemini API 키가 필요합니다. 설정으로 이동하여 키를 추가해주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.settings);
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    _textController.clear();

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

  void _handleAiResponse() async {
    try {
      final hasOpenAIKey = await _openAIService.checkApiKeyAvailability();
      final hasGeminiKey = await _geminiService.checkApiKeyAvailability();

      Stream<String> stream;

      List<Map<String, String>> messagesForApi = _chatService.buildPromptForAI(
        await _chatService.getMessages(_chatId).first,
        _pageContents,
        _pageTitles,
      );

      if (hasOpenAIKey) {
        stream = _openAIService.generateTrainingContentStream(messagesForApi);
      } else if (hasGeminiKey) {
        stream = _geminiService.generateQuizFromText(messagesForApi);
      } else {
        throw Exception("No API Key available.");
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
          final errorMessage = ChatMessage(
            content: "Error: ${error.toString()}",
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
          await _chatService.sendMessage(_chatId, errorMessage);
        },
      );
    } catch (e) {
      final errorMessage = ChatMessage(
        content: "Error: ${e.toString()}",
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      await _chatService.sendMessage(_chatId, errorMessage);
    }
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
    return Scaffold(
      appBar: CommonAppBar(
        title: '복습: $_pageTitles',
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _completeStudy,
            tooltip: '학습 완료',
          ),
        ],
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Column(
              children: [
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
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        final messages = snapshot.data ?? [];
                        List<ChatMessage> displayMessages = messages;
                        if (displayMessages.isEmpty) {
                          displayMessages = [
                            ChatMessage(
                              content: PromptConstants.welcomeMessage(
                                _pageTitles,
                              ),
                              sender: MessageSender.system,
                              timestamp: DateTime.now(),
                            ),
                          ];
                        }
                        return Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _focusNode.unfocus(),
                                behavior: HitTestBehavior.translucent,
                                child: ChatMessagesList(
                                  messages: displayMessages,
                                ),
                              ),
                            ),
                            ChatInputField(
                              controller: _textController,
                              focusNode: _focusNode,
                              onSubmitted: (text) =>
                                  _checkApiKeysAndSendMessage(text),
                              onSendPressed: () => _checkApiKeysAndSendMessage(
                                _textController.text,
                              ),
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
