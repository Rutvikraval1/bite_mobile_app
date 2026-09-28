import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/badge_catalog.dart';
import '../../../../core/constants/tier_definitions.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/glass.dart';

/// Full-page "expanded XP bar" — level, tier progress, badge progress,
/// streak and the tier ladder. Ports `CookingLevelScreen` from
/// `screens-misc.jsx`, satisfying `AppScreen.cookingLevel`.
///
/// The prototype's static "Points Breakdown" (hardcoded demo numbers) is
/// replaced with a real badge-progress section driven by
/// [AppStateCubit.state.userBadges] + [BadgeCatalog], since this app has no
/// per-category point tracking — everything else here reads live state.
class CookingLevelScreen extends StatelessWidget {
  const CookingLevelScreen({super.key});

  static const List<String> _tierTaglines = [
    "Just getting started — welcome!",
    'Building your kitchen basics',
    "You're mastering the basics!",
    'Leveling up your knife skills',
    'Cooking like a pro',
    'Culinary mastery, unlocked',
    'You are a b🌶te Legend',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppStateCubit, AppState>(
      builder: (context, state) {
        final tiers = TierDefinitions.all;
        final tier = TierDefinitions.tierFor(state.xp);
        final tierIndex = tiers.indexOf(tier);
        final isMaxTier = tierIndex == tiers.length - 1;
        final nextTier = isMaxTier ? null : tiers[tierIndex + 1];
        final progress = TierDefinitions.progressInTier(state.xp);
        final earned = state.userBadges.toSet();
        final streakLit = state.streakCount.clamp(0, 14);

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.bgDark,
          child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.read<FlowCubit>().goBack(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back_ios_new,
                              size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 14,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.coral, AppColors.amber],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.coral.withValues(alpha: 0.3),
                                blurRadius: 32,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(tier.emoji,
                                  style: const TextStyle(fontSize: 36)),
                              Text(
                                'LVL ${tier.level}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tier.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _tierTaglines[tierIndex.clamp(
                              0, _tierTaglines.length - 1)],
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Progress to next tier ──
                        Glass(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isMaxTier
                                        ? '${state.xp} XP — Max Level'
                                        : '${state.xp - tier.min}/${tier.max - tier.min} pts to Level ${tier.level + 1}',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  if (nextTier != null)
                                    Text(
                                      nextTier.name,
                                      style: const TextStyle(
                                        color: AppColors.coral,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 8,
                                  color: Colors.white.withValues(alpha: 0.08),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: isMaxTier ? 1 : progress,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        borderRadius:
                                            BorderRadius.all(Radius.circular(4)),
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.coral,
                                            AppColors.amber,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Badge progress ──
                        Glass(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Badges',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  Text(
                                    '${earned.length}/${BadgeCatalog.all.length} earned',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (var i = 0;
                                      i < BadgeCatalog.all.length;
                                      i++)
                                    PopIn(
                                      duration:
                                          const Duration(milliseconds: 260),
                                      begin: 0.4 + (i * 0.03),
                                      child: _badgeChip(
                                        emoji: BadgeCatalog.all[i].emoji,
                                        name: BadgeCatalog.all[i].name,
                                        color: BadgeCatalog.all[i].color,
                                        earned: earned
                                            .contains(BadgeCatalog.all[i].id),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Streak ──
                        Glass(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 20)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${state.streakCount} day streak',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List.generate(14, (i) {
                                  final lit = i < streakLit;
                                  return Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: lit
                                          ? AppColors.amber
                                          : Colors.white.withValues(alpha: 0.08),
                                      border: lit
                                          ? null
                                          : Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.1)),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Virtual kitchen teaser (static, matches prototype) ──
                        ZoomIn(
                          duration: const Duration(milliseconds: 400),
                          child: Glass(
                            padding: const EdgeInsets.all(16),
                            borderColor: AppColors.amber.withValues(alpha: 0.13),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Text('🍴',
                                        style: TextStyle(fontSize: 24)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'My Kitchen — Coming Soon',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          Text(
                                            'Earn items for your virtual '
                                            'kitchen as you level up',
                                            style: TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 11,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.amber
                                            .withValues(alpha: 0.08),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        border: Border.all(
                                          color: AppColors.amber
                                              .withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: const Text(
                                        '✨ New',
                                        style: TextStyle(
                                          color: AppColors.amber,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    for (final item in const [
                                      ('🔪 100pts', true),
                                      ('🍳 250pts', true),
                                      ('🎍 500pts', false),
                                      ('☕ 2000pts', false),
                                    ])
                                      Expanded(
                                        child: Container(
                                          margin:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 2),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 4),
                                          decoration: BoxDecoration(
                                            color: item.$2
                                                ? const Color(0x144CAF50)
                                                : Colors.white
                                                    .withValues(alpha: 0.03),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: item.$2
                                                  ? const Color(0x264CAF50)
                                                  : Colors.white
                                                      .withValues(alpha: 0.04),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            item.$1,
                                            style: TextStyle(
                                              color: item.$2
                                                  ? const Color(0xFF4CAF50)
                                                  : AppColors.muted,
                                              fontSize: 10,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Tier ladder ──
                        SizedBox(
                          height: 90,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: tiers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final t = tiers[i];
                              final unlocked = i <= tierIndex;
                              final isCurrent = i == tierIndex;
                              return Opacity(
                                opacity: unlocked ? 1 : 0.35,
                                child: SizedBox(
                                  width: 72,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          gradient: isCurrent
                                              ? const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    AppColors.coral,
                                                    AppColors.amber,
                                                  ],
                                                )
                                              : null,
                                          color: isCurrent
                                              ? null
                                              : Colors.white
                                                  .withValues(alpha: 0.06),
                                          border: Border.all(
                                            color: isCurrent
                                                ? AppColors.coral
                                                : Colors.white
                                                    .withValues(alpha: 0.1),
                                            width: isCurrent ? 2 : 1,
                                          ),
                                          boxShadow: isCurrent
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.coral
                                                        .withValues(
                                                            alpha: 0.3),
                                                    blurRadius: 16,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(t.emoji,
                                            style:
                                                const TextStyle(fontSize: 22)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        t.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCurrent
                                              ? Colors.white
                                              : AppColors.muted,
                                          fontSize: 10,
                                          fontWeight: isCurrent
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
        );
      },
    );
  }

  static Widget _badgeChip({
    required String emoji,
    required String name,
    required Color color,
    required bool earned,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: earned ? color.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: earned ? color.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: earned ? 1 : 0.35,
            child: Text(emoji, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 5),
          Text(
            name,
            style: TextStyle(
              color: earned ? Colors.white : AppColors.muted,
              fontSize: 10,
              fontWeight: earned ? FontWeight.w600 : FontWeight.w400,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
