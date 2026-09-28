import 'dart:async';

import 'package:flutter/material.dart';

/// Sticky bottom "scroll" hint that fades away after a moment.
/// Ports `ScrollHint` from `ui.jsx`.
class ScrollHint extends StatefulWidget {
  const ScrollHint({super.key, this.color = const Color(0xB3FFFFFF)});

  final Color color;

  @override
  State<ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<ScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _controller,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 48,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF0D0D0D).withValues(alpha: 0.9),
                  const Color(0xFF0D0D0D).withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SCROLL',
                  style: TextStyle(
                    color: widget.color.withValues(alpha: 0.6),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    color: widget.color.withValues(alpha: 0.7), size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
