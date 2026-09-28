import 'dart:async';

import 'package:flutter/material.dart';

import '../services/xp_float_service.dart';
import '../theme/app_colors.dart';

/// Floating "+XP" particles fed by [XpFloatService].
class XpFloatOverlay extends StatefulWidget {
  const XpFloatOverlay({super.key});

  @override
  State<XpFloatOverlay> createState() => _XpFloatOverlayState();
}

class _XpFloatOverlayState extends State<XpFloatOverlay> {
  StreamSubscription<XpFloat>? _sub;
  final List<_ActiveFloat> _active = [];

  @override
  void initState() {
    super.initState();
    _sub = XpFloatService.instance.stream.listen((float) {
      final entry = _ActiveFloat(float);
      setState(() => _active.add(entry));
      Timer(const Duration(milliseconds: 1900), () {
        if (mounted) setState(() => _active.remove(entry));
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_active.isEmpty) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            for (final entry in _active)
              _FloatingXpPill(
                key: ValueKey(entry.float.id),
                points: entry.float.points,
                x: entry.float.x ?? 40 + (entry.float.id % 5) * 18.0,
                y: entry.float.y ?? 60,
              ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFloat {
  _ActiveFloat(this.float);

  final XpFloat float;
}

class _FloatingXpPill extends StatefulWidget {
  const _FloatingXpPill({
    super.key,
    required this.points,
    required this.x,
    required this.y,
  });

  final int points;
  final double x;
  final double y;

  @override
  State<_FloatingXpPill> createState() => _FloatingXpPillState();
}

class _FloatingXpPillState extends State<_FloatingXpPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..forward();

  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.x,
      top: widget.y,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final dy = -(80 * _curve.value);
          final opacity = 1 - _curve.value;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, dy),
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
          ),
          child: Text(
            '+${widget.points} XP',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.amber,
            ),
          ),
        ),
      ),
    );
  }
}
