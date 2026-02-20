import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSendPressed;
  final bool isEnabled;

  const ChatInputField({
    super.key,
    required this.controller,
    this.focusNode,
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
            child: Focus(
              onKey: (FocusNode node, RawKeyEvent event) {
                if (event is RawKeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.enter &&
                      !event.isShiftPressed) {
                    // Handle Enter key press to send message
                    onSendPressed();
                    return KeyEventResult.handled; // Consume the event
                  }
                }
                return KeyEventResult.ignored; // Let other keys be handled by the TextField
              },
              child: TextField(
                style: const TextStyle(fontSize: 16.0),
                cursorColor: Theme.of(context).primaryColor,
                autofocus: true,
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: '메세지를 입력하세요. (Shift+Enter로 줄바꿈)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                onTap: () => focusNode?.requestFocus(),
                readOnly: !isEnabled,
                autocorrect: false,
                enableSuggestions: false,
                enabled: isEnabled,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: isEnabled ? onSendPressed : null,
            backgroundColor: isEnabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            elevation: 1,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
