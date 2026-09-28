import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_safe_area.dart';

/// Boot splash — animated chili logo + tagline. Ports `SplashScreen`.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.hold = false});

  /// When true, stays on the splash forever (used while auth resolves).
  final bool hold;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _phase = 0; // 0=enter, 1=glow, 2=tagline, 3=fadeout
  Timer? _t1;
  Timer? _t2;
  Timer? _t3;
  Timer? _t4;

  @override
  void initState() {
    super.initState();
    _t1 = Timer(
      const Duration(milliseconds: 400),
      () => setState(() => _phase = 1),
    );
    _t2 = Timer(
      const Duration(milliseconds: 1000),
      () => setState(() => _phase = 2),
    );
    if (!widget.hold) {
      _t3 = Timer(
        const Duration(milliseconds: 2400),
        () => setState(() => _phase = 3),
      );
      _t4 = Timer(const Duration(milliseconds: 3000), () {
        if (mounted) context.read<FlowCubit>().setScreen(AppScreen.auth);
      });
    }
  }

  @override
  void dispose() {
    _t1?.cancel();
    _t2?.cancel();
    _t3?.cancel();
    _t4?.cancel();
    super.dispose();
  }

  static const _floaters = [
    (8, 12, '🍗', 0.0),
    (72, 8, '🌮', 0.3),
    (25, 72, '🍜', 0.6),
    (82, 65, '🍕', 0.2),
    (15, 42, '🥗', 0.8),
    (65, 38, '🍣', 0.5),
    (45, 82, '🍰', 0.4),
    (88, 28, '🥘', 0.7),
    (50, 15, '🧁', 0.9),
    (32, 55, '🍝', 1.0),
    (78, 80, '🥑', 0.1),
    (5, 85, '🍔', 0.55),
    (58, 52, '🥟', 0.35),
    (42, 28, '🌽', 0.75),
    (90, 48, '🍩', 0.45),
    (20, 92, '🫕', 0.65),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedOpacity(
        opacity: _phase == 3 ? 0 : 1,
        duration: const Duration(milliseconds: 600),
        child: AppSafeArea(
          child: Stack(
            children: [
              // Glow rings
              AnimatedContainer(
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutBack,
                width: _phase >= 1 ? 600 : 0,
                height: _phase >= 1 ? 600 : 0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x15FF6B6B),
                      Color(0x08FF6B6B),
                      Color(0x00FF6B6B),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutBack,
                width: _phase >= 1 ? 400 : 0,
                height: _phase >= 1 ? 400 : 0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x12F5A623), Color(0x00F5A623)],
                  ),
                ),
              ),
              // Floating emojis
              for (var i = 0; i < _floaters.length; i++)
                _Floater(
                  emoji: _floaters[i].$3,
                  left: _floaters[i].$1.toDouble(),
                  top: _floaters[i].$2.toDouble(),
                  delay: _floaters[i].$4,
                  index: i,
                  visible: _phase >= 1,
                ),
              // Center content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                      width: _phase >= 1 ? 120 : 60,
                      height: _phase >= 1 ? 120 : 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _phase >= 1
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0x22FF6B6B), Color(0x22F5A623)],
                              )
                            : null,
                        border: _phase >= 1
                            ? Border.all(
                                color: const Color(0x44FF6B6B),
                                width: 2,
                              )
                            : null,
                        boxShadow: _phase >= 1
                            ? [
                                BoxShadow(
                                  color: AppColors.coral.withValues(alpha: 0.2),
                                  blurRadius: 80,
                                ),
                                BoxShadow(
                                  color: AppColors.amber.withValues(
                                    alpha: 0.13,
                                  ),
                                  blurRadius: 40,
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedRotation(
                        turns: _phase >= 1 ? -0.05 : -0.083,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        child: const Text('🌶', style: TextStyle(fontSize: 64)),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: _phase >= 2 ? 1 : 0,
                      duration: const Duration(milliseconds: 500),
                      child: AnimatedSlide(
                        offset: _phase >= 2
                            ? Offset.zero
                            : const Offset(0, 0.3),
                        duration: const Duration(milliseconds: 500),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TagWord('swipe.', AppColors.coral, 0),
                            SizedBox(width: 12),
                            _TagWord('taste.', AppColors.amber, 1),
                            SizedBox(width: 12),
                            _TagWord('share.', AppColors.cyan, 2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom loading bar
              Positioned(
                bottom: 72,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 200,
                    height: 2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      color: const Color(0x0FFFFFFF),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1400),
                        curve: Curves.easeOut,
                        width: _phase >= 2 ? 200 : 0,
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.coral, AppColors.amber],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Text(
                  'zenT(n) Technologies',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0x40FFFFFF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagWord extends StatelessWidget {
  const _TagWord(this.text, this.color, this.index);

  final String text;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        fontFamily: 'Inter',
      ),
    );
  }
}

class _Floater extends StatelessWidget {
  const _Floater({
    required this.emoji,
    required this.left,
    required this.top,
    required this.delay,
    required this.index,
    required this.visible,
  });

  final String emoji;
  final double left;
  final double top;
  final double delay;
  final int index;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedOpacity(
        opacity: visible ? 0.15 : 0,
        duration: const Duration(milliseconds: 1000),
        child: Transform.rotate(
          angle: index * 0.38,
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}
