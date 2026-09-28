import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/genie_planner_data.dart';

/// One dish's row in the cook-timeline — status pill, progress bar and,
/// when expanded, its full step checklist with per-step timers.
class GenieDishTimelineCard extends StatelessWidget {
  const GenieDishTimelineCard({
    super.key,
    required this.entry,
    required this.status,
    required this.started,
    required this.expanded,
    required this.flashed,
    required this.doneSteps,
    required this.timerStates,
    this.countdownSeconds,
    this.quickNextLabel,
    required this.onToggleExpand,
    required this.onToggleStep,
    required this.onToggleTimer,
    this.onQuickNext,
  });

  final GenieTimelineEntry entry;
  final GenieDishStatus status;
  final bool started;
  final bool expanded;
  final bool flashed;
  final Set<int> doneSteps;

  /// Timer state per step index, for steps that have an active/paused timer.
  final Map<int, ({int remaining, bool running})> timerStates;
  final int? countdownSeconds;

  /// Label for the "quick next" pill in the expanded steps header, or null
  /// to hide it (e.g. this dish is fully checked with no next dish).
  final String? quickNextLabel;

  final VoidCallback onToggleExpand;
  final void Function(int stepIndex) onToggleStep;
  final void Function(int stepIndex) onToggleTimer;
  final VoidCallback? onQuickNext;

  Color get _statusColor => switch (status) {
    GenieDishStatus.done => AppColors.saveGreen,
    GenieDishStatus.cooking => AppColors.coral,
    GenieDishStatus.prepping => AppColors.amber,
    GenieDishStatus.waiting => AppColors.muted,
  };

  String get _statusLabel => switch (status) {
    GenieDishStatus.done => '✓ Done',
    GenieDishStatus.cooking => '🔥 Cooking',
    GenieDishStatus.prepping => '🔪 Prep',
    GenieDishStatus.waiting => 'Waiting',
  };

  int get _stepProgressPct => entry.dish.steps.isEmpty
      ? 0
      : ((doneSteps.length / entry.dish.steps.length) * 100).round();

  @override
  Widget build(BuildContext context) {
    final dish = entry.dish;
    final borderColor = flashed
        ? AppColors.cyan.withValues(alpha: 0.53)
        : (status == GenieDishStatus.cooking ||
              status == GenieDishStatus.prepping)
        ? dish.color.withValues(alpha: 0.27)
        : expanded
        ? AppColors.cyan.withValues(alpha: 0.2)
        : AppColors.glassBorder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Glass(
        borderRadius: 14,
        padding: const EdgeInsets.all(14),
        borderColor: borderColor,
        borderWidth: flashed ? 2 : 1,
        onTap: started ? onToggleExpand : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    started
                        ? entry.startClock
                        : entry.startOffset == 0
                        ? 'START'
                        : '+${entry.startOffset}m',
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(dish.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [
                          dish.type,
                          if (started && _stepProgressPct > 0)
                            '$_stepProgressPct% steps',
                          if (started &&
                              (status == GenieDishStatus.prepping ||
                                  status == GenieDishStatus.cooking) &&
                              countdownSeconds != null)
                            '⏱ ${countdownSeconds! ~/ 60}:${(countdownSeconds! % 60).toString().padLeft(2, '0')}',
                          if (started && status == GenieDishStatus.done)
                            '✓ Complete',
                        ].join(' · '),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (_stepProgressPct / 100).clamp(0.02, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(
                  _stepProgressPct >= 100 ? AppColors.saveGreen : dish.color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  [
                    if (dish.prepMin > 0) '🔪 ${dish.prepMin}m',
                    if (dish.cookMin > 0) '🔥 ${dish.cookMin}m',
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                Text(
                  '${dish.totalMin}m',
                  style: TextStyle(
                    color: dish.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (expanded && started) ...[
              const Divider(height: 24, color: AppColors.glassBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STEPS',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (quickNextLabel != null)
                    GestureDetector(
                      onTap: onQuickNext,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: AppColors.cyan.withValues(alpha: 0.33),
                          ),
                        ),
                        child: Text(
                          quickNextLabel!,
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              for (var si = 0; si < dish.steps.length; si++)
                _StepRow(
                  step: dish.steps[si],
                  done: doneSteps.contains(si),
                  timer: timerStates[si],
                  onTap: () => onToggleStep(si),
                  onToggleTimer: () => onToggleTimer(si),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.done,
    required this.timer,
    required this.onTap,
    required this.onToggleTimer,
  });

  final GenieStep step;
  final bool done;
  final ({int remaining, bool running})? timer;
  final VoidCallback onTap;
  final VoidCallback onToggleTimer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: done ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: done
              ? const Color(0x0A4CAF50)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: done
                ? const Color(0x1F4CAF50)
                : Colors.white.withValues(alpha: 0.03),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 1),
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? AppColors.saveGreen
                    : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: done
                      ? AppColors.saveGreen
                      : Colors.white.withValues(alpha: 0.12),
                  width: 2,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.text,
                    style: TextStyle(
                      color: done
                          ? Colors.white.withValues(alpha: 0.35)
                          : Colors.white,
                      fontSize: 12,
                      height: 1.4,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (step.timed && !done)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _TimerChip(
                        step: step,
                        timer: timer,
                        onTap: onToggleTimer,
                        onDone: onTap,
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

class _TimerChip extends StatelessWidget {
  const _TimerChip({
    required this.step,
    required this.timer,
    required this.onTap,
    required this.onDone,
  });

  final GenieStep step;
  final ({int remaining, bool running})? timer;
  final VoidCallback onTap;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final remaining = timer?.remaining ?? step.seconds;
    final running = timer?.running ?? false;
    final isDone = timer != null && timer!.remaining <= 0;
    final mins = remaining ~/ 60;
    final secs = remaining % 60;
    final color = isDone
        ? AppColors.saveGreen
        : running
        ? AppColors.cyan
        : AppColors.muted;

    return GestureDetector(
      onTap: isDone ? onDone : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDone
              ? const Color(0x1F4CAF50)
              : running
              ? AppColors.cyan.withValues(alpha: 0.07)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone
                ? const Color(0x4D4CAF50)
                : running
                ? AppColors.cyan.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDone
                  ? '✅'
                  : running
                  ? '⏸'
                  : '▶',
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(width: 5),
            Text(
              isDone ? 'Done!' : '$mins:${secs.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
