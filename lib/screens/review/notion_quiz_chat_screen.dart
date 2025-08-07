import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/repositories/chat/chat_repository.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/widgets/chat_input_field.dart';
import 'package:memora/widgets/chat_messages_list.dart';
import 'package:memora/widgets/common_app_bar.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:provider/provider.dart';

class NotionQuizChatScreen extends StatefulWidget {
  final String pageTitle;
  final String pageContent;
  final String databaseName;

  const NotionQuizChatScreen({
    super.key,
    required this.pageTitle,
    required this.pageContent,
    required this.databaseName,
  });

  @override
  State<NotionQuizChatScreen> createState() => _NotionQuizChatScreenState();
}

class _NotionQuizChatScreenState extends State<NotionQuizChatScreen> {
  late final OpenAIService _openAIService;
  late final ChatService _chatService;
  late final UserProvider _userProvider;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  StreamSubscription? _streamSubscription;
  StreamSubscription? _chatHistorySubscription;

  // AI의 실시간 응답을 임시로 저장할 변수
  ChatMessage? _streamingAiMessage;

  late final String _chatId;

  @override
  void initState() {
    super.initState();
    // Use the robust chatId generation
    _chatId = ChatRepository.generateChatId([widget.pageTitle]);
    _openAIService = Provider.of<OpenAIService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _userProvider = Provider.of<UserProvider>(context, listen: false);
    _startQuizSessionIfNeeded();
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

  void _startQuizSessionIfNeeded() {
    // Listen to the stream to check for history.
    // This is more robust than using .first.
    _chatHistorySubscription =
        _chatService.getMessages(_chatId).listen((messages) {
      // If messages are empty and we are not already loading a quiz, start one.
      if (messages.isEmpty && !_isLoading) {
        _startQuizSession();
      }
      // Once we get the first batch of messages, we don't need this subscription anymore.
      _chatHistorySubscription?.cancel();
    });
  }

  void _startQuizSession() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final initialPrompt =
        "Based on the following content from my Notion page '${widget.pageTitle}', please quiz me to help me remember it. Ask me one question at a time. After I answer, please tell me if I am correct or incorrect by starting your response with 'Correct.' or 'Incorrect.'. Then, ask the next question. Ask a total of 3 questions.";

    _handleAiResponse(initialPrompt, isInitialMessage: true);
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
    // User message is sent to Firebase, the stream will update the UI and local cache
    await _chatService.sendMessage(
      _chatId,
      userMessage,
      pageTitle: widget.pageTitle,
      pageContent: widget.pageContent,
      databaseName: widget.databaseName,
    );

    _handleAiResponse(text);
  }

  void _handleAiResponse(String prompt, {bool isInitialMessage = false}) {
    setState(() {
      _isLoading = true;
      // AI 응답 스트리밍 시작을 표시하기 위한 임시 메시지
      _streamingAiMessage = ChatMessage(
        content: "...",
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
      );
    });

    try {
      final stream = _openAIService.generateTrainingContentStream(prompt);
      String fullResponse = "";

      _streamSubscription = stream.listen(
        (contentChunk) {
          fullResponse += contentChunk;
          setState(() {
            // 스트리밍 중인 메시지 내용 업데이트
            if (_streamingAiMessage != null) {
              _streamingAiMessage!.content = fullResponse;
            }
          });
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
              _streamingAiMessage = null; // 스트리밍 완료 후 임시 메시지 제거
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _focusNode.requestFocus();
              }
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
              _streamingAiMessage = null;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _focusNode.requestFocus();
              }
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
      _chatService.sendMessage(_chatId, errorMessage);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _streamingAiMessage = null;
        });
      }
    }
  }

  void _completeStudy() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider
        .addStudyRecordForToday(
          databaseName: widget.databaseName,
          title: widget.pageTitle,
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
        title: '복습: ${widget.pageTitle}',
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
                    !snapshot.hasData) {
                  // Now, this should only show briefly as local data loads fast.
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                final allMessages = messages.reversed.toList();
                if (_streamingAiMessage != null) {
                  // Insert streaming message at the beginning (top of the reversed list)
                  allMessages.insert(0, _streamingAiMessage!);
                }

                return ChatMessagesList(messages: allMessages);
              },
            ),
          ),
          ChatInputField(
            controller: _textController,
            focusNode: _focusNode,
            onSubmitted: (text) => _sendMessage(text),
            onSendPressed: () => _sendMessage(_textController.text),
            isEnabled: !_isLoading,
          ),
        ],
      ),
    );
  }
}