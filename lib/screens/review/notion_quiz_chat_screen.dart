import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/widgets/chat_input_field.dart';
import 'package:memora/widgets/chat_messages_list.dart';
import 'package:memora/widgets/common_app_bar.dart';
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
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  StreamSubscription<String>? _streamSubscription;

  // AI의 실시간 응답을 임시로 저장할 변수
  ChatMessage? _streamingAiMessage;

  int _questionCount = 0;
  final List<bool?> _quizResults = [null, null, null];

  // chatId는 Notion 페이지 제목을 기반으로 생성 (고유 식별자로 사용)
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    _chatId = widget.pageTitle;
    _openAIService = Provider.of<OpenAIService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _startQuizSessionIfNeeded();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startQuizSessionIfNeeded() {
    // 기존 채팅 기록이 있는지 확인 후, 없으면 퀴즈 시작
    _chatService.getMessages(_chatId).first.then((messages) {
      if (messages.isEmpty) {
        _startQuizSession();
      }
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
    _focusNode.requestFocus();

    final userMessage = ChatMessage(
      content: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );
    // 사용자 메시지를 먼저 Firestore에 저장
    await _chatService.sendMessage(_chatId, userMessage);

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
            _streamingAiMessage!.content = fullResponse;
          });
        },
        onDone: () async {
          if (!isInitialMessage && _questionCount < 3) {
            bool isCorrect = fullResponse.toLowerCase().startsWith('correct');
            if (mounted) {
              setState(() {
                _quizResults[_questionCount] = isCorrect;
                _questionCount++;
              });
            }
          }
          // 최종 AI 메시지를 Firestore에 저장
          final aiMessage = ChatMessage(
            content: fullResponse,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
          await _chatService.sendMessage(_chatId, aiMessage);

          if (mounted) {
            setState(() {
              _isLoading = false;
              _streamingAiMessage = null; // 스트리밍 완료 후 임시 메시지 제거
            });
            _focusNode.requestFocus();
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
          Row(
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Icon(
                  _quizResults[index] == true
                      ? Icons.circle
                      : _quizResults[index] == false
                      ? Icons.close
                      : Icons.circle_outlined,
                  color: _quizResults[index] == true
                      ? Colors.green
                      : _quizResults[index] == false
                      ? Colors.red
                      : Colors.grey,
                  size: 16,
                ),
              );
            }),
          ),
          const SizedBox(width: 10),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final messages = snapshot.data ?? [];
                final allMessages = [...messages];
                if (_streamingAiMessage != null) {
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
