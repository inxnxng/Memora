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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Focus(
                onKeyEvent: (FocusNode node, KeyEvent event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.enter &&
                        !HardwareKeyboard.instance.isShiftPressed) {
                      onSendPressed();
                      return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  style: theme.textTheme.bodyLarge,
                  cursorColor: theme.colorScheme.primary,
                  autofocus: true,
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요 (Shift+Enter: 줄바꿈)',
                    hintStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  readOnly: !isEnabled,
                  autocorrect: false,
                  enableSuggestions: false,
                  enabled: isEnabled,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: isEnabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              elevation: isEnabled ? 0 : 0,
              child: InkWell(
                onTap: isEnabled ? onSendPressed : null,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.send_rounded,
                    size: 24,
                    color: isEnabled
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
