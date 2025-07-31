import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/models/task_model.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/widgets/chat_input_field.dart';
import 'package:memora/widgets/chat_messages_list.dart';
import 'package:provider/provider.dart';

class CombinedTrainingChatScreen extends StatefulWidget {
  final List<NotionPage> pages;

  const CombinedTrainingChatScreen({super.key, required this.pages});

  @override
  State<CombinedTrainingChatScreen> createState() =>
      _CombinedTrainingChatScreenState();
}

class _CombinedTrainingChatScreenState
    extends State<CombinedTrainingChatScreen> {
  late final OpenAIService _openAIService;
  late final ChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isCompleteButtonEnabled = false;
  Timer? _timer;
  late final String _chatId;

  @override
  void initState() {
    super.initState();
    _openAIService = Provider.of<OpenAIService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _chatId = widget.pages.map((p) => p.id).join('_');
    _loadChatHistoryAndStartSession();
    _startCompletionTimer();
  }

  @override
  void dispose() {
    _textController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCompletionTimer() {
    _timer = Timer(const Duration(minutes: 3), () {
      if (mounted) {
        setState(() {
          _isCompleteButtonEnabled = true;
        });
      }
    });
  }

  Future<void> _loadChatHistoryAndStartSession() async {
    final loadedHistory = await _chatService.loadChatHistory(_chatId);
    if (mounted) {
      setState(() {
        _messages.addAll(loadedHistory);
      });
    }

    if (_messages.isEmpty) {
      final pageTitles = widget.pages.map((p) => p.title).join(', ');
      _addMessageToChat(
        '안녕하세요! 다음 Notion 페이지 내용으로 훈련을 시작할게요: $pageTitles. 준비되셨나요?',
        isUser: false,
      );
    }
  }

  void _sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isLoading) return;

    _addMessageToChat(trimmedText, isUser: true);
    _textController.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      String prompt;
      if (_messages.length <= 2) {
        final pageContents = widget.pages
            .map((p) => 'Page "${p.title}":\n${p.content}')
            .join('\n\n---\n\n');
        prompt =
            "Let's start memory training based on the content of these Notion pages:\n\n$pageContents\n\nPlease guide me through an exercise. My first response to you is: $trimmedText";
      } else {
        prompt = trimmedText;
      }

      final aiResponse = await _openAIService.generateTrainingContent(prompt);
      _addMessageToChat(aiResponse, isUser: false);
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        await _chatService.saveChatHistory(_chatId, _messages);
      }
    }
  }

  void _addMessageToChat(String text, {bool isUser = true}) {
    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            content: text,
            sender: isUser ? MessageSender.user : MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  void _handleError(Object e) {
    if (!mounted) return;
    String errorMessage = "An unexpected error occurred.";
    if (e.toString().contains('API key not found') ||
        e.toString().contains('invalid') ||
        e.toString().contains('unauthorized')) {
      errorMessage =
          'OpenAI API Key is invalid or missing. Please update it in the settings.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      Navigator.pop(context);
    } else {
      errorMessage = "Error: ${e.toString()}";
      _addMessageToChat(errorMessage, isUser: false);
    }
  }

  void _endTrainingSession() {
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
    final pageTitles = widget.pages.map((p) => p.title).join(', ');
    return Scaffold(
      appBar: AppBar(
        title: Text('훈련: $pageTitles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _isCompleteButtonEnabled ? _endTrainingSession : null,
            tooltip: '훈련 완료',
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
            onSubmitted: _sendMessage,
            onSendPressed: () => _sendMessage(_textController.text),
            isEnabled: !_isLoading,
          ),
        ],
      ),
    );
  }
}
