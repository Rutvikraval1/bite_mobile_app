import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';

/// Prototype welcome gate — first-time intro. Ports `WelcomeGateScreen`.
class WelcomeGateScreen extends StatefulWidget {
  const WelcomeGateScreen({super.key});

  @override
  State<WelcomeGateScreen> createState() => _WelcomeGateScreenState();
}

class _WelcomeGateScreenState extends State<WelcomeGateScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  static const _items = [
    ('🧪', 'Interactive demo — tap, swipe & explore', AppColors.cyan),
    ('⌨️', 'Fields auto-fill on tap — no typing needed', Color(0xFF4CAF50)),
    ('🆓', 'Everything unlocked — Premium, AI & ordering', AppColors.amber),
    ('🎨', 'Emoji visuals — real app has photos & themes', AppColors.coral),
    ('📊', 'Sample data — recipes, stats are placeholders', AppColors.placesPurple),
    ('🚀', 'Planned features — final app may vary', Color(0xFF64B5F6)),
    ('💬', "We'd love your feedback!", Color(0xFFFFD700)),
  ];

  static const _floaters = [
    (12, 15, '🍗'), (78, 10, '🍣'), (25, 75, '🌮'), (85, 70, '🍸'),
    (50, 85, '🍕'), (8, 45, '🥗'), (90, 40, '🧁'), (65, 20, '🍜'),
    (35, 55, '🥂'), (55, 65, '🔥'), (18, 90, '🌶'), (72, 88, '☕'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.bgDark,
      child: Stack(
        children: [
          for (var i = 0; i < _floaters.length; i++)
            Positioned(
              left: _floaters[i].$1.toDouble(),
              top: _floaters[i].$2.toDouble(),
              child: AnimatedOpacity(
                opacity: _ready ? 0.12 : 0,
                duration: const Duration(milliseconds: 1500),
                child: EmojiFloat(
                  duration: Duration(seconds: 5 + (i % 3)),
                  child: Text(
                    _floaters[i].$3,
                    style: TextStyle(fontSize: 16 + (i % 4) * 4),
                  ),
                ),
              ),
            ),
          Pulse(
            amount: 0.06,
            duration: const Duration(seconds: 6),
            child: const Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 400,
                  height: 400,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Color(0x08FF6B6B),
                        Color(0x04F5A623),
                        Color(0x00000000),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
              child: Column(
                children: [
                  if (_ready)
                    PopIn(
                      duration: const Duration(milliseconds: 600),
                      child: const _GateLogo(),
                    ),
                  const SizedBox(height: 24),
                  AnimatedOpacity(
                    opacity: _ready ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: GlassCard(
                      items: _items,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _VersionPill(),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const ExploreButton(),
                  const SizedBox(height: 12),
                  const Text(
                    'Swipe up to save · Down to pass · Tap for details · ⭐ to favorite',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0x40FFFFFF),
                      fontSize: 10,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

class _GateLogo extends StatelessWidget {
  const _GateLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'b',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -2,
                fontFamily: 'Inter',
              ),
            ),
            Text('🌶', style: TextStyle(fontSize: 44)),
            Text(
              'te',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -2,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Discover recipes you\'ll actually cook',
          style: TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.items});

  final List<(String, String, Color)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('👋', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'Welcome to the prototype',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: StaggerReveal(
                stagger: const Duration(milliseconds: 80),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: items[i].$3.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: items[i].$3.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].$1, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            items[i].$2,
                            style: TextStyle(
                              color: items[i].$3.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _VersionPill extends StatelessWidget {
  const _VersionPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            AppConfig.versionLabel,
            style: TextStyle(
              color: AppColors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const Text(' · ', style: TextStyle(color: AppColors.muted, fontSize: 10)),
          const Text(
            'zenT(n) Technologies',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class ExploreButton extends StatefulWidget {
  const ExploreButton({super.key});

  @override
  State<ExploreButton> createState() => _ExploreButtonState();
}

class _ExploreButtonState extends State<ExploreButton> {
  @override
  Widget build(BuildContext context) {
    return Pulse(
      amount: 0.05,
      duration: const Duration(milliseconds: 2000),
      child: GestureDetector(
        onTap: () => context.read<FlowCubit>().setScreen(AppScreen.splash),
        child: Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [
              AppColors.coral,
              AppColors.amber,
              AppColors.cyan,
              AppColors.placesPurple,
              AppColors.coral,
            ]),
            boxShadow: [
              BoxShadow(color: Color(0x33FF6B6B), blurRadius: 30),
              BoxShadow(color: Color(0x15F5A623), blurRadius: 60),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bgDark,
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌶', style: TextStyle(fontSize: 28)),
                  SizedBox(height: 2),
                  Text(
                    'EXPLORE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
