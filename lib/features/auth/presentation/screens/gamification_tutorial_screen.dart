import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/app_safe_area.dart';
import '../../../../core/widgets/glass.dart';

/// Post-onboarding gamification explainer. Ports `GamificationTutorialScreen`.
class GamificationTutorialScreen extends StatefulWidget {
  const GamificationTutorialScreen({super.key});

  @override
  State<GamificationTutorialScreen> createState() =>
      _GamificationTutorialScreenState();
}

class _GamificationTutorialScreenState
    extends State<GamificationTutorialScreen> {
  static const _actions = [
    (icon: '🍳', label: 'Cook', pts: 10),
    (icon: '🌶️', label: 'Rate', pts: 5),
    (icon: '📷', label: 'Photo', pts: 5),
    (icon: '✍️', label: 'Create', pts: 20),
    (icon: '🔥', label: 'Streak', pts: 50),
  ];
  static const _tiers = [
    '🥚 Newbie',
    '🥄 Curious',
    '🍳 Home Cook',
    '🔪 Sous Chef',
    '👨‍🍳 Chef',
    '⭐ Master',
    '👑 Legend',
  ];
  static const _badgeChips = [
    '🥄 First Bite',
    '🔥 Streak',
    '✈️ Traveler',
    '🍸 Mixer',
    '📤 Sharer',
    '🌟 OG',
  ];
  static const _stats = [
    (icon: '⭐', value: '847', label: 'XP Earned', color: Color(0xFFFFD700)),
    (icon: '🔥', value: '12', label: 'Day Streak', color: AppColors.coral),
    (icon: '🪙', value: '156', label: 'Bite Coins', color: AppColors.amber),
    (icon: '🏅', value: '6', label: 'Badges', color: AppColors.cyan),
  ];
  static const _markers = [
    (name: '🥚', pct: 0.0, active: false),
    (name: '🥄', pct: 0.08, active: false),
    (name: '🍳', pct: 0.25, active: true),
    (name: '🔪', pct: 0.50, active: false),
    (name: '👨‍🍳', pct: 0.70, active: false),
    (name: '⭐', pct: 0.88, active: false),
    (name: '👑', pct: 1.00, active: false),
  ];

  int _visible = 0;
  bool _hasScrolled = false;
  final ScrollController _scrollController = ScrollController();
  List<Timer>? _timers;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted && _scrollController.offset > 0 && !_hasScrolled) {
        setState(() => _hasScrolled = true);
      }
    });
    _timers = [
      Timer(
        const Duration(milliseconds: 200),
        () => mounted ? setState(() => _visible = 1) : null,
      ),
      Timer(
        const Duration(milliseconds: 700),
        () => mounted ? setState(() => _visible = 2) : null,
      ),
      Timer(
        const Duration(milliseconds: 1200),
        () => mounted ? setState(() => _visible = 3) : null,
      ),
    ];
  }

  @override
  void dispose() {
    for (final t in _timers ?? []) {
      t.cancel();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<FlowCubit>().setScreen(AppScreen.swipeDeck);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AppSafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 160),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Pulse(
                              amount: 0.1,
                              duration: Duration(milliseconds: 2000),
                              child: Text('✨', style: TextStyle(fontSize: 20)),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'How b🌶te Works',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _finish,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionCard(
                          visible: _visible >= 1,
                          topBar: const [AppColors.coral, AppColors.amber],
                          icon: '🔥',
                          title: 'Every Action Earns Points',
                          subtitle: 'The more you cook, the more you earn',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var i = 0; i < _actions.length; i++)
                                _action(_actions[i], i),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          visible: _visible >= 2,
                          topBar: const [AppColors.amber, Color(0xFFFFD700)],
                          icon: '📊',
                          title: 'Level Up & Earn Rewards',
                          subtitle:
                              '7 tiers + daily chests with coins & shards',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < _tiers.length; i++)
                                      _tierLine(i),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                children: [
                                  Text('📦', style: TextStyle(fontSize: 32)),
                                  Text(
                                    'Daily',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 9,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text('👑', style: TextStyle(fontSize: 32)),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_visible >= 2 && !_hasScrolled)
                          Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 8),
                            child: Column(
                              children: [
                                const Text(
                                  'MORE BELOW',
                                  style: TextStyle(
                                    color: Color(0x4DFFFFFF),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const Pulse(
                                  amount: 0.3,
                                  duration: Duration(milliseconds: 1200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Color(0x40FFFFFF),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          visible: _visible >= 3,
                          topBar: const [AppColors.cyan, AppColors.coral],
                          icon: '🏅',
                          title: '116+ Badges & Collectibles',
                          subtitle: 'Frames, pets, seasonal events & more',
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (var i = 0; i < _badgeChips.length; i++)
                                _badgeChip(i),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _HeadStartCard(visible: _visible >= 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                opacity: _visible >= 3 ? 1 : 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.bgDark.withValues(alpha: 0.0),
                        AppColors.bgDark,
                      ],
                    ),
                  ),
                  child: GestureDetector(
                    onTap: _finish,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.coral, AppColors.amber],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.coral.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Start Swiping! 🔥',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(({String icon, String label, int pts}) a, int i) {
    return PopIn(
      duration: const Duration(milliseconds: 300),
      begin: 0.3 + i * 0.08,
      child: Column(
        children: [
          Text(a.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            '+${a.pts}',
            style: const TextStyle(
              color: Color(0xFF69F0AE),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: Color(0x4D69F0AE), blurRadius: 8)],
              fontFamily: 'Inter',
            ),
          ),
          Text(
            a.label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 9,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierLine(int i) {
    final isYou = i == 2;
    final color = isYou
        ? AppColors.coral
        : i < 2
        ? const Color(0x80FFFFFF)
        : const Color(0x40FFFFFF);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            _tiers[i],
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isYou ? FontWeight.w800 : FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
          if (isYou)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0x1A4CAF50),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'YOU',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badgeChip(int i) {
    return PopIn(
      duration: const Duration(milliseconds: 280),
      begin: 0.2 + i * 0.06,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0x14FFFFFF)),
        ),
        child: Text(
          _badgeChips[i],
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.visible,
    required this.topBar,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final bool visible;
  final List<Color> topBar;
  final String icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        child: Glass(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3,
                child: _TopBar(colors: topBar, running: visible),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Pulse(
                        amount: 0.08,
                        duration: const Duration(milliseconds: 1500),
                        child: Text(icon, style: const TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                              ),
                            ),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  child,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar({required this.colors, required this.running});

  final List<Color> colors;
  final bool running;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  @override
  void initState() {
    super.initState();
    if (widget.running) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only react to actual changes — parent rebuilds must not restart it.
    if (widget.running == oldWidget.running) return;
    if (widget.running) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                ...widget.colors,
                Colors.transparent,
              ],
              transform: _SlidingTransform(_controller.value * 2 - 1),
            ).createShader(bounds);
          },
          child: Container(height: 3, color: Colors.white),
        );
      },
      ),
    );
  }
}

class _SlidingTransform extends GradientTransform {
  const _SlidingTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}

class _HeadStartCard extends StatelessWidget {
  const _HeadStartCard({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        offset: visible ? Offset.zero : const Offset(0, 0.08),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x0FFF6B6B), Color(0x0AF5A623), Color(0x084ECDC4)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x0FFFFFFF)),
          ),
          child: Column(
            children: [
              const Text(
                '🎯 Your Head Start',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (
                    var i = 0;
                    i < _GamificationTutorialScreenState._stats.length;
                    i++
                  )
                    Expanded(child: _statCard(i)),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '⭐ 847 / 1,200 XP',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    'Next: Sous Chef 🔪',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 9,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.easeOutCubic,
                  height: 10,
                  width: double.infinity,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(color: const Color(0x0FFFFFFF)),
                  child: FractionallySizedBox(
                    widthFactor: visible ? 0.706 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4CAF50),
                            Color(0xFFFFD700),
                            Color(0xFFFF8C00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFFD700,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    for (
                      var i = 0;
                      i < _GamificationTutorialScreenState._markers.length;
                      i++
                    )
                      Positioned(
                        left:
                            _GamificationTutorialScreenState._markers[i].pct *
                                100 -
                            6,
                        top: 0,
                        child: Column(
                          children: [
                            Container(
                              width: 2,
                              height: 4,
                              color:
                                  _GamificationTutorialScreenState
                                      ._markers[i]
                                      .active
                                  ? AppColors.coral
                                  : const Color(0x1FFFFFFF),
                            ),
                            Text(
                              _GamificationTutorialScreenState._markers[i].name,
                              style: TextStyle(
                                fontSize:
                                    _GamificationTutorialScreenState
                                        ._markers[i]
                                        .active
                                    ? 12
                                    : 9,
                                color:
                                    _GamificationTutorialScreenState
                                        ._markers[i]
                                        .active
                                    ? Colors.white
                                    : const Color(0x66FFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text.rich(
                TextSpan(
                  text: "You're already a ",
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontFamily: 'Inter',
                  ),
                  children: [
                    TextSpan(
                      text: 'Home Cook',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' — keep climbing!'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(int i) {
    final s = _GamificationTutorialScreenState._stats[i];
    return PopIn(
      duration: const Duration(milliseconds: 320),
      begin: 0.3 + i * 0.1,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: s.color.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: s.color.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Text(s.icon, style: const TextStyle(fontSize: 16)),
            Text(
              s.value,
              style: TextStyle(
                color: s.color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
              ),
            ),
            Text(
              s.label,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 8,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
