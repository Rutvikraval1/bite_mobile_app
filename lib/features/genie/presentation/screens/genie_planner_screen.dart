import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/genie_planner_data.dart';
import '../widgets/genie_dish_timeline_card.dart';
import '../widgets/genie_ingredients_sheet.dart';
import '../widgets/genie_step_walkthrough.dart';

/// Genie's synchronized cook-timing session — a demo 4-dish "Korean Night"
/// meal where every dish is paced to finish together at the chosen serve
/// time. Ports `GeniePlannerScreen` from `screens-genie.jsx`.
///
/// There is no real timing/AI backend, so the dish list, steps and timings
/// are canned (see [GeniePlannerData]) — exactly mirroring the prototype's
/// hardcoded demo. The pace clock and per-step timers still tick for real,
/// scaled by the on-screen demo-speed multiplier, to preserve the "live
/// cooking session" feel.
class GeniePlannerScreen extends StatefulWidget {
  const GeniePlannerScreen({super.key});

  @override
  State<GeniePlannerScreen> createState() => _GeniePlannerScreenState();
}

typedef _StepCursor = ({int timelineIndex, int step});
typedef _TimerState = ({int remaining, bool running});

class _GeniePlannerScreenState extends State<GeniePlannerScreen> {
  final List<GenieDish> _dishes = GeniePlannerData.demoDishes;

  String _serveTime = '7:00 PM';
  bool _started = false;
  bool _completed = false;
  int _elapsedMin = 0;
  int _demoSpeed = 3;
  String? _headsUp;
  int? _expandedDishId;
  int? _flashDishId;
  final Map<int, Set<int>> _dishStepsDone = {};
  bool _showIngredients = false;
  final Map<String, bool> _checkedIngs = {};
  final Map<String, _TimerState> _activeTimers = {};
  final Map<int, int> _dishCountdowns = {};
  ({String dishName, String emoji})? _celebration;
  GenieMealViewMode _viewMode = GenieMealViewMode.timeline;
  _StepCursor _stepCursor = (timelineIndex: 0, step: 0);

  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Cooking session control ──

  void _startCooking() {
    setState(() => _started = true);
    _restartTicker();
    final timeline = GeniePlannerData.buildTimeline(_dishes, _serveTime);
    for (final e in timeline) {
      final done = _dishStepsDone[e.dish.id];
      if (done == null || done.length < e.dish.steps.length) {
        _expandAndFlash(e.dish.id);
        break;
      }
    }
  }

  void _restartTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      Duration(milliseconds: (2500 / _demoSpeed).round()),
      (_) => _tick(),
    );
  }

  void _cycleSpeed() {
    setState(() => _demoSpeed = _demoSpeed >= 5 ? 1 : _demoSpeed + 1);
    if (_started && !_completed) _restartTicker();
  }

  void _resetCooking() {
    _ticker?.cancel();
    setState(() {
      _started = false;
      _elapsedMin = 0;
    });
  }

  GenieDishStatus _statusFor(GenieTimelineEntry e) {
    if (!_started) return GenieDishStatus.waiting;
    if (_elapsedMin < e.startOffset) return GenieDishStatus.waiting;
    if (_elapsedMin < e.startOffset + e.dish.prepMin) {
      return GenieDishStatus.prepping;
    }
    if (_elapsedMin < e.startOffset + e.dish.totalMin) {
      return e.dish.cookMin > 0
          ? GenieDishStatus.cooking
          : GenieDishStatus.done;
    }
    return GenieDishStatus.done;
  }

  void _tick() {
    if (!_started || _completed) return;
    final timeline = GeniePlannerData.buildTimeline(_dishes, _serveTime);
    final maxTotal = GeniePlannerData.maxTotalMinutes(_dishes);
    String? headsUpMsg;
    var timerFinished = false;

    setState(() {
      final next = _elapsedMin + 1;
      if (next >= maxTotal) {
        _elapsedMin = maxTotal;
        if (!_completed) {
          _completed = true;
          ToastService.instance.show(
            "🎉 Pace time complete! Finish up and tap I'm Done when ready.",
          );
        }
      } else {
        _elapsedMin = next;
        for (final e in timeline) {
          if (e.startOffset == next + 2) {
            headsUpMsg =
                '🔔 Get ready! ${e.dish.emoji} ${e.dish.name} starts in 2 min';
          }
        }
        if (next > 0) {
          for (final e in timeline) {
            if (e.startOffset == next) {
              headsUpMsg = '⚡ Time to start ${e.dish.emoji} ${e.dish.name}!';
            }
          }
        }
        for (final e in timeline) {
          final status = _statusFor(e);
          if ((status == GenieDishStatus.prepping ||
                  status == GenieDishStatus.cooking) &&
              !_dishCountdowns.containsKey(e.dish.id)) {
            _dishCountdowns[e.dish.id] = e.dish.totalMin * 60;
          }
        }
      }

      _dishCountdowns.updateAll((id, sec) => sec > 0 ? sec - 1 : sec);

      final updated = <String, _TimerState>{};
      _activeTimers.forEach((key, t) {
        if (t.running && t.remaining > 0) {
          final r = t.remaining - 1;
          updated[key] = (remaining: r, running: true);
          if (r <= 0) timerFinished = true;
        } else {
          updated[key] = t;
        }
      });
      _activeTimers
        ..clear()
        ..addAll(updated);
    });

    if (timerFinished) {
      ToastService.instance.show('⏰ Timer done! Step complete.');
    }
    if (headsUpMsg != null) _showHeadsUp(headsUpMsg!);
  }

  void _showHeadsUp(String msg) {
    setState(() => _headsUp = msg);
    Future<void>.delayed(const Duration(milliseconds: 4000), () {
      if (mounted && _headsUp == msg) setState(() => _headsUp = null);
    });
  }

  // ── Dish expand / steps ──

  void _toggleExpand(int dishId) {
    if (!_started) return;
    setState(() => _expandedDishId = _expandedDishId == dishId ? null : dishId);
  }

  void _expandAndFlash(int dishId) {
    setState(() {
      _expandedDishId = dishId;
      _flashDishId = dishId;
    });
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _flashDishId = null);
    });
  }

  void _toggleStep(GenieDish dish, int stepIndex) {
    final timeline = GeniePlannerData.buildTimeline(_dishes, _serveTime);
    final done = Set<int>.from(_dishStepsDone[dish.id] ?? {});
    final wasChecked = done.contains(stepIndex);
    setState(() {
      if (wasChecked) {
        done.remove(stepIndex);
      } else {
        done.add(stepIndex);
      }
      _dishStepsDone[dish.id] = done;
    });
    if (wasChecked) return;
    HapticsService.selection();

    final timelineIndex = timeline.indexWhere((e) => e.dish.id == dish.id);
    int? nextUndone;
    for (var i = stepIndex + 1; i < dish.steps.length; i++) {
      if (!done.contains(i)) {
        nextUndone = i;
        break;
      }
    }
    if (nextUndone != null && timelineIndex >= 0) {
      final resolvedNext = nextUndone;
      setState(
        () => _stepCursor = (timelineIndex: timelineIndex, step: resolvedNext),
      );
    }

    if (done.length < dish.steps.length) return;

    setState(() => _celebration = (dishName: dish.name, emoji: dish.emoji));
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _celebration = null);
    });
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      GenieDish? next;
      var nextTimelineIdx = -1;
      for (var i = 0; i < timeline.length; i++) {
        final d = timeline[i].dish;
        final doneCount = _dishStepsDone[d.id]?.length ?? 0;
        if (d.id != dish.id && doneCount < d.steps.length) {
          next = d;
          nextTimelineIdx = i;
          break;
        }
      }
      final resolvedDish = next;
      setState(() {
        if (resolvedDish != null) {
          _expandedDishId = resolvedDish.id;
          _flashDishId = resolvedDish.id;
          _stepCursor = (timelineIndex: nextTimelineIdx, step: 0);
        } else {
          _expandedDishId = null;
        }
      });
      if (resolvedDish != null) {
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _flashDishId = null);
        });
      }
    });
  }

  void _toggleTimer(GenieDish dish, int stepIndex) {
    final key = '${dish.id}-$stepIndex';
    final step = dish.steps[stepIndex];
    final current = _activeTimers[key];
    setState(() {
      if (current != null && current.running) {
        _activeTimers[key] = (remaining: current.remaining, running: false);
      } else {
        _activeTimers[key] = (
          remaining: current?.remaining ?? step.seconds,
          running: true,
        );
      }
    });
  }

  Map<int, _TimerState> _timerStatesFor(int dishId) {
    final map = <int, _TimerState>{};
    _activeTimers.forEach((key, value) {
      final parts = key.split('-');
      if (parts.length == 2 && int.tryParse(parts[0]) == dishId) {
        final stepIdx = int.tryParse(parts[1]);
        if (stepIdx != null) map[stepIdx] = value;
      }
    });
    return map;
  }

  // ── Step-view cursor ──

  int _currentFlatIndexFor(List<GenieFlatStep> flat) {
    final idx = flat.indexWhere(
      (f) =>
          f.timelineIndex == _stepCursor.timelineIndex &&
          f.stepIndex == _stepCursor.step,
    );
    return idx < 0 ? 0 : idx;
  }

  void _advanceStepCursor(List<GenieFlatStep> flat) {
    final idx = _currentFlatIndexFor(flat);
    if (idx + 1 < flat.length) {
      final nf = flat[idx + 1];
      setState(
        () =>
            _stepCursor = (timelineIndex: nf.timelineIndex, step: nf.stepIndex),
      );
    }
  }

  void _retreatStepCursor(List<GenieFlatStep> flat) {
    final idx = _currentFlatIndexFor(flat);
    if (idx > 0) {
      final pf = flat[idx - 1];
      setState(
        () =>
            _stepCursor = (timelineIndex: pf.timelineIndex, step: pf.stepIndex),
      );
    }
  }

  // ── Ingredients ──

  void _toggleIngredient(String key) {
    setState(() => _checkedIngs[key] = !(_checkedIngs[key] ?? false));
  }

  void _orderMissing(String service, int missingCount) {
    setState(() {
      for (final dish in _dishes) {
        for (var i = 0; i < dish.ingredients.length; i++) {
          _checkedIngs['${dish.id}-$i'] = true;
        }
      }
      _showIngredients = false;
    });
    ToastService.instance.show(
      '✅ $missingCount items ordered via $service — ready to cook!',
    );
  }

  void _cookAnyway() {
    setState(() => _showIngredients = false);
    ToastService.instance.show('🔥 Cooking anyway — you got this!');
  }

  bool get _allStepsChecked => _dishes.every(
    (d) => (_dishStepsDone[d.id]?.length ?? 0) >= d.steps.length,
  );

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final timeline = GeniePlannerData.buildTimeline(_dishes, _serveTime);
    final maxTotal = GeniePlannerData.maxTotalMinutes(_dishes);
    final serveMinutes = GeniePlannerData.parseTime(_serveTime);
    final startMinutes = serveMinutes - maxTotal;
    final startTimeStr = GeniePlannerData.formatClock(startMinutes);
    final currentClock = GeniePlannerData.formatClock(
      startMinutes + _elapsedMin,
    );
    final allDone = timeline.every(
      (e) => _statusFor(e) == GenieDishStatus.done,
    );
    final flatSteps = buildFlatSteps(timeline);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(flow),
                if (_started) _buildViewModeToggle(),
                _buildIngredientsBanner(),
                if (!_started)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _startCooking,
                        icon: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const Text(
                          'Start Cooking',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_headsUp != null && _started)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.amber.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _headsUp!,
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Expanded(
                  child: (_viewMode == GenieMealViewMode.step && _started)
                      ? GenieStepWalkthrough(
                          flatSteps: flatSteps,
                          currentIndex: _currentFlatIndexFor(flatSteps),
                          dishStepsDone: _dishStepsDone,
                          activeTimers: _activeTimers,
                          onJumpTo: (i) => setState(() {
                            _stepCursor = (
                              timelineIndex: flatSteps[i].timelineIndex,
                              step: flatSteps[i].stepIndex,
                            );
                          }),
                          onMarkDone: () {
                            final f =
                                flatSteps[_currentFlatIndexFor(flatSteps)];
                            setState(() => _expandedDishId = f.dish.id);
                            _toggleStep(f.dish, f.stepIndex);
                          },
                          onAdvance: () => _advanceStepCursor(flatSteps),
                          onPrev: () => _retreatStepCursor(flatSteps),
                          onToggleTimer: () {
                            final f =
                                flatSteps[_currentFlatIndexFor(flatSteps)];
                            _toggleTimer(f.dish, f.stepIndex);
                          },
                          onFinish: () => flow.setScreen(AppScreen.postCook),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            if (!_started)
                              _buildServeTimeCard(startTimeStr, maxTotal),
                            if (_started && !_completed)
                              _buildLiveClockCard(currentClock, maxTotal),
                            if (!_started)
                              _buildGeniePlanExplanation(
                                startTimeStr,
                                startMinutes,
                              ),
                            const SizedBox(height: 4),
                            const Text(
                              'COOKING TIMELINE',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_started)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildProgressSummary(maxTotal),
                              ),
                            for (var i = 0; i < timeline.length; i++)
                              _buildDishCard(timeline, i),
                            _buildServeMarker(allDone),
                            const SizedBox(height: 16),
                            Glass(
                              borderRadius: 16,
                              padding: const EdgeInsets.all(16),
                              child: _buildSummaryStats(maxTotal),
                            ),
                            const SizedBox(height: 16),
                            _buildCta(flow, timeline),
                            if (_started && _allStepsChecked)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        flow.setScreen(AppScreen.postCook),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.coral,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
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
                            if (!_started)
                              const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: Text(
                                  '⭐ Premium feature · Genie calculates timing '
                                  'based on prep + cook durations',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
            if (_celebration != null) _buildCelebrationOverlay(),
            if (_showIngredients)
              GenieIngredientsSheet(
                dishes: _dishes,
                checked: _checkedIngs,
                onToggle: _toggleIngredient,
                onClose: () => setState(() => _showIngredients = false),
                onOrder: _orderMissing,
                onCookAnyway: _cookAnyway,
              ),
          ],
        ),
      ),
    );
  }

  // ── Sub-sections ──

  Widget _buildHeader(FlowCubit flow) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: flow.goBack,
            child: const Icon(Icons.close, size: 22, color: AppColors.muted),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  '⏱ Meal Timing Planner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Everything ready at the same time",
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cycleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.amber.withValues(alpha: 0.27),
                ),
              ),
              child: Text(
                '${_demoSpeed}x ⚡',
                style: const TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeToggle() {
    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _viewModeButton('Step View', GenieMealViewMode.step)),
          Expanded(
            child: _viewModeButton('Full Timeline', GenieMealViewMode.timeline),
          ),
        ],
      ),
    );
  }

  Widget _viewModeButton(String label, GenieMealViewMode mode) {
    final active = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [AppColors.coral, AppColors.amber])
              : null,
          color: active ? null : Colors.white.withValues(alpha: 0.04),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.muted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsBanner() {
    final totalIngs = _dishes.fold<int>(0, (s, d) => s + d.ingredients.length);
    final checkedCount = _checkedIngs.values.where((v) => v).length;
    final missing = totalIngs - checkedCount;
    final allReady = missing <= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: () => setState(() => _showIngredients = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: allReady
                ? const Color(0x144CAF50)
                : AppColors.amber.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: allReady
                  ? const Color(0x334CAF50)
                  : AppColors.amber.withValues(alpha: 0.13),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: allReady
                      ? const Color(0x264CAF50)
                      : AppColors.amber.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  allReady ? '✅' : '🧾',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allReady
                          ? 'All ingredients ready!'
                          : '$checkedCount/$totalIngs ingredients checked',
                      style: TextStyle(
                        color: allReady ? AppColors.saveGreen : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      allReady
                          ? 'Tap to review'
                          : '$missing missing — tap to check off or order',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: allReady ? AppColors.saveGreen : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServeTimeCard(String startTimeStr, int maxTotal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Glass(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SERVE TIME',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _serveTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in GeniePlannerData.serveTimeOptions)
                  GestureDetector(
                    onTap: () => setState(() => _serveTime = t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _serveTime == t
                            ? AppColors.amber
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        t.replaceFirst(':00 ', ' '),
                        style: TextStyle(
                          color: _serveTime == t
                              ? Colors.black
                              : AppColors.muted,
                          fontSize: 11,
                          fontWeight: _serveTime == t
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppColors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Start cooking at $startTimeStr — ${maxTotal}m total',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveClockCard(String currentClock, int maxTotal) {
    final remaining = maxTotal - _elapsedMin;
    final pct = (_elapsedMin / maxTotal * 100).clamp(0, 100);
    final barColor = pct < 25
        ? AppColors.coral
        : pct < 50
        ? const Color(0xFFFF9800)
        : pct < 75
        ? AppColors.amber
        : AppColors.saveGreen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Glass(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        borderColor: AppColors.coral.withValues(alpha: 0.13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔴 COOKING',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                    Text(
                      currentClock,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text(
                      'REMAINING',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                    Text(
                      '${remaining}m',
                      style: TextStyle(
                        color: remaining <= 5
                            ? AppColors.coral
                            : AppColors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'SERVE AT',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                    Text(
                      _serveTime,
                      style: const TextStyle(
                        color: AppColors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (pct / 100).toDouble(),
                minHeight: 4,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_elapsedMin}m elapsed${_demoSpeed > 1 ? ' (${_demoSpeed}x)' : ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                Text(
                  '${remaining}m remaining',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeniePlanExplanation(String startTimeStr, int startMinutes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.07)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: AppColors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(
                      text: "Genie's plan: ",
                      style: TextStyle(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text:
                          'Start chicken at $startTimeStr (longest cook). '
                          'Rice at ${GeniePlannerData.formatClock(startMinutes + 18)}. '
                          'Salad at ${GeniePlannerData.formatClock(startMinutes + 32)}. '
                          'Drinks at ${GeniePlannerData.formatClock(startMinutes + 35)}. '
                          'Everything lands on the table at $_serveTime.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummary(int maxTotal) {
    final totalStepsAll = _dishes.fold<int>(0, (s, d) => s + d.steps.length);
    final doneStepsAll = _dishStepsDone.values.fold<int>(
      0,
      (s, set) => s + set.length,
    );
    final stepPct = totalStepsAll > 0
        ? (doneStepsAll / totalStepsAll * 100).round()
        : 0;
    final pacePct = (_elapsedMin / maxTotal * 100).round();
    return Row(
      children: [
        Expanded(child: _progressBarLabeled('PACE', pacePct, AppColors.coral)),
        const SizedBox(width: 12),
        Expanded(child: _progressBarLabeled('STEPS', stepPct, AppColors.cyan)),
      ],
    );
  }

  Widget _progressBarLabeled(String label, int pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0, 1).toDouble(),
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDishCard(List<GenieTimelineEntry> timeline, int i) {
    final entry = timeline[i];
    final done = _dishStepsDone[entry.dish.id] ?? {};
    final allDoneThisDish = done.length >= entry.dish.steps.length;
    String? quickNextLabel;
    VoidCallback? onQuickNext;
    if (allDoneThisDish) {
      GenieTimelineEntry? nextEntry;
      for (var j = i + 1; j < timeline.length; j++) {
        final d = timeline[j].dish;
        if ((_dishStepsDone[d.id]?.length ?? 0) < d.steps.length) {
          nextEntry = timeline[j];
          break;
        }
      }
      if (nextEntry != null) {
        quickNextLabel = 'Next: ${nextEntry.dish.emoji} ▸';
        onQuickNext = () => _expandAndFlash(nextEntry!.dish.id);
      }
    } else {
      quickNextLabel = 'Next ▸';
      onQuickNext = () {
        for (var si = 0; si < entry.dish.steps.length; si++) {
          if (!done.contains(si)) {
            _toggleStep(entry.dish, si);
            break;
          }
        }
      };
    }

    return GenieDishTimelineCard(
      entry: entry,
      status: _statusFor(entry),
      started: _started,
      expanded: _expandedDishId == entry.dish.id,
      flashed: _flashDishId == entry.dish.id,
      doneSteps: done,
      timerStates: _timerStatesFor(entry.dish.id),
      countdownSeconds: _dishCountdowns[entry.dish.id],
      quickNextLabel: quickNextLabel,
      onToggleExpand: () => _toggleExpand(entry.dish.id),
      onToggleStep: (si) => _toggleStep(entry.dish, si),
      onToggleTimer: (si) => _toggleTimer(entry.dish, si),
      onQuickNext: onQuickNext,
    );
  }

  Widget _buildServeMarker(bool allDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: allDone ? AppColors.saveGreen : null,
                    gradient: allDone
                        ? null
                        : const LinearGradient(
                            colors: [AppColors.coral, AppColors.amber],
                          ),
                  ),
                  child: const Text('🍽', style: TextStyle(fontSize: 10)),
                ),
                const SizedBox(height: 2),
                Text(
                  _serveTime,
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: allDone ? const Color(0x144CAF50) : null,
                gradient: allDone
                    ? null
                    : LinearGradient(
                        colors: [
                          AppColors.amber.withValues(alpha: 0.07),
                          AppColors.coral.withValues(alpha: 0.03),
                        ],
                      ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: allDone
                      ? const Color(0x4D4CAF50)
                      : AppColors.amber.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone
                        ? "✓ Everything's ready!"
                        : '🍽 Serve at $_serveTime',
                    style: TextStyle(
                      color: allDone ? AppColors.saveGreen : AppColors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'All dishes served hot together',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(int maxTotal) {
    final stoveCount = _dishes.where((d) => d.cookMin > 0).length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statTile('${_dishes.length}', 'Dishes'),
        _vDivider(),
        _statTile('${maxTotal}m', 'Total'),
        _vDivider(),
        _statTile('$stoveCount', 'Stove'),
        _vDivider(),
        _statTile(_serveTime.replaceFirst(':00 ', ' '), 'Serve'),
      ],
    );
  }

  Widget _statTile(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
    ],
  );

  Widget _vDivider() =>
      Container(width: 1, height: 32, color: AppColors.glassBorder);

  Widget _buildCta(FlowCubit flow, List<GenieTimelineEntry> timeline) {
    if (!_started) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _startCooking,
          icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
          label: const Text(
            'Start Cooking — Genie will guide you',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.coral,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      );
    }
    if (_completed) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0x0F4CAF50),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0x334CAF50)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 6, color: AppColors.saveGreen),
                    SizedBox(width: 6),
                    Text(
                      'LIVE — Pace timer running',
                      style: TextStyle(
                        color: AppColors.saveGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _resetCooking,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildNextActionAlert(timeline),
        const SizedBox(height: 8),
        const Text(
          'Pace timer never pauses — beat the clock for +50 bonus XP 🔥',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0x33FFFFFF), fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildNextActionAlert(List<GenieTimelineEntry> timeline) {
    GenieTimelineEntry? next;
    for (final e in timeline) {
      if (_statusFor(e) == GenieDishStatus.waiting) {
        next = e;
        break;
      }
    }
    if (next == null) {
      final cooking = timeline
          .where(
            (e) =>
                _statusFor(e) == GenieDishStatus.cooking ||
                _statusFor(e) == GenieDishStatus.prepping,
          )
          .toList();
      if (cooking.isEmpty) return const SizedBox.shrink();
      return _alertBox(
        '🔥',
        '${cooking.length} dish${cooking.length > 1 ? 'es' : ''} still cooking — almost there!',
        AppColors.coral,
      );
    }
    final minsUntil = next.startOffset - _elapsedMin;
    if (minsUntil <= 0) {
      return _alertBox(
        next.dish.emoji,
        '⚡ Start ${next.dish.name} NOW!',
        AppColors.amber,
      );
    }
    return _alertBox(
      next.dish.emoji,
      'Start ${next.dish.name} in $minsUntil min (${next.startClock})',
      AppColors.amber,
    );
  }

  Widget _alertBox(String emoji, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.13)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationOverlay() {
    final c = _celebration!;
    return IgnorePointer(
      child: Center(
        child: PopIn(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x4D4CAF50)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                Text(
                  '✓ ${c.dishName} done!',
                  style: const TextStyle(
                    color: AppColors.saveGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
