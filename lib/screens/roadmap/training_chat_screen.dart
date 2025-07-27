import 'dart:async'; // Import for Timer

import 'package:flutter/material.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/services/chat_service.dart';
import 'package:memora/services/openai_service.dart';
import 'package:memora/services/task_service.dart';
import 'package:memora/widgets/chat_input_field.dart';
import 'package:memora/widgets/chat_messages_list.dart';
import 'package:provider/provider.dart';

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
  late final OpenAIService _openAIService;
  late final TaskService _taskService;
  late final ChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isCompleteButtonEnabled = false; // State for the button
  Timer? _timer; // Timer for enabling the button

  @override
  void initState() {
    super.initState();
    _openAIService = Provider.of<OpenAIService>(context, listen: false);
    _taskService = Provider.of<TaskService>(context, listen: false);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _loadChatHistoryAndStartSession();
    _startCompletionTimer(); // Start the timer
  }

  // New method to start the timer
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
    final loadedHistory = await _chatService.loadChatHistory(widget.taskId);
    if (mounted) {
      setState(() {
        _messages.addAll(loadedHistory);
      });
    }

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
    if (_messages.length == 2 && _messages.first.sender == MessageSender.ai) {
      final lastTrained = await _taskService.loadLastTrainedDate(widget.taskId);
      String initialPrompt =
          "Let's start memory training for: ${widget.taskTitle}. ${widget.taskDescription}.";
      if (lastTrained != null) {
        initialPrompt +=
            " Based on your last training on $lastTrained, let's adjust the difficulty.";
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
    if (e.toString().contains('API key not found') ||
        e.toString().contains('invalid') ||
        e.toString().contains('unauthorized')) {
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
    await _taskService.saveLastTrainedDate(
      widget.taskId,
      DateTime.now(),
    ); // Save the training date
    // Mark task as complete using the passed taskProvider
    widget.taskProvider.toggleTaskCompletion(widget.taskId);
    if (mounted) {
      Navigator.pop(context); // Go back to the previous screen
    }
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
          Expanded(child: ChatMessagesList(messages: _messages)),
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
