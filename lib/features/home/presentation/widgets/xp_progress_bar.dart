import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tier entry for the XP bar — mirrors the prototype ladder.
class _XpTier {
  const _XpTier(this.min, this.max, this.level, this.name, this.emoji,
      this.color, this.colorEnd, this.nextColor, this.nextEmoji);

  final int min;
  final int max;
  final int level;
  final String name;
  final String emoji;
  final Color color;
  final Color colorEnd;
  final Color nextColor;
  final String nextEmoji;
}

const List<_XpTier> _tiers = [
  _XpTier(0, 10, 1, 'Curious', '👀', Color(0xFF64B5F6), Color(0xFF42A5F5),
      Color(0xFF4CAF50), '🥄'),
  _XpTier(10, 30, 2, 'Beginner', '🥄', Color(0xFF4CAF50), Color(0xFF66BB6A),
      AppColors.coral, '🍳'),
  _XpTier(30, 75, 3, 'Home Cook', '🍳', AppColors.coral, Color(0xFFFF8A65),
      AppColors.placesPurple, '🧑‍🍳'),
  _XpTier(75, 150, 4, 'Sous Chef', '🧑‍🍳', AppColors.placesPurple,
      Color(0xFFAB47BC), AppColors.amber, '👨‍🍳'),
  _XpTier(150, 300, 5, 'Chef', '👨‍🍳', AppColors.amber, Color(0xFFFFD54F),
      Color(0xFFFFD700), '🏆'),
];

/// Tier-themed XP progress bar — ports the inline block from
/// `SwipeDeckScreen` in `screens-deck.jsx`.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    super.key,
    required this.xp,
    required this.streakCount,
    required this.streakMultiplier,
    this.xpFlash,
    this.onTap,
    this.onStreakTap,
  });

  final int xp;
  final int streakCount;
  final double streakMultiplier;
  final int? xpFlash;
  final VoidCallback? onTap;
  final VoidCallback? onStreakTap;

  _XpTier get _tier {
    for (final t in _tiers) {
      if (xp >= t.min && xp < t.max) return t;
    }
    return _tiers.last;
  }

  @override
  Widget build(BuildContext context) {
    final tiny = MediaQuery.sizeOf(context).height < 600;
    final tier = _tier;
    final progress = ((xp - tier.min) / (tier.max - tier.min)).clamp(0.0, 1.0);
    final nearNext = progress > 0.85;
    final almostThere = progress > 0.95;

    final glowSize = 4 + progress * 12;
    final glowOpacity = 0.08 + progress * 0.24;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tiny ? 12 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tier.emoji,
                      style: TextStyle(
                        fontSize: tiny ? 10 : 12,
                        shadows: [
                          Shadow(
                            color: tier.color.withValues(alpha: glowOpacity),
                            blurRadius: glowSize,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Lv ${tier.level} · ${tier.name}',
                      style: TextStyle(
                        fontSize: tiny ? 8 : 10,
                        fontWeight: FontWeight.w600,
                        color: xpFlash != null
                            ? tier.color
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onStreakTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: tiny ? 4 : 6,
                          vertical: tiny ? 0 : 1,
                        ),
                        decoration: BoxDecoration(
                          color: streakCount >= 30
                              ? const Color(0x26FFD700)
                              : AppColors.coral.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: streakCount >= 30
                                ? const Color(0x44FFD700)
                                : AppColors.coral.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '🔥 $streakCount',
                          style: TextStyle(
                            fontSize: tiny ? 8 : 10,
                            fontWeight: FontWeight.w700,
                            color: streakCount >= 30
                                ? const Color(0xFFFFD700)
                                : AppColors.coral,
                          ),
                        ),
                      ),
                    ),
                    if (streakMultiplier > 1) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          '${streakMultiplier.toStringAsFixed(1)}×',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyan,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$xp/${tier.max}',
                      style: TextStyle(
                        fontSize: tiny ? 8 : 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: xpFlash != null
                            ? (nearNext
                                ? const Color(0xFFFFD700)
                                : tier.colorEnd)
                            : Colors.white.withValues(alpha: 0.4),
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 4),
                        ],
                      ),
                    ),
                    if (xpFlash != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '+$xpFlash',
                        style: TextStyle(
                          fontSize: tiny ? 8 : 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                    if (progress > 0.5) ...[
                      const SizedBox(width: 6),
                      Text(
                        tier.nextEmoji,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(
                            alpha: (progress - 0.5) * 2,
                          ),
                          shadows: nearNext
                              ? [
                                  Shadow(
                                    color: tier.nextColor,
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: tiny ? 2 : 3),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: tiny ? 3 : 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white.withValues(alpha: 0.06),
                    boxShadow: progress > 0.3
                        ? [
                            BoxShadow(
                              color:
                                  tier.color.withValues(alpha: 0.07),
                              blurRadius: progress * 6,
                            ),
                          ]
                        : null,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: almostThere
                                  ? [tier.color, const Color(0xFFFFD700)]
                                  : nearNext
                                      ? [tier.color, tier.nextColor]
                                      : [
                                          tier.color.withValues(
                                            alpha:
                                                0.6 + progress * 0.4,
                                          ),
                                          tier.colorEnd,
                                        ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: tier.color
                                    .withValues(alpha: glowOpacity),
                                blurRadius: glowSize,
                              ),
                              if (almostThere)
                                const BoxShadow(
                                  color: Color(0x66FFD700),
                                  blurRadius: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (nearNext) ...[
              const SizedBox(height: 3),
              Text(
                almostThere
                    ? '✨ Almost ${tier.name}!'
                    : '${tier.max - xp} XP to ${tier.nextEmoji} ${tier.name}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color:
                      almostThere ? const Color(0xFFFFD700) : tier.nextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
