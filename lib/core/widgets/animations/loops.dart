import 'package:flutter/material.dart';

/// Pulse — infinite gentle scale 1 → 1.08. Ports `@keyframes pulse`.
class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.child,
    this.amount = 0.08,
    this.duration = const Duration(milliseconds: 1200),
  });

  final Widget child;
  final double amount;
  final Duration duration;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.0 + widget.amount).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// EmojiFloat — infinite gentle vertical bob. Ports `@keyframes emojiFloat`.
class EmojiFloat extends StatefulWidget {
  const EmojiFloat({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2400),
  });

  final Widget child;
  final Duration duration;

  @override
  State<EmojiFloat> createState() => _EmojiFloatState();
}

class _EmojiFloatState extends State<EmojiFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

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
        return Transform.translate(
          offset: Offset(0, Tween(begin: 0.0, end: -6.0)
              .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
              .value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Shimmer — animated gradient sweep across the child. Ports `@keyframes shimmer`.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFFFFFFF),
    this.highlightColor = const Color(0x33FFFFFF),
    this.duration = const Duration(milliseconds: 1600),
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
          stops: const [0.35, 0.5, 0.65],
          transform: _SlidingGradientTransform(
            slidePercent: _controller.value * 2 - 1,
          ),
        ).createShader(bounds);
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// BorderPulse — animates border color between a dim and bright variant.
/// Ports `@keyframes greenBorder` / `amberBorder`.
class BorderPulse extends StatefulWidget {
  const BorderPulse({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final Widget child;
  final Color color;
  final BorderRadius borderRadius;

  @override
  State<BorderPulse> createState() => _BorderPulseState();
}

class _BorderPulseState extends State<BorderPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

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
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: Color.lerp(
                widget.color.withValues(alpha: 0.2),
                widget.color.withValues(alpha: 0.55),
                _controller.value,
              )!,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// NotifDot — pulsing dot used on notification bells. Ports `@keyframes notifDot`.
class NotifDot extends StatefulWidget {
  const NotifDot({super.key, this.color = const Color(0xFFFF6B6B), this.size = 8});

  final Color color;
  final double size;

  @override
  State<NotifDot> createState() => _NotifDotState();
}

class _NotifDotState extends State<NotifDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.3 + 0.6 * _controller.value,
                ),
                blurRadius: 2 + 6 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
