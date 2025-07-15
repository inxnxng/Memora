import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:memora/models/chat_message.dart';

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;

  const ChatMessagesList({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return GestureDetector(
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
