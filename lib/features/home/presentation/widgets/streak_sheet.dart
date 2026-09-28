import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';

/// Streak mini-sheet — ports the `showStreakSheet` overlay from
/// `SwipeDeckScreen`.
class StreakSheet extends StatelessWidget {
  const StreakSheet({
    super.key,
    required this.streakCount,
    required this.longestStreak,
    required this.streakMultiplier,
    required this.streakFreezes,
    required this.onClose,
  });

  final int streakCount;
  final int longestStreak;
  final double streakMultiplier;
  final int streakFreezes;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('🔥', '$streakCount days', 'Current', AppColors.coral),
      ('🏆', '$longestStreak days', 'Longest', AppColors.amber),
      ('⚡', '${streakMultiplier.toStringAsFixed(1)}×', 'Multiplier',
          AppColors.cyan),
      ('🧊', '$streakFreezes left', 'Freezes', const Color(0xFF64B5F6)),
    ];

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.7),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideUp(
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: const BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0x14FFFFFF)),
                left: BorderSide(color: Color(0x14FFFFFF)),
                right: BorderSide(color: Color(0x14FFFFFF)),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('🔥', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    '$streakCount Day Streak',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep cooking daily to increase your multiplier!',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var i = 0; i < stats.length; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: i > 0 ? 8 : 0),
                            child: ZoomIn(
                              duration:
                                  Duration(milliseconds: 200 + i * 50),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 6),
                                decoration: BoxDecoration(
                                  color: stats[i].$4.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: stats[i].$4
                                          .withValues(alpha: 0.13)),
                                ),
                                child: Column(
                                  children: [
                                    Text(stats[i].$1,
                                        style: const TextStyle(fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                      stats[i].$2,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      stats[i].$3,
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFD700),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x1FFFD700)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next: 14-Day Milestone',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '+100 bonus XP + 2× multiplier unlock',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${14 - streakCount}d',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
