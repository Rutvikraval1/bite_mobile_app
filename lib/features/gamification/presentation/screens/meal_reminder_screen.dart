import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';

/// "Tonight's picks" meal-reminder bottom sheet — ports `MealReminderScreen`
/// from `screens-misc.jsx`, satisfying `AppScreen.mealReminder`. Triggered
/// from the top bar's meal-reminder icon in `SwipeDeckScreen`.
///
/// There is no notification-scheduling backend (no local-notifications
/// plugin in `pubspec.yaml`), so "Remind Later" only fakes a confirmation
/// toast — no OS notification is actually scheduled.
class MealReminderScreen extends StatelessWidget {
  const MealReminderScreen({super.key});

  static const List<
      ({
        String title,
        String time,
        String heat,
        String emoji,
        Color color,
        String reason,
        bool isPlace,
      })> _recommendations = [
    (
      title: 'Bibimbap Bowl',
      time: '25 min',
      heat: '🌶',
      emoji: '🍲',
      color: AppColors.coral,
      reason: 'You liked 4 Korean recipes',
      isPlace: false,
    ),
    (
      title: 'One-Pan Lemon Pasta',
      time: '20 min',
      heat: '',
      emoji: '🍝',
      color: AppColors.amber,
      reason: 'Under 30 min + Italian',
      isPlace: false,
    ),
    (
      title: 'Sakura Sushi',
      time: '📍 0.8 mi',
      heat: '⭐ 4.6',
      emoji: '🍣',
      color: AppColors.placesPurple,
      reason: 'You saved 3 Japanese places',
      isPlace: true,
    ),
  ];

  static const List<({String label, AppScreen dest})> _quickActions = [
    (label: '🧞 Ask Genie', dest: AppScreen.genieChat),
    (label: '🎲 Surprise Me', dest: AppScreen.swipeDeck),
    (label: '⏰ Remind Later', dest: AppScreen.swipeDeck),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: const ModalBarrier(
            color: Color(0xB3000000),
            dismissible: false,
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * 0.70,
            decoration: const BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: () => context.read<FlowCubit>().goBack(),
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
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
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Tonight's Picks 🌙",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Based on your taste + what's quick",
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 13,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    context.read<FlowCubit>().goBack(),
                                child: const Icon(Icons.close,
                                    color: AppColors.muted, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 206,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              itemCount: _recommendations.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, i) =>
                                  _RecommendationCard(item: _recommendations[i]),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              for (var i = 0; i < _quickActions.length; i++)
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                        left: i > 0 ? 8 : 0),
                                    child: _quickActionButton(
                                        context, _quickActions[i]),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Customize meal reminders in Settings → '
                            'Notifications',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0x33FFFFFF),
                              fontSize: 11,
                              fontFamily: 'Inter',
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
      ],
      ),
    );
  }

  Widget _quickActionButton(
      BuildContext context, ({String label, AppScreen dest}) action) {
    return GestureDetector(
      onTap: () {
        if (action.label.contains('Remind Later')) {
          ToastService.instance
              .show("⏰ We'll remind you again in 30 minutes");
        }
        context.read<FlowCubit>().setScreen(action.dest);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        alignment: Alignment.center,
        child: Text(
          action.label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final ({
    String title,
    String time,
    String heat,
    String emoji,
    Color color,
    String reason,
    bool isPlace,
  }) item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<FlowCubit>().setScreen(
          item.isPlace ? AppScreen.placeDetail : AppScreen.recipeDetail),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.glass,
          border: Border.all(color: AppColors.glassBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withValues(alpha: 0.2),
                    item.color.withValues(alpha: 0.07),
                  ],
                ),
              ),
              child: Text(item.emoji, style: const TextStyle(fontSize: 36)),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.heat.isEmpty
                        ? item.time
                        : '${item.time} · ${item.heat}',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.42),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
