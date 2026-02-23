import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:memora/models/chat_message.dart';
import 'package:memora/widgets/typing_effect_text.dart';

class ChatMessagesList extends StatelessWidget {
  final List<ChatMessage> messages;

  const ChatMessagesList({super.key, required this.messages});

  /// 목록은 최신순이므로, 첫 번째 AI 메시지가 가장 최신 AI 응답.
  int? _indexOfNewestAiMessage() {
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].sender == MessageSender.ai) return i;
    }
    return null;
  }

  /// 가장 최근 사용자 메시지의 timestamp (목록은 최신순).
  DateTime? _latestUserMessageTimestamp() {
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].sender == MessageSender.user) {
        return messages[i].timestamp;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(child: WavingDots());
    }
    final theme = Theme.of(context);
    final newestAiIndex = _indexOfNewestAiMessage();
    final latestUserTs = _latestUserMessageTimestamp();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.sender == MessageSender.user;
        final isSystem = message.sender == MessageSender.system;
        // 사용자가 최근 보낸 메시지보다 더 최신인 AI 메시지에만 타이핑 효과 적용
        final useTypingEffect =
            message.sender == MessageSender.ai &&
            newestAiIndex == index &&
            (latestUserTs == null || message.timestamp.isAfter(latestUserTs));

        return GestureDetector(
          key: ValueKey(message.id),
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: message.content));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('메시지가 복사되었습니다')));
          },
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.82,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primaryContainer
                      : isSystem
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.sender == MessageSender.ai && !isSystem)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.smart_toy_outlined,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    useTypingEffect
                        ? TypingEffectText(
                            text: message.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              height: 1.4,
                            ),
                            millisecondsPerCharacter: 20,
                          )
                        : Text(
                            message.content,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface,
                              height: 1.4,
                            ),
                          ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i * 0.15;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final offset = (value * 2 - 1) * 8;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, offset),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
