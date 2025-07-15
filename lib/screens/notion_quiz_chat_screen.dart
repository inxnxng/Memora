import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/widgets/chat_input_field.dart';
import 'package:memora/widgets/chat_messages_list.dart';

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
  final OpenAIService _openAIService = OpenAIService();
  final LocalStorageService _localStorageService = LocalStorageService();
  late final ChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;

  int _questionCount = 0;
  final List<bool?> _quizResults = [null, null, null];
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(_localStorageService);
    _startQuizSession();
  }

  Future<void> _startQuizSession() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final initialPrompt =
          "Based on the following content from my Notion page '${widget.pageTitle}', please quiz me to help me remember it. Ask me one question at a time. After I answer, please tell me if I am correct or incorrect by starting your response with 'Correct.' or 'Incorrect.'. Then, ask the next question. Ask a total of 3 questions.";
      final aiResponse = await _openAIService.generateTrainingContent(
        initialPrompt,
      );
      _addMessage(aiResponse, isUser: false);
    } catch (e) {
      _addMessage("Error starting quiz: ${e.toString()}", isUser: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addMessage(String text, {bool isUser = true}) {
    setState(() {
      _messages.insert(
          0,
          ChatMessage(
            content: text,
            sender: isUser ? MessageSender.user : MessageSender.ai,
            timestamp: DateTime.now(),
          ));
    });
  }

  void _sendMessage(String text) async {
    if (text.isEmpty) return;

    if (text == '/reset') {
      _textController.clear();
      return;
    }

    if (_quizFinished) return;

    _addMessage(text, isUser: true);
    _textController.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      final aiResponse = await _openAIService.generateTrainingContent(text);

      if (_questionCount < 3) {
        bool isCorrect = aiResponse.toLowerCase().startsWith('correct');
        setState(() {
          _quizResults[_questionCount] = isCorrect;
          _questionCount++;
        });
      }

      _addMessage(aiResponse, isUser: false);

      if (_questionCount >= 3) {
        setState(() {
          _quizFinished = true;
        });
      }
      // Save chat history after each message exchange
      await _chatService.saveChatHistory(widget.pageTitle, _messages);
    } catch (e) {
      _addMessage("Error: ${e.toString()}", isUser: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                      : Icons.circle_outlined,
                  color: _quizResults[index] == true
                      ? Colors.green
                      : Colors.grey,
                  size: 16,
                ),
              );
            }),
          ),
          const SizedBox(width: 10),
          if (_quizFinished)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '나가기',
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
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          ChatInputField(
            controller: _textController,
            onSubmitted: (_isLoading || _quizFinished)
                ? (_) {}
                : (text) => _sendMessage(text),
            onSendPressed: (_isLoading || _quizFinished)
                ? () {}
                : () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }
}
