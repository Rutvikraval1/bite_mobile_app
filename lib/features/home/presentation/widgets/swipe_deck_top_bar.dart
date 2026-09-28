import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/loops.dart';

/// Tier ring colors — mirrors the prototype's avatar ring gradient.
class _TierRing {
  const _TierRing(this.min, this.max, this.color, this.colorEnd, this.emoji);

  final int min;
  final int max;
  final Color color;
  final Color colorEnd;
  final String emoji;
}

const List<_TierRing> _tiers = [
  _TierRing(0, 10, Color(0xFF64B5F6), Color(0xFF42A5F5), '👀'),
  _TierRing(10, 30, Color(0xFF4CAF50), Color(0xFF66BB6A), '🥄'),
  _TierRing(30, 75, AppColors.coral, Color(0xFFFF8A65), '🍳'),
  _TierRing(75, 150, AppColors.placesPurple, Color(0xFFAB47BC), '🧑‍🍳'),
  _TierRing(150, 300, AppColors.amber, Color(0xFFFFD54F), '👨‍🍳'),
];

/// Fixed header for the swipe deck — ports `SwipeDeckTopBar` from
/// `screens-deck.jsx`.
class SwipeDeckTopBar extends StatelessWidget {
  const SwipeDeckTopBar({
    super.key,
    required this.subTab,
    required this.onSubTabChanged,
    required this.onAvatarClick,
    required this.onBellClick,
    required this.onTrophyClick,
    required this.onCrownClick,
    required this.onMealReminderClick,
    required this.onDrinksGate,
    required this.onPlacesGate,
    required this.ageVerified,
    required this.locationGranted,
    required this.xp,
    required this.notificationCount,
    this.avatarEmoji,
  });

  final DeckTab subTab;
  final ValueChanged<DeckTab> onSubTabChanged;
  final VoidCallback onAvatarClick;
  final VoidCallback onBellClick;
  final VoidCallback onTrophyClick;
  final VoidCallback onCrownClick;
  final VoidCallback onMealReminderClick;
  final VoidCallback onDrinksGate;
  final VoidCallback onPlacesGate;
  final bool ageVerified;
  final bool locationGranted;
  final int xp;
  final int notificationCount;
  final String? avatarEmoji;

  Color get _tabColor => switch (subTab) {
        DeckTab.food => AppColors.coral,
        DeckTab.drinks => AppColors.drinksBlue,
        DeckTab.places => AppColors.placesPurple,
      };

  _TierRing get _tier {
    for (final t in _tiers) {
      if (xp >= t.min && xp < t.max) return t;
    }
    return _tiers.last;
  }

  @override
  Widget build(BuildContext context) {
    final tiny = MediaQuery.sizeOf(context).height < 600;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(13, 13, 13, 0.97),
            Color.fromRGBO(13, 13, 13, 0.92),
            Color.fromRGBO(13, 13, 13, 0.60),
            Colors.transparent,
          ],
          stops: [0, 0.6, 0.85, 1],
        ),
      ),
      padding: EdgeInsets.only(top: tiny ? 4 : 8),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tiny ? 12 : 16,
              vertical: tiny ? 2 : 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _AvatarButton(
                  tier: _tier,
                  emoji: avatarEmoji ?? _tier.emoji,
                  size: tiny ? 30 : 38,
                  onTap: onAvatarClick,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconButton(
                      icon: Icons.emoji_events_outlined,
                      color: AppColors.amber,
                      size: tiny ? 16 : 20,
                      glow: const Color(0x44F5A623),
                      onTap: onTrophyClick,
                      padding: tiny ? 28 : 36,
                    ),
                    _IconButton(
                      icon: Icons.workspace_premium_outlined,
                      color: AppColors.coral,
                      size: tiny ? 16 : 20,
                      onTap: onCrownClick,
                      padding: tiny ? 28 : 36,
                    ),
                    _IconButton(
                      icon: Icons.schedule_rounded,
                      color: const Color(0x8CFFFFFF),
                      size: tiny ? 14 : 17,
                      onTap: onMealReminderClick,
                      padding: tiny ? 28 : 36,
                      badge: const Pulse(
                        amount: 0.6,
                        duration: Duration(milliseconds: 1400),
                        child: _Dot(color: AppColors.amber, size: 6),
                      ),
                    ),
                    _IconButton(
                      icon: Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: tiny ? 16 : 20,
                      onTap: onBellClick,
                      padding: tiny ? 28 : 36,
                      badge: _BellBadge(
                        count: notificationCount,
                        size: tiny ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tiny ? 10 : 16,
              vertical: tiny ? 1 : 2,
            ),
            child: _SubTabSwitcher(
              subTab: subTab,
              onSubTabChanged: (next) {
                if (next == DeckTab.drinks && !ageVerified) {
                  onDrinksGate();
                  return;
                }
                if (next == DeckTab.places && !locationGranted) {
                  onPlacesGate();
                  return;
                }
                onSubTabChanged(next);
              },
              tabColor: _tabColor,
              tiny: tiny,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({
    required this.tier,
    required this.emoji,
    required this.size,
    required this.onTap,
  });

  final _TierRing tier;
  final String emoji;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [tier.color, tier.colorEnd, tier.color],
          ),
          boxShadow: [
            BoxShadow(
              color: tier.color.withValues(alpha: 0.33),
              blurRadius: 14,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: tier.color.withValues(alpha: 0.13),
              blurRadius: 30,
            ),
          ],
        ),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tier.color.withValues(alpha: 0.53),
                tier.colorEnd.withValues(alpha: 0.4),
              ],
            ),
            border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
          ),
          child: Text(
            emoji,
            style: TextStyle(fontSize: size * 0.42),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    required this.padding,
    this.glow,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final double padding;
  final Color? glow;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: padding,
        height: padding,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: size,
              color: color,
              shadows: glow == null
                  ? null
                  : [Shadow(color: glow!, blurRadius: 8)],
            ),
            if (badge != null) Positioned(top: 0, right: 0, child: badge!),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 6)],
      ),
    );
  }
}

class _BellBadge extends StatelessWidget {
  const _BellBadge({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: AppColors.coral,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFF0D0D0D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.6),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.55,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _SubTabSwitcher extends StatefulWidget {
  const _SubTabSwitcher({
    required this.subTab,
    required this.onSubTabChanged,
    required this.tabColor,
    required this.tiny,
  });

  final DeckTab subTab;
  final ValueChanged<DeckTab> onSubTabChanged;
  final Color tabColor;
  final bool tiny;

  @override
  State<_SubTabSwitcher> createState() => _SubTabSwitcherState();
}

class _SubTabSwitcherState extends State<_SubTabSwitcher> {
  @override
  Widget build(BuildContext context) {
    final items = [
      (DeckTab.food, 'Food', '🍽', AppColors.coral),
      (DeckTab.drinks, 'Drinks', '🍸', AppColors.drinksBlue),
      (DeckTab.places, 'Places', '📍', AppColors.placesPurple),
    ];
    final index = items.indexWhere((i) => i.$1 == widget.subTab);
    return Container(
      height: widget.tiny ? 34 : 42,
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(widget.tiny ? 12 : 16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.tiny ? 12 : 16),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Shimmer(
                baseColor: Colors.transparent,
                highlightColor: Color(0x0DFFFFFF),
                duration: Duration(seconds: 8),
                child: SizedBox.expand(),
              ),
            ),
            // Indicator rail under the active tab
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              left: (16 + index * (1 / 3) * 100) / 100 *
                  MediaQuery.sizeOf(context).width,
              bottom: 2,
              width: MediaQuery.sizeOf(context).width / 3 - 24,
              height: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      widget.tabColor,
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.tabColor.withValues(alpha: 0.66),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _TabPill(
                      label: items[i].$2,
                      emoji: items[i].$3,
                      color: items[i].$4,
                      active: items[i].$1 == widget.subTab,
                      tiny: widget.tiny,
                      onTap: () => widget.onSubTabChanged(items[i].$1),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.emoji,
    required this.color,
    required this.active,
    required this.tiny,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Color color;
  final bool active;
  final bool tiny;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tiny ? 9 : 12),
          gradient: active
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.8)],
                )
              : null,
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.6)
                : Colors.transparent,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.27),
                    blurRadius: 14,
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.18),
                    blurRadius: 1,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: active ? 1 : 0.55,
              child: Text(
                emoji,
                style: TextStyle(fontSize: tiny ? 12 : 15),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: tiny ? 11 : 14,
                fontWeight: FontWeight.w700,
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                shadows: active
                    ? [Shadow(color: color.withValues(alpha: 0.33), blurRadius: 8)]
                    : null,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep math import used for potential future glow math (avoid unused-import).
// ignore: unused_element
double _glowSpread(double v) => math.min(1, v);
