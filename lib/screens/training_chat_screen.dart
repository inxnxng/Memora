import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memora/providers/task_provider.dart';
import 'package:memora/screens/openai_api_key_input_screen.dart';
import 'package:memora/services/local_storage_service.dart';
import 'package:memora/services/openai_service.dart';

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
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isCompleteButtonEnabled = false; // State for the button
  Timer? _timer; // Timer for enabling the button

  @override
  void initState() {
    super.initState();
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
    final loadedHistory = await _localStorageService.loadChatHistory(
      widget.taskId,
    );
    setState(() {
      _messages.addAll(loadedHistory);
    });

    if (_messages.isEmpty) {
      final lastResult = await _localStorageService.loadLastTrainingResult();
      String initialPrompt =
          "Let's start memory training for: ${widget.taskTitle}. ${widget.taskDescription}.";
      if (lastResult != null && lastResult.isNotEmpty) {
        initialPrompt +=
            " Based on your last training result: $lastResult, let's adjust the difficulty.";
      }
      initialPrompt += " Please guide me through an exercise.";
      // AI initiates the session, not a simulated user message
      _sendMessage(initialPrompt, isUser: false);
    }
  }

  void _sendMessage(String text, {bool isUser = true}) async {
    setState(() {
      _messages.add({'role': isUser ? 'user' : 'ai', 'content': text});
    });
    await _localStorageService.saveChatHistory(widget.taskId, _messages);

    if (isUser) {
      _textController.clear();
      try {
        final aiResponse = await _openAIService.generateTrainingContent(text);
        _sendMessage(aiResponse, isUser: false);
      } catch (e) {
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
          if (!mounted) return; // Add this line
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const OpenAIApiKeyInputScreen(),
            ),
          );
        } else {
          _sendMessage("Error: ${e.toString()}", isUser: false);
        }
      }
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
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return Align(
                  alignment: message['role'] == 'user'
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: message['role'] == 'user'
                          ? Colors.blue[100]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12.0),
                        topRight: const Radius.circular(12.0),
                        bottomLeft: Radius.circular(
                          message['role'] == 'user' ? 12.0 : 0,
                        ),
                        bottomRight: Radius.circular(
                          message['role'] == 'user' ? 0 : 12.0,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['content']!,
                          style: const TextStyle(color: Colors.black),
                        ),
                        if (message.containsKey('timestamp') &&
                            message['timestamp'] != null &&
                            message['timestamp']!.isNotEmpty) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            DateFormat(
                              'HH:mm:ss',
                            ).format(DateTime.parse(message['timestamp']!)),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    onSubmitted: (text) => _sendMessage(text),
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: () => _sendMessage(_textController.text),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
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
