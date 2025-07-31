import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/widgets/chat_input_field.dart';
import 'package:memora/widgets/chat_messages_list.dart';
import 'package:provider/provider.dart';

class NotionQuizChatScreen extends StatefulWidget {
  final String pageTitle;
  final String pageContent;

  const NotionQuizChatScreen({
    super.key,
    required this.pageTitle,
    required this.pageContent,
  });

  @override
  State<NotionQuizChatScreen> createState() => _NotionQuizChatScreenState();
}

class _NotionQuizChatScreenState extends State<NotionQuizChatScreen> {
  late final OpenAIService _openAIService;
  late final ChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  int _questionCount = 0;
  final List<bool?> _quizResults = [null, null, null];
  StreamSubscription<String>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _openAIService = Provider.of<OpenAIService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _startQuizSession();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startQuizSession() {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final initialPrompt =
        "Based on the following content from my Notion page '${widget.pageTitle}', please quiz me to help me remember it. Ask me one question at a time. After I answer, please tell me if I am correct or incorrect by starting your response with 'Correct.' or 'Incorrect.'. Then, ask the next question. Ask a total of 3 questions.";

    _addMessage("", isUser: false); // Add a placeholder for the AI message

    final stream = _openAIService.generateTrainingContentStream(initialPrompt);
    String fullResponse = "";
    _streamSubscription = stream.listen(
      (contentChunk) {
        fullResponse += contentChunk;
        setState(() {
          _messages[0] = ChatMessage(
            content: fullResponse,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
        });
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _focusNode.requestFocus();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _messages[0] = ChatMessage(
              content: "Error starting quiz: ${error.toString()}",
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            );
            _isLoading = false;
          });
        }
      },
    );
  }

  void _addMessage(String text, {bool isUser = true}) {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          content: text,
          sender: isUser ? MessageSender.user : MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _sendMessage(String text) {
    if (text.isEmpty || _isLoading) return;

    _streamSubscription?.cancel();
    _addMessage(text, isUser: true);
    _textController.clear();
    _focusNode.requestFocus();

    setState(() {
      _isLoading = true;
    });

    _addMessage("", isUser: false);

    try {
      final stream = _openAIService.generateTrainingContentStream(text);
      String fullResponse = "";

      _streamSubscription = stream.listen(
        (contentChunk) {
          fullResponse += contentChunk;
          setState(() {
            _messages[0] = ChatMessage(
              content: fullResponse,
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            );
          });
        },
        onDone: () async {
          if (_questionCount < 3) {
            bool isCorrect = fullResponse.toLowerCase().startsWith('correct');
            if (mounted) {
              setState(() {
                _quizResults[_questionCount] = isCorrect;
                _questionCount++;
              });
            }
          }
          await _chatService.saveChatHistory(widget.pageTitle, _messages);
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _messages[0] = ChatMessage(
                content: "Error: ${error.toString()}",
                sender: MessageSender.ai,
                timestamp: DateTime.now(),
              );
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages[0] = ChatMessage(
            content: "Error: ${e.toString()}",
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          );
          _isLoading = false;
        });
      }
    }
  }

  void _completeStudy() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider
        .addStudyRecordForToday()
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('오늘의 학습이 기록되었습니다!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
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
      appBar: AppBar(
        title: Text('복습: ${widget.pageTitle}'),
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
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ChatMessagesList(messages: _messages),
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
