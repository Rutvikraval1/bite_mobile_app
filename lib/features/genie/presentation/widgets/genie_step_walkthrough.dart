import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/genie_planner_data.dart';

/// The "Step View" cooking walkthrough — one big glass card per instruction,
/// linear next/prev navigation, progress dots and inline step timers.
class GenieStepWalkthrough extends StatelessWidget {
  const GenieStepWalkthrough({
    super.key,
    required this.flatSteps,
    required this.currentIndex,
    required this.dishStepsDone,
    required this.activeTimers,
    required this.onJumpTo,
    required this.onMarkDone,
    required this.onAdvance,
    required this.onPrev,
    required this.onToggleTimer,
    required this.onFinish,
  });

  final List<GenieFlatStep> flatSteps;
  final int currentIndex;
  final Map<int, Set<int>> dishStepsDone;
  final Map<String, ({int remaining, bool running})> activeTimers;
  final void Function(int flatIndex) onJumpTo;
  final VoidCallback onMarkDone;
  final VoidCallback onAdvance;
  final VoidCallback onPrev;
  final VoidCallback onToggleTimer;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    if (flatSteps.isEmpty) return const SizedBox.shrink();
    final idx = currentIndex.clamp(0, flatSteps.length - 1);
    final flat = flatSteps[idx];
    final dish = flat.dish;
    final step = flat.step;
    final done = dishStepsDone[dish.id]?.contains(flat.stepIndex) ?? false;
    final isLastStep = idx >= flatSteps.length - 1;
    final hasTimer = step.timed && step.seconds > 0;
    final timerKey = '${dish.id}-${flat.stepIndex}';
    final timerInfo = activeTimers[timerKey];
    final timerRunning = timerInfo?.running ?? false;
    final timerDone = hasTimer && timerInfo != null && timerInfo.remaining <= 0;
    final remaining = timerInfo?.remaining ?? step.seconds;
    final dc = dish.color;
    final isFirstEver = idx == 0 && !done;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 5,
            children: [
              for (var i = 0; i < flatSteps.length; i++)
                GestureDetector(
                  onTap: () => onJumpTo(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: i == idx ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          dishStepsDone[flatSteps[i].dish.id]?.contains(
                                flatSteps[i].stepIndex,
                              ) ??
                              false
                          ? AppColors.saveGreen
                          : i == idx
                          ? flatSteps[i].dish.color
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: dc.withValues(alpha: 0.13)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: [
                                dc.withValues(alpha: 0.13),
                                dc.withValues(alpha: 0.03),
                              ],
                            ),
                            border: Border.all(
                              color: dc.withValues(alpha: 0.27),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            dish.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dish.name.toUpperCase(),
                                style: TextStyle(
                                  color: dc,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Step ${flat.stepIndex + 1} of ${dish.steps.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${idx + 1}/${flatSteps.length}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: done
                            ? const Color(0x0F4CAF50)
                            : isFirstEver
                            ? const Color(0x0FFFD700)
                            : AppColors.cyan.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: done
                              ? const Color(0x334CAF50)
                              : isFirstEver
                              ? const Color(0xA6FFD700)
                              : AppColors.cyan.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: done
                          ? const Column(
                              children: [
                                Text('✅', style: TextStyle(fontSize: 24)),
                                SizedBox(height: 4),
                                Text(
                                  'Step complete!',
                                  style: TextStyle(
                                    color: AppColors.saveGreen,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isFirstEver) ...[
                                  const Row(
                                    children: [
                                      Text(
                                        '👇',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Let's begin! Complete your first step",
                                        style: TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                Text(
                                  isFirstEver ? 'FIRST STEP' : 'CURRENT STEP',
                                  style: TextStyle(
                                    color: isFirstEver
                                        ? const Color(0xFFFFD700)
                                        : AppColors.cyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  step.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: OutlinedButton.icon(
                                    onPressed: onMarkDone,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: AppColors.cyan
                                          .withValues(alpha: 0.13),
                                      side: BorderSide(
                                        color: AppColors.cyan.withValues(
                                          alpha: 0.27,
                                        ),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: AppColors.cyan,
                                    ),
                                    label: const Text(
                                      'Mark Done',
                                      style: TextStyle(
                                        color: AppColors.cyan,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (hasTimer) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: timerDone
                              ? const Color(0x0F4CAF50)
                              : timerRunning
                              ? AppColors.amber.withValues(alpha: 0.03)
                              : Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: timerDone
                                ? const Color(0x4D4CAF50)
                                : timerRunning
                                ? AppColors.amber.withValues(alpha: 0.27)
                                : Colors.white.withValues(alpha: 0.06),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              timerDone
                                  ? '00:00'
                                  : '${(remaining ~/ 60).toString().padLeft(2, '0')}:'
                                        '${(remaining % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w200,
                                fontFamily: 'monospace',
                                letterSpacing: 4,
                                color: timerDone
                                    ? AppColors.saveGreen
                                    : timerRunning
                                    ? AppColors.amber
                                    : Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            if (!timerDone) ...[
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: onToggleTimer,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    gradient: timerRunning
                                        ? null
                                        : const LinearGradient(
                                            colors: [
                                              AppColors.amber,
                                              AppColors.coral,
                                            ],
                                          ),
                                    color: timerRunning
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : null,
                                  ),
                                  child: Text(
                                    timerRunning
                                        ? 'Pause'
                                        : timerInfo != null
                                        ? 'Resume'
                                        : 'Start',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (idx > 0)
                GestureDetector(
                  onTap: onPrev,
                  child: Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              if (done && !isLastStep)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onAdvance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dc,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: Text(
                        flat.isLastInDish &&
                                flat.timelineIndex + 1 < _timelineDishCount()
                            ? 'Next: ${_nextDishLabel()} →'
                            : 'Next Step →',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              if (isLastStep && done)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: const Text(
                        "🔥 I'm Done — Rate & Share!",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  int _timelineDishCount() =>
      flatSteps.map((f) => f.timelineIndex).toSet().length;

  String _nextDishLabel() {
    if (flatSteps.isEmpty) return 'Next Dish';
    final idx = currentIndex.clamp(0, flatSteps.length - 1);
    final nextTimelineIndex = flatSteps[idx].timelineIndex + 1;
    final match = flatSteps.where((f) => f.timelineIndex == nextTimelineIndex);
    if (match.isEmpty) return 'Next Dish';
    return '${match.first.dish.emoji} ${match.first.dish.name}';
  }
}
