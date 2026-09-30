import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// One run of text; tappable (and styled as a link) when [onTap] is set.
class LinkedTextSegment {
  const LinkedTextSegment(this.text, {this.onTap});

  final String text;
  final VoidCallback? onTap;
}

/// Rich text where some segments are tappable links.
class LinkedText extends StatefulWidget {
  const LinkedText({
    super.key,
    required this.segments,
    required this.style,
    this.linkStyle,
    this.textAlign = TextAlign.start,
  });

  final List<LinkedTextSegment> segments;
  final TextStyle style;

  /// Merged over [style] for link segments. Defaults to underline.
  final TextStyle? linkStyle;
  final TextAlign textAlign;

  @override
  State<LinkedText> createState() => _LinkedTextState();
}

class _LinkedTextState extends State<LinkedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _recognizer(VoidCallback onTap) {
    final r = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(r);
    return r;
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final linkStyle = widget.style.merge(
      widget.linkStyle ?? const TextStyle(decoration: TextDecoration.underline),
    );
    return Text.rich(
      TextSpan(
        style: widget.style,
        children: [
          for (final s in widget.segments)
            if (s.onTap == null)
              TextSpan(text: s.text)
            else
              TextSpan(
                text: s.text,
                style: linkStyle,
                recognizer: _recognizer(s.onTap!),
              ),
        ],
      ),
      textAlign: widget.textAlign,
    );
  }
}
