import 'dart:async';

import 'package:flutter/material.dart';

/// 한 글자씩 순차적으로 표시되는 타이핑 효과 텍스트.
class TypingEffectText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int millisecondsPerCharacter;
  final bool animate;

  const TypingEffectText({
    super.key,
    required this.text,
    this.style,
    this.millisecondsPerCharacter = 25,
    this.animate = true,
  });

  @override
  State<TypingEffectText> createState() => _TypingEffectTextState();
}

class _TypingEffectTextState extends State<TypingEffectText> {
  int _visibleLength = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.text.isNotEmpty) {
      _scheduleNext();
    } else if (!widget.animate) {
      _visibleLength = widget.text.length;
    }
  }

  @override
  void didUpdateWidget(TypingEffectText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      if (widget.text.length < _visibleLength) {
        _visibleLength = widget.text.length;
      }
      if (widget.animate && _visibleLength < widget.text.length) {
        _scheduleNext();
      }
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: widget.millisecondsPerCharacter), () {
      if (!mounted) return;
      setState(() {
        if (_visibleLength < widget.text.length) {
          _visibleLength++;
          _scheduleNext();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = widget.animate
        ? widget.text.substring(0, _visibleLength.clamp(0, widget.text.length))
        : widget.text;
    final showCursor = widget.animate && _visibleLength < widget.text.length;

    return RichText(
      text: TextSpan(
        style: widget.style ?? DefaultTextStyle.of(context).style,
        children: [
          TextSpan(text: displayText),
          if (showCursor)
            TextSpan(
              text: '▌',
              style: (widget.style ?? DefaultTextStyle.of(context).style)
                  .copyWith(
                    color:
                        (widget.style?.color ??
                                DefaultTextStyle.of(context).style.color)
                            ?.withValues(alpha: 0.7),
                  ),
            ),
        ],
      ),
    );
  }
}
