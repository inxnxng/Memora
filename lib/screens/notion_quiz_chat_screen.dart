import 'dart:async';
import 'package:flutter/material.dart';
import 'package:memora/services/openai_service.dart';

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
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = true;

  int _questionCount = 0;
  final List<bool?> _quizResults = [null, null, null];
  bool _quizFinished = false;

  @override
  void initState() {
    super.initState();
    _startQuizSession();
  }

  Future<void> _startQuizSession() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final initialPrompt =
          "Based on the following content from my Notion page '${widget.pageTitle}', please quiz me to help me remember it. Ask me one question at a time. After I answer, please tell me if I am correct or incorrect by starting your response with 'Correct.' or 'Incorrect.'. Then, ask the next question. Ask a total of 3 questions.";
      final aiResponse =
          await _openAIService.generateTrainingContent(initialPrompt);
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
      _messages.insert(0, {'role': isUser ? 'user' : 'ai', 'content': text});
    });
  }

  void _sendMessage(String text) async {
    if (text.isEmpty || _quizFinished) return;

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
                  color: _quizResults[index] == true ? Colors.green : Colors.grey,
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
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message['role'] == 'user';
                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color:
                                isUser ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            message['content']!,
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: _quizFinished ? '퀴즈가 종료되었습니다.' : '답변을 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onSubmitted: (_isLoading || _quizFinished)
                  ? null
                  : (text) => _sendMessage(text),
              enabled: !_quizFinished,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: (_isLoading || _quizFinished)
                ? null
                : () => _sendMessage(_textController.text),
          ),
        ],
      ),
    );
  }
}
