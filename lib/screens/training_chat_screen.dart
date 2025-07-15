import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/providers/task_provider.dart';

import 'package:memora/services/chat_service.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/widgets/chat_input_field.dart';
import 'package:memora/widgets/chat_messages_list.dart';

class TrainingChatScreen extends StatefulWidget {
  final String taskTitle;
  final String taskDescription;
  final String taskId;
  final TaskProvider taskProvider; // New parameter

  const TrainingChatScreen({
    super.key,
    required this.taskTitle,
    required this.taskDescription,
    required this.taskId,
    required this.taskProvider, // Required
  });

  @override
  State<TrainingChatScreen> createState() => _TrainingChatScreenState();
}

class _TrainingChatScreenState extends State<TrainingChatScreen> {
  final OpenAIService _openAIService = OpenAIService();
  final LocalStorageService _localStorageService = LocalStorageService();
  late final ChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isCompleteButtonEnabled = false; // State for the button
  Timer? _timer; // Timer for enabling the button

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(_localStorageService);
    _loadChatHistoryAndStartSession();
    _startCompletionTimer(); // Start the timer
  }

  // New method to start the timer
  void _startCompletionTimer() {
    _timer = Timer(const Duration(minutes: 3), () {
      setState(() {
        _isCompleteButtonEnabled = true;
      });
    });
  }

  Future<void> _loadChatHistoryAndStartSession() async {
    final loadedHistory = await _chatService.loadChatHistory(widget.taskId);
    setState(() {
      _messages.addAll(loadedHistory);
    });

    if (_messages.isEmpty) {
      // Start with a greeting from the app, not the AI
      _addMessageToChat(
        '안녕하세요! ${widget.taskTitle} 주제로 훈련을 시작할거에요! 준비되셨나요?',
        isUser: false,
      );
    }
  }

  Future<void> _resetChat() async {
    setState(() {
      _messages.clear();
    });
    await _chatService.clearChatHistory(widget.taskId);
    await _loadChatHistoryAndStartSession(); // Restart with the welcome message
  }

  void _sendMessage(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    if (trimmedText == '/reset') {
      await _resetChat();
      return;
    }

    _addMessageToChat(trimmedText, isUser: true);
    _textController.clear();

    // If this is the first user message, construct the initial prompt for the AI
    if (_messages.length == 2 && _messages[0].sender == MessageSender.ai) {
      final lastResult = await _localStorageService.loadLastTrainingResult();
      String initialPrompt =
          "Let's start memory training for: ${widget.taskTitle}. ${widget.taskDescription}.";
      if (lastResult != null && lastResult.isNotEmpty) {
        initialPrompt +=
            " Based on your last training result: $lastResult, let's adjust the difficulty.";
      }
      initialPrompt +=
          " Please guide me through an exercise. My first response to you is: $trimmedText";

      // Now, send this combined prompt to the AI
      try {
        final aiResponse = await _openAIService.generateTrainingContent(
          initialPrompt,
        );
        _addMessageToChat(aiResponse, isUser: false);
      } catch (e) {
        _handleError(e);
      }
    } else {
      // For subsequent messages, just send the user's text
      try {
        final aiResponse = await _openAIService.generateTrainingContent(
          trimmedText,
        );
        _addMessageToChat(aiResponse, isUser: false);
      } catch (e) {
        _handleError(e);
      }
    }

    await _chatService.saveChatHistory(widget.taskId, _messages);
  }

  void _addMessageToChat(String text, {bool isUser = true}) {
    setState(() {
      _messages.add(ChatMessage(
        content: text,
        sender: isUser ? MessageSender.user : MessageSender.ai,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _handleError(Object e) {
    if (e.toString().contains('API key not found') ||
        e.toString().contains('invalid') ||
        e.toString().contains('unauthorized')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'OpenAI API Key is invalid or missing. Please update it.',
          ),
        ),
      );
      Navigator.pop(context); // Go back to the previous screen
    } else {
      _addMessageToChat("Error: ${e.toString()}", isUser: false);
    }
  }

  void _endTrainingSession() async {
    // For now, a simple dummy result. This should be replaced with actual logic
    // to determine difficulty/result based on the chat interaction.
    final result =
        "Completed training for ${widget.taskTitle} on ${DateTime.now().toIso8601String().split('T')[0]}";
    await _localStorageService.saveLastTrainingResult(result);
    await _localStorageService.saveLastTrainedDate(
      widget.taskId,
      DateTime.now(),
    ); // Save the training date
    // Mark task as complete using the passed taskProvider
    widget.taskProvider.toggleTaskCompletion(widget.taskId);
    Navigator.pop(context); // Go back to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('훈련: ${widget.taskTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            onPressed: _isCompleteButtonEnabled
                ? _endTrainingSession
                : null, // Enable/disable based on timer
            tooltip: '훈련 완료',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessagesList(messages: _messages),
          ),
          ChatInputField(
            controller: _textController,
            onSubmitted: _sendMessage,
            onSendPressed: () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    super.dispose();
  }
}
