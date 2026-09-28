import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/glass.dart';
import '../widgets/auth_widgets.dart';

/// Auth landing — rotating taglines + trending dish + sign-up buttons.
/// Ports `AuthScreen`.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _taglines = [
    ('Discover recipes you\'ll actually cook.', ['swipe.', 'taste.', 'share.']),
    ('Your cravings, one swipe away.', ['crave.', 'match.', 'cook.']),
    ('From first bite to family favorite.', ['find.', 'savor.', 'repeat.']),
  ];
  static const _trending = [
    ('🍗', 'Gochujang Glazed Fried Chicken'),
    ('🍜', 'Spicy Garlic Miso Ramen'),
    ('🌮', 'Birria Tacos with Consomé'),
    ('🍣', 'Crispy Salmon Sushi Stack'),
  ];

  int _tagIdx = 0;
  int _dishIdx = 0;
  Timer? _tagTimer;
  Timer? _dishTimer;

  @override
  void initState() {
    super.initState();
    _tagTimer = Timer.periodic(
      const Duration(milliseconds: 3800),
      (_) => setState(() => _tagIdx = (_tagIdx + 1) % _taglines.length),
    );
    _dishTimer = Timer.periodic(
      const Duration(milliseconds: 3200),
      (_) => setState(() => _dishIdx = (_dishIdx + 1) % _trending.length),
    );
  }

  @override
  void dispose() {
    _tagTimer?.cancel();
    _dishTimer?.cancel();
    super.dispose();
  }

  void _oauth(String provider) {
    ToastService.instance.show('🔗 Connecting $provider…');
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final tagline = _taglines[_tagIdx];
    final dish = _trending[_dishIdx];
    return Material(color: Colors.transparent, child: Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A14),
            Color(0xFF0D0D1A),
            Color(0xFF0A0A12),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Glow blobs
          Positioned(
            top: -80,
            left: -80,
            child: Pulse(
              amount: 0.15,
              duration: const Duration(seconds: 7),
              child: Container(
                width: 340,
                height: 340,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Color(0x12FF6B6B),
                    Color(0x00FF6B6B),
                  ]),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -90,
            child: Pulse(
              amount: 0.15,
              duration: const Duration(seconds: 8),
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Color(0x0D4ECDC4),
                    Color(0x004ECDC4),
                  ]),
                ),
              ),
            ),
          ),
          // Floating emojis
          const _FloatingFood(),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PopIn(
                          duration: const Duration(milliseconds: 800),
                          child: const _Logo(),
                        ),
                        const SizedBox(height: 12),
                        _RotatingTagline(
                          key: ValueKey('tagline-$_tagIdx'),
                          headline: tagline.$1,
                          words: tagline.$2,
                        ),
                        const SizedBox(height: 18),
                        _TrendingDish(
                          key: ValueKey('dish-$_dishIdx'),
                          emoji: dish.$1,
                          title: dish.$2,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      StaggerReveal(
                        stagger: const Duration(milliseconds: 120),
                        children: [
                          _OAuthButton(
                            label: 'Continue with Google',
                            emoji: 'G',
                            onTap: () => _oauth('Google'),
                          ),
                          const SizedBox(height: 12),
                          _OAuthButton(
                            label: 'Continue with Apple',
                            emoji: '',
                            onTap: () => _oauth('Apple'),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: AuthOrDivider(),
                      ),
                      SlideUp(
                        duration: const Duration(milliseconds: 400),
                        child: AuthPrimaryButton(
                          label: 'Sign up with Email',
                          onTap: () => flow.setScreen(AppScreen.emailSignup),
                          glow: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => flow.setScreen(AppScreen.emailLogin),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "Already have an account? Log in",
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "By continuing, you agree to b🌶te's Terms of Service\nand Privacy Policy.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0x1FFFFFFF),
                          fontSize: 10,
                          height: 1.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
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

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: const [
        Text(
          'b',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -2,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          '🌶',
          style: TextStyle(fontSize: 48),
        ),
        Text(
          'te',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -2,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }
}

class _RotatingTagline extends StatelessWidget {
  const _RotatingTagline({super.key, required this.headline, required this.words});

  final String headline;
  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.coral, AppColors.amber, AppColors.cyan];
    return Column(
      children: [
        FadeInOut(
          duration: const Duration(milliseconds: 3800),
          child: Text(
            headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0x73FFFFFF),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(height: 12),
        PopIn(
          duration: const Duration(milliseconds: 500),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < words.length; i++)
                Padding(
                  padding: EdgeInsets.only(right: i == words.length - 1 ? 0 : 16),
                  child: EmojiFloat(
                    duration: Duration(milliseconds: 2500 + i * 300),
                    child: Transform.rotate(
                      angle: [-3, 0, 3][i] * 0.017,
                      child: Text(
                        words[i],
                        style: TextStyle(
                          color: colors[i],
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendingDish extends StatelessWidget {
  const _TrendingDish({super.key, required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ZoomIn(
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔥', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 8),
            const Text(
              'TRENDING NOW',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$emoji $title',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  const _OAuthButton({
    required this.label,
    required this.emoji,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      onTap: onTap,
      borderRadius: 100,
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingFood extends StatelessWidget {
  const _FloatingFood();

  static const _items = [
    (12, 15, '🍗'),
    (78, 10, '🍣'),
    (25, 75, '🌮'),
    (85, 70, '🍸'),
    (50, 85, '🍕'),
    (8, 45, '🥗'),
    (90, 40, '🧁'),
    (65, 20, '🍜'),
    (35, 55, '🥂'),
    (55, 65, '🔥'),
    (18, 90, '🌶'),
    (72, 88, '☕'),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (var i = 0; i < _items.length; i++)
            Positioned(
              left: _items[i].$1.toDouble(),
              top: _items[i].$2.toDouble(),
              child: EmojiFloat(
                duration: Duration(milliseconds: 4500 + (i % 5) * 700),
                child: Text(
                  _items[i].$3,
                  style: TextStyle(
                    fontSize: 13 + (i % 4) * 5,
                    color: Colors.white.withValues(alpha: 0.055),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
