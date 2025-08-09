import 'package:flutter/material.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSendPressed;
  final bool isEnabled;

  const ChatInputField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.onSubmitted,
    required this.onSendPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                hintText: '메세지를 입력하세요.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              onSubmitted: isEnabled ? onSubmitted : null,
              enabled: isEnabled,
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: isEnabled ? onSendPressed : null,
            backgroundColor: isEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
