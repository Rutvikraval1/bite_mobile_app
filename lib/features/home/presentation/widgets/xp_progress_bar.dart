import 'package:flutter/material.dart';

import '../../../../core/constants/tier_definitions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/loops.dart';

/// Tier entry for the XP bar: a level from [TierDefinitions] (the app-wide
/// ladder) plus the bar's gradient colours and the next level's details.
class _XpTier {
  const _XpTier(this.min, this.max, this.level, this.name, this.emoji,
      this.color, this.colorEnd, this.nextColor, this.nextEmoji, this.nextName);

  final int min;
  final int max;
  final int level;
  final String name;
  final String emoji;
  final Color color;
  final Color colorEnd;
  final Color nextColor;
  final String nextEmoji;

  /// Null at the top level.
  final String? nextName;
}

/// Gradient end colour per level (the start colour is the tier's own);
/// levels added in the database without one use a lighter tier colour.
const Map<int, Color> _colorEnd = {
  1: Color(0xFF42A5F5),
  2: Color(0xFF66BB6A),
  3: Color(0xFFFF8A65),
  4: Color(0xFFAB47BC),
  5: Color(0xFFFFD54F),
  6: Color(0xFFBA68C8),
  7: Color(0xFFFFE082),
};

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
    this.chestReady,
    this.onChestTap,
  });

  final int xp;
  final int streakCount;
  final double streakMultiplier;
  final int? xpFlash;
  final VoidCallback? onTap;
  final VoidCallback? onStreakTap;

  /// Daily chest button: true = ready to open, false = opened today,
  /// null = hidden (signed out).
  final bool? chestReady;
  final VoidCallback? onChestTap;

  _XpTier get _tier {
    final all = TierDefinitions.all;
    final t = TierDefinitions.tierFor(xp);
    final i = all.indexOf(t);
    final next = i + 1 < all.length ? all[i + 1] : null;
    return _XpTier(t.min, t.max, t.level, t.name, t.emoji, t.color,
        _colorEnd[t.level] ?? Color.lerp(t.color, Colors.white, 0.25)!, next?.color ?? t.color,
        next?.emoji ?? t.emoji, next?.name);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the level ladder arrives from the database.
    return ValueListenableBuilder<int>(
      valueListenable: TierDefinitions.version,
      builder: (context, _, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final tiny = MediaQuery.sizeOf(context).height < 600;
    final tier = _tier;
    final progress = ((xp - tier.min) / (tier.max - tier.min)).clamp(0.0, 1.0);
    final isTop = tier.nextName == null;
    final nearNext = !isTop && progress > 0.85;
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
                    if (chestReady != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onChestTap,
                        child: _ChestPill(ready: chestReady!, tiny: tiny),
                      ),
                    ],
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
                      isTop ? '$xp XP' : '$xp/${tier.max}',
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
                    ? '✨ Almost ${tier.nextName}!'
                    : '${tier.max - xp} XP to ${tier.nextEmoji} ${tier.nextName}',
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

/// Daily chest shortcut next to the streak pill: pulses when today's chest
/// is ready, dims once it's been opened.
class _ChestPill extends StatelessWidget {
  const _ChestPill({required this.ready, required this.tiny});

  final bool ready;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: tiny ? 4 : 6, vertical: tiny ? 0 : 1),
      decoration: BoxDecoration(
        color: ready ? AppColors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: ready ? AppColors.amber.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        ready ? '🎁 Open' : '📦 ✓',
        style: TextStyle(
          fontSize: tiny ? 8 : 10,
          fontWeight: FontWeight.w700,
          color: ready ? AppColors.amber : Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
    return ready ? Pulse(amount: 0.06, duration: const Duration(milliseconds: 1400), child: pill) : pill;
  }
}
