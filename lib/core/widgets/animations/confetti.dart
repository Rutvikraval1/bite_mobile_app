import 'dart:math' as math;

import 'package:flutter/material.dart';

/// ConfettiFall — falling confetti particles. Ports `@keyframes confettiFall`.
class ConfettiFall extends StatefulWidget {
  const ConfettiFall({
    super.key,
    this.count = 16,
    this.colors = const [
      Color(0xFFFF6B6B),
      Color(0xFFF5A623),
      Color(0xFF4ECDC4),
      Color(0xFF9B59B6),
      Color(0xFF66BB6A),
      Color(0xFFFFD700),
    ],
    this.particleSize = 7,
  });

  final int count;
  final List<Color> colors;
  final double particleSize;

  @override
  State<ConfettiFall> createState() => _ConfettiFallState();
}

class _ConfettiFallState extends State<ConfettiFall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );

  late final List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _particles = List.generate(widget.count, (i) {
      return _ConfettiParticle(
        x: random.nextDouble(),
        delay: random.nextDouble() * 0.4,
        duration: 2.4 + random.nextDouble() * 1.6,
        size: widget.particleSize * (0.6 + random.nextDouble() * 0.9),
        rotation: random.nextDouble() * math.pi * 2,
        color: widget.colors[i % widget.colors.length],
        drift: (random.nextDouble() - 0.5) * 80,
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final particle in _particles)
                    Positioned(
                      left: particle.x * width + particle.drift * _sine(_controller.value - particle.delay),
                      top: height * _progress(_controller.value, particle) - particle.size,
                      child: Transform.rotate(
                        angle: particle.rotation + _controller.value * 8,
                        child: Container(
                          width: particle.size,
                          height: particle.size * 0.7,
                          decoration: BoxDecoration(
                            color: particle.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  double _progress(double t, _ConfettiParticle p) {
    final value = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
    return Curves.easeOut.transform(value);
  }

  double _sine(double t) => math.sin(t * math.pi * 6);
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.duration,
    required this.size,
    required this.rotation,
    required this.color,
    required this.drift,
  });

  final double x;
  final double delay;
  final double duration;
  final double size;
  final double rotation;
  final Color color;
  final double drift;
}
