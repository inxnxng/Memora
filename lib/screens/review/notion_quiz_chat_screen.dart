import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/constants/prompt_constants.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/repositories/chat/chat_repository.dart';
import 'package:memora/router/app_routes.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/gemini_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/widgets/chat_input_field.dart';
import 'package:memora/widgets/chat_messages_list.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:provider/provider.dart';

class NotionQuizChatScreen extends StatefulWidget {
  final List<NotionPage> pages;
  final String databaseName;

  const NotionQuizChatScreen({
    super.key,
    required this.pages,
    required this.databaseName,
  });

  @override
  State<NotionQuizChatScreen> createState() => _NotionQuizChatScreenState();
}

class _NotionQuizChatScreenState extends State<NotionQuizChatScreen> {
  late final OpenAIService _openAIService;
  late final GeminiService _geminiService;
  late final ChatService _chatService;
  late final UserProvider _userProvider;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  StreamSubscription? _streamSubscription;
  StreamSubscription? _chatHistorySubscription;

  late final String _chatId;
  late final String _pageTitles;
  late final String _pageContents;

  @override
  void initState() {
    super.initState();
    _pageTitles = widget.pages.map((p) => p.title).join(', ');
    _pageContents = widget.pages.map((p) => p.content).join('\n\n---\n\n');
    _chatId = ChatRepository.generateChatId(
      widget.pages.map((p) => p.id).toList(),
    );
    _openAIService = Provider.of<OpenAIService>(context, listen: false);
    _geminiService = Provider.of<GeminiService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    _initializeChat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _chatHistorySubscription?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _userProvider.recordLearningSession();
    super.dispose();
  }

  void _initializeChat() {
    _chatHistorySubscription = _chatService.getMessages(_chatId).listen((
      messages,
    ) {
      if (messages.isEmpty) {
        _showWelcomeMessage();
      }
      _chatHistorySubscription?.cancel();
    });
  }

  void _showWelcomeMessage() async {
    final welcomeMessage = ChatMessage(
      content: PromptConstants.welcomeMessage(_pageTitles),
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    );
    await _chatService.sendMessage(
      _chatId,
      welcomeMessage,
      pageTitle: _pageTitles,
      pageContent: _pageContents,
      databaseName: widget.databaseName,
    );
  }

  Future<void> _checkApiKeysAndSendMessage(String text) async {
    final hasOpenAIKey = await _openAIService.checkApiKeyAvailability();
    final hasGeminiKey = await _geminiService.checkApiKeyAvailability();

    if (!hasOpenAIKey && !hasGeminiKey) {
      if (mounted) {
        _showApiKeyRequiredDialog();
      }
    } else {
      _sendMessage(text);
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
    if (text.isEmpty || _isLoading) return;

    _streamSubscription?.cancel();
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
      pageContent: _pageContents,
      databaseName: widget.databaseName,
    );

    _handleAiResponse();
  }

  void _handleAiResponse() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasOpenAIKey = await _openAIService.checkApiKeyAvailability();
      final hasGeminiKey = await _geminiService.checkApiKeyAvailability();

      Stream<String> stream;

      final history = await _chatService.getMessages(_chatId).first;
      final userMessages = history
          .where((m) => m.sender == MessageSender.user)
          .toList();

      final isFirstUserMessage = userMessages.length == 1;

      List<Map<String, String>> messagesForApi;

      if (isFirstUserMessage) {
        messagesForApi = [
          {'role': 'system', 'content': PromptConstants.reviewSystemPrompt},
          {
            'role': 'user',
            'content': PromptConstants.initialUserPrompt(_pageContents),
          },
        ];
      } else {
        final chatHistory = history
            .where(
              (m) => m.content != PromptConstants.welcomeMessage(_pageTitles),
            )
            .map(
              (msg) => {
                'role': msg.sender == MessageSender.user ? 'user' : 'assistant',
                'content': msg.content,
              },
            )
            .toList()
            .reversed
            .toList();

        messagesForApi = [
          {'role': 'system', 'content': PromptConstants.reviewSystemPrompt},
          ...chatHistory,
        ];
      }

      if (hasOpenAIKey) {
        stream = _openAIService.generateTrainingContentStream(messagesForApi);
      } else if (hasGeminiKey) {
        stream = _geminiService.generateQuizFromText(messagesForApi);
      } else {
        throw Exception("No API Key available.");
      }

      String fullResponse = "";

      _streamSubscription = stream.listen(
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

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        onError: (error) async {
          final errorMessage = ChatMessage(
            content: "Error: ${error.toString()}",
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
          await _chatService.sendMessage(_chatId, errorMessage);
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      final errorMessage = ChatMessage(
        content: "Error: ${e.toString()}",
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
      await _chatService.sendMessage(_chatId, errorMessage);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    (snapshot.data?.isEmpty ?? true)) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                return ChatMessagesList(messages: messages);
              },
            ),
          ),
          ChatInputField(
            controller: _textController,
            focusNode: _focusNode,
            onSubmitted: (text) => _checkApiKeysAndSendMessage(text),
            onSendPressed: () =>
                _checkApiKeysAndSendMessage(_textController.text),
            isEnabled: !_isLoading,
          ),
        ],
      ),
    );
  }
}
