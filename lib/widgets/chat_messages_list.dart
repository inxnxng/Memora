import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:memora/models/chat_message.dart';

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;

  const ChatMessagesList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: WavingDots());
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return GestureDetector(
          key: ValueKey(message.id),
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
          child: Align(
            alignment: message.sender == MessageSender.user
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: message.sender == MessageSender.user
                    ? Colors.blue[100]
                    : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12.0),
                  topRight: const Radius.circular(12.0),
                  bottomLeft: Radius.circular(
                    message.sender == MessageSender.user ? 12.0 : 0,
                  ),
                  bottomRight: Radius.circular(
                    message.sender == MessageSender.user ? 0 : 12.0,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    DateFormat('HH:mm:ss').format(message.timestamp),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class WavingDots extends StatefulWidget {
  const WavingDots({super.key});

  @override
  State<WavingDots> createState() => _WavingDotsState();
}

class _WavingDotsState extends State<WavingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation1 = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeInOut),
      ),
    );
    _animation2 = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.3, curve: Curves.easeInOut),
      ),
    );
    _animation3 = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.4, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, _animation1.value),
              child: const Text('.', style: TextStyle(fontSize: 80)),
            ),
            Transform.translate(
              offset: Offset(0, _animation2.value),
              child: const Text('.', style: TextStyle(fontSize: 80)),
            ),
            Transform.translate(
              offset: Offset(0, _animation3.value),
              child: const Text('.', style: TextStyle(fontSize: 80)),
            ),
          ],
        );
      },
    );
  }
}
