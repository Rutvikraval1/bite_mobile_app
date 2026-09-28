import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/premium_gate_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/glass.dart';

/// One quick-action tile in the Genie hub grid.
class _GenieAction {
  const _GenieAction({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.dest,
    this.premium = false,
    this.gateTitle,
    this.gateDesc,
  });

  final String icon;
  final String title;
  final String desc;
  final Color color;
  final AppScreen dest;
  final bool premium;
  final String? gateTitle;
  final String? gateDesc;
}

/// The Genie hub — a bottom-anchored modal sheet with the AI orb, Crave
/// Radar CTA, a 2×2 quick-action grid and the Meal Timing Planner banner.
/// Ports `GenieScreen` from `screens-genie.jsx`.
class GenieScreen extends StatelessWidget {
  const GenieScreen({super.key});

  List<_GenieAction> _actionsFor(DeckTab tab) {
    switch (tab) {
      case DeckTab.places:
        return const [
          _GenieAction(
            icon: '📍',
            title: 'Nearby',
            desc: 'Find restaurants around you',
            color: AppColors.placesPurple,
            dest: AppScreen.genieChat,
          ),
          _GenieAction(
            icon: '🎯',
            title: 'Filter',
            desc: 'Cuisine, price, vibe & distance',
            color: AppColors.coral,
            dest: AppScreen.genieFilter,
            premium: true,
            gateTitle: 'Smart Filters',
            gateDesc:
                'Unlock precision sliders for cuisine, price range, '
                'vibe, distance, and dietary filters.',
          ),
          _GenieAction(
            icon: '📸',
            title: 'Scan',
            desc: 'Snap a menu or storefront',
            color: AppColors.cyan,
            dest: AppScreen.genieScan,
          ),
          _GenieAction(
            icon: '🗓',
            title: 'Reserve',
            desc: 'Find open tables tonight',
            color: AppColors.saveGreen,
            dest: AppScreen.placeDetail,
            premium: true,
            gateTitle: 'Reservations',
            gateDesc:
                'Search availability across OpenTable, Resy & Google '
                '— book tables directly from b🌶te.',
          ),
        ];
      case DeckTab.drinks:
        return const [
          _GenieAction(
            icon: '✨',
            title: 'Suggest',
            desc: 'What should I mix?',
            color: AppColors.amber,
            dest: AppScreen.genieChat,
          ),
          _GenieAction(
            icon: '🎯',
            title: 'Filter',
            desc: 'Spirit, mood, occasion & strength',
            color: AppColors.drinksBlue,
            dest: AppScreen.genieFilter,
            premium: true,
            gateTitle: 'Smart Filters',
            gateDesc:
                'Filter by spirit type, strength, occasion, and '
                'flavor profile.',
          ),
          _GenieAction(
            icon: '📸',
            title: 'Scan',
            desc: 'Snap a bottle or cocktail menu',
            color: AppColors.cyan,
            dest: AppScreen.genieScan,
          ),
          _GenieAction(
            icon: '🍹',
            title: 'Pairings',
            desc: 'Match drinks to your meal',
            color: AppColors.saveGreen,
            dest: AppScreen.genieMeals,
            premium: true,
            gateTitle: 'Drink Pairings',
            gateDesc:
                'AI-powered drink pairing for any dish — wine, '
                'cocktails, mocktails, or beer.',
          ),
        ];
      case DeckTab.food:
        return const [
          _GenieAction(
            icon: '✨',
            title: 'Suggest',
            desc: 'What should I cook?',
            color: AppColors.amber,
            dest: AppScreen.genieChat,
          ),
          _GenieAction(
            icon: '🎯',
            title: 'Filter',
            desc: 'Narrow down by nutrition & vibe',
            color: AppColors.coral,
            dest: AppScreen.genieFilter,
            premium: true,
            gateTitle: 'Smart Filters',
            gateDesc:
                'Unlock precision sliders for calories, macros, cook '
                'time, spice level, and dietary filters.',
          ),
          _GenieAction(
            icon: '📸',
            title: 'Scan',
            desc: 'Snap ingredients or a recipe',
            color: AppColors.cyan,
            dest: AppScreen.genieScan,
          ),
          _GenieAction(
            icon: '🍽',
            title: 'Meals',
            desc: 'Full meal pairings — entree, side & drink',
            color: AppColors.saveGreen,
            dest: AppScreen.genieMeals,
            premium: true,
            gateTitle: 'Meal Builder',
            gateDesc:
                'Build complete meals with AI-curated pairings and '
                'synchronized cook timers.',
          ),
        ];
    }
  }

  void _openAction(BuildContext context, _GenieAction a, bool isPremium) {
    if (a.premium && !isPremium) {
      PremiumGateService.instance.show(
        a.gateTitle ?? a.title,
        'premium',
        a.gateDesc ?? 'Upgrade to Premium to unlock this feature.',
      );
      return;
    }
    context.read<FlowCubit>().setScreen(a.dest);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppStateCubit, AppState>(
      buildWhen: (prev, curr) =>
          prev.subTab != curr.subTab || prev.isPremium != curr.isPremium,
      builder: (context, state) {
        final actions = _actionsFor(state.subTab);
        final flow = context.read<FlowCubit>();

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: flow.goBack,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.black.withValues(alpha: 0.7)),
                ),
              ),
              SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: flow.goBack,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () {},
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    120,
                                  ),
                                  child: _GenieSheetContent(
                                    actions: actions,
                                    isPremium: state.isPremium,
                                    onOpen: (a) => _openAction(
                                      context,
                                      a,
                                      state.isPremium,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GenieSheetContent extends StatelessWidget {
  const _GenieSheetContent({
    required this.actions,
    required this.isPremium,
    required this.onOpen,
  });

  final List<_GenieAction> actions;
  final bool isPremium;
  final ValueChanged<_GenieAction> onOpen;

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: flow.goBack,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
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
            ),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Pulse(
                    amount: 0.06,
                    child: GestureDetector(
                      onTap: () => flow.setScreen(AppScreen.genieChat),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [AppColors.amber, AppColors.coral],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withValues(alpha: 0.4),
                              blurRadius: 32,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🧞 Food Genie',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your AI cooking & discovery assistant',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ZoomIn(
              child: _CraveRadarCta(
                onTap: () {
                  ToastService.instance.show(
                    '🔍 Crave Radar — tell me what you’re craving!',
                  );
                  flow.goBack();
                },
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                for (var i = 0; i < actions.length; i++)
                  ZoomIn(
                    duration: Duration(milliseconds: 240 + i * 60),
                    child: _ActionTile(
                      action: actions[i],
                      isPremium: isPremium,
                      onTap: () => onOpen(actions[i]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Glass(
              borderRadius: 20,
              padding: const EdgeInsets.all(16),
              borderColor: isPremium
                  ? const Color(0x334CAF50)
                  : AppColors.amber.withValues(alpha: 0.13),
              onTap: () {
                if (isPremium) {
                  flow.setScreen(AppScreen.genieMeals);
                } else {
                  PremiumGateService.instance.show(
                    'Meal Timing Planner',
                    'premium',
                    'Time multiple dishes to land on the table together — '
                        'Genie calculates start times and guides each step.',
                  );
                }
              },
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isPremium ? const Color(0x1F4CAF50) : null,
                      gradient: isPremium
                          ? null
                          : LinearGradient(
                              colors: [
                                AppColors.amber.withValues(alpha: 0.2),
                                AppColors.coral.withValues(alpha: 0.13),
                              ],
                            ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('⏱', style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Meal Timing Planner',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!isPremium) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: AppColors.amber.withValues(
                                      alpha: 0.33,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'PREMIUM',
                                  style: TextStyle(
                                    color: AppColors.amber,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Time your dishes so everything's hot & ready at "
                          'once',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: isPremium ? AppColors.saveGreen : AppColors.amber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isPremium)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x0F4CAF50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x264CAF50)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('✨', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 8),
                    Text(
                      'Unlimited Genie — Premium active',
                      style: TextStyle(
                        color: AppColors.saveGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Container(
                            margin: const EdgeInsets.only(right: 3),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < 2
                                  ? AppColors.amber
                                  : Colors.white.withValues(alpha: 0.12),
                              boxShadow: i < 2
                                  ? [
                                      BoxShadow(
                                        color: AppColors.amber.withValues(
                                          alpha: 0.27,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        '2 of 3 free requests today',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => flow.setScreen(AppScreen.premium),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.coral.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.coral.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Text(
                          'Unlimited →',
                          style: TextStyle(
                            color: AppColors.coral,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            const Text(
              'Genie learns your taste with every swipe ✨',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0x40FFFFFF), fontSize: 11),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => flow.setScreen(AppScreen.genieChat),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  color: Colors.white.withValues(alpha: 0.04),
                ),
                child: const Row(
                  children: [
                    Text('🧞', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ask Genie anything...',
                        style: TextStyle(
                          color: Color(0x73FFFFFF),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(Icons.send, size: 16, color: AppColors.amber),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: -4,
          right: 0,
          child: GestureDetector(
            onTap: flow.goBack,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _CraveRadarCta extends StatelessWidget {
  const _CraveRadarCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cyan.withValues(alpha: 0.13),
              AppColors.placesPurple.withValues(alpha: 0.13),
            ],
          ),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.27)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.13),
              blurRadius: 28,
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Container(
                      width: 24.0 + i * 14,
                      height: 24.0 + i * 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.cyan.withValues(
                            alpha: [0.4, 0.27, 0.13][i],
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyan.withValues(alpha: 0.2),
                          AppColors.placesPurple.withValues(alpha: 0.2),
                        ],
                      ),
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.search,
                      color: AppColors.cyan,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Crave Radar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.33),
                          ),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Tell me what you're craving — I'll find who serves it "
                    'best nearby',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.cyan, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.isPremium,
    required this.onTap,
  });

  final _GenieAction action;
  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 20,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(action.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 8),
              Text(
                action.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                action.desc,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          if (action.premium)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPremium
                      ? const Color(0x264CAF50)
                      : AppColors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isPremium
                        ? const Color(0x594CAF50)
                        : AppColors.amber.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  isPremium ? '✓' : 'PREMIUM',
                  style: TextStyle(
                    color: isPremium ? AppColors.saveGreen : AppColors.amber,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
