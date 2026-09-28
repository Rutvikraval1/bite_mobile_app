import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../data/cook_data.dart';
import '../../domain/cook_session.dart';

/// Hands-free, step-by-step cooking flow — ports `CookModeScreen` from
/// `screens-cooking.jsx`.
///
/// Simplified from the prototype: the advanced "peek ahead" / minimum
/// dwell-time pacing gate and the per-minute milestone toasts were dropped
/// to keep the interaction surface manageable for this port; the core
/// task-checklist walkthrough, per-step timers, pace tracking and the two
/// view modes (Step View / Full Timeline) are preserved.
class CookModeScreen extends StatefulWidget {
  const CookModeScreen({super.key});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  static const int _targetSecs = 25 * 60;

  late final bool _isDrink;
  late final Color _themeColor;
  late final List<CookStepDef> _steps;
  late final List<CookDish> _dishes;

  int _currentStep = 0;
  final Set<int> _completedSteps = {};
  final Set<String> _checkedTasks = {};
  String _viewMode = 'A';
  int _demoSpeed = 3;

  int _totalTimer = 0;
  int _personalTimer = 0;
  bool _personalPaused = false;
  final Map<int, int> _stepTimers = {};
  int? _stepTimerRunning;
  bool _showTimerDonePopupFlag = false;

  final Set<String> _cookIngChecked = {};

  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppStateCubit>().state;
    _isDrink = appState.subTab == DeckTab.drinks;
    _themeColor = _isDrink ? AppColors.drinksBlue : AppColors.coral;
    _steps = _isDrink ? CookData.drinkCookSteps : CookData.foodCookSteps;
    _dishes = _isDrink ? CookData.drinkDishes(_themeColor) : CookData.foodDishes(_themeColor);
    _ticker = Timer.periodic(const Duration(milliseconds: 350), _onTick);
    if (_steps[_currentStep].timerSecs != null) {
      _startStepTimer(_currentStep);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int get _tickAmount => switch (_demoSpeed) {
        <= 2 => 1,
        <= 3 => 5,
        <= 4 => 30,
        _ => 60,
      };

  void _onTick(Timer t) {
    if (!mounted) return;
    setState(() {
      _totalTimer += _tickAmount;
      if (!_personalPaused) _personalTimer += _tickAmount;
      final running = _stepTimerRunning;
      if (running != null) {
        final remaining = (_stepTimers[running] ?? (_steps[running].timerSecs ?? 0)) - _tickAmount;
        if (remaining <= 0) {
          _stepTimers[running] = 0;
          _stepTimerRunning = null;
          _showTimerDonePopupFlag = true;
        } else {
          _stepTimers[running] = remaining;
        }
      }
    });
  }

  void _startStepTimer(int stepIdx) {
    _stepTimers.putIfAbsent(stepIdx, () => _steps[stepIdx].timerSecs ?? 0);
    setState(() => _stepTimerRunning = stepIdx);
  }

  void _goToStep(int i) {
    setState(() => _currentStep = i);
    final def = _steps[i];
    if (def.timerSecs != null && !_stepTimers.containsKey(i) && _stepTimerRunning != i) {
      _startStepTimer(i);
    }
  }

  bool _stepAllDone(int i) {
    final tasks = _steps[i].tasks;
    for (var ti = 0; ti < tasks.length; ti++) {
      if (!_checkedTasks.contains('$i-$ti')) return false;
    }
    return true;
  }

  void _toggleTask(int stepIdx, int taskIdx) {
    final key = '$stepIdx-$taskIdx';
    setState(() {
      if (_checkedTasks.contains(key)) {
        _checkedTasks.remove(key);
      } else {
        _checkedTasks.add(key);
      }
    });
    if (_stepAllDone(stepIdx) && !_completedSteps.contains(stepIdx)) {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _completedSteps.add(stepIdx));
      });
    }
  }

  void _finishCooking() {
    CookSession.instance
      ..paceRatio = _totalTimer / _targetSecs
      ..isDrink = _isDrink;
    context.read<FlowCubit>().setScreen(AppScreen.postCook);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<FlowCubit>().goBack();
      },
      child: Material(
        color: AppColors.bgDark,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _topBar(),
                  _viewModeRow(),
                  _ingredientsBanner(),
                  _progressBars(),
                  Expanded(
                    child: _viewMode == 'A' ? _modeA(step) : _modeB(),
                  ),
                  if (_viewMode == 'B') _bottomNavRow(step),
                ],
              ),
              if (_showTimerDonePopupFlag) _timerDonePopup(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top chrome ──

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.read<FlowCubit>().goBack(),
            child: const Icon(Icons.close_rounded, color: AppColors.muted, size: 24),
          ),
          Text(_isDrink ? 'Mix Mode' : 'Cook Mode', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('LIVE', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              SizedBox(width: 6),
              NotifDot(color: Color(0xFF4CAF50), size: 6),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewModeRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  for (final mode in const [('A', 'Step View'), ('B', 'Full Timeline')])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _viewMode = mode.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: _viewMode == mode.$1 ? _themeColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(mode.$2,
                              style: TextStyle(
                                  color: _viewMode == mode.$1 ? Colors.white : AppColors.muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _demoSpeed = _demoSpeed >= 5 ? 1 : _demoSpeed + 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.27)),
              ),
              child: Text('${_demoSpeed}x ⚡',
                  style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientsBanner() {
    final total = _dishes.fold<int>(0, (s, d) => s + d.items.length);
    final checked = _cookIngChecked.length;
    final allReady = checked >= total && total > 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GestureDetector(
        onTap: _openIngredientsSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: allReady ? const Color(0x144CAF50) : AppColors.amber.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: allReady ? const Color(0x334CAF50) : AppColors.amber.withValues(alpha: 0.13)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: allReady ? const Color(0x264CAF50) : AppColors.amber.withValues(alpha: 0.13),
                ),
                child: Text(allReady ? '✅' : '🧾', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      allReady ? 'All ingredients ready!' : '$checked/$total ingredients checked',
                      style: TextStyle(
                          color: allReady ? const Color(0xFF4CAF50) : Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      allReady ? 'Tap to review' : '${total - checked} missing — tap to check off',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: allReady ? const Color(0xFF4CAF50) : AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBars() {
    final timePct = (_totalTimer / _targetSecs).clamp(0.0, 1.0);
    final stepPct = _steps.length <= 1 ? 1.0 : (_currentStep / (_steps.length - 1)).clamp(0.0, 1.0);
    final paceRatioNow = _totalTimer <= 0 ? 0.0 : _totalTimer / (_targetSecs * ((_currentStep + 1) / _steps.length));
    final paceColor = paceRatioNow < 1.15 ? const Color(0xFF4CAF50) : paceRatioNow < 1.3 ? AppColors.amber : AppColors.coral;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              _barLabel('⏱ ${CookData.fmtTime(_totalTimer)}', paceColor),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _personalPaused = !_personalPaused),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_personalPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 14, color: AppColors.cyan),
                    const SizedBox(width: 3),
                    Text(CookData.fmtTime(_personalTimer),
                        style: TextStyle(
                            color: _personalPaused ? AppColors.cyan : AppColors.muted,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _thinBar('PACE', timePct, _themeColor)),
              const SizedBox(width: 12),
              Expanded(child: _thinBar('STEPS', stepPct, AppColors.cyan)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barLabel(String text, Color color) =>
      Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace'));

  Widget _thinBar(String label, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700)),
            Text('${(pct * 100).round()}%', style: TextStyle(color: color, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: color.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // ── Mode A: step-by-step walkthrough ──

  Widget _modeA(CookStepDef step) {
    final allTasksDone = _stepAllDone(_currentStep);
    final firstUnchecked = () {
      for (var ti = 0; ti < step.tasks.length; ti++) {
        if (!_checkedTasks.contains('$_currentStep-$ti')) return ti;
      }
      return step.tasks.length - 1;
    }();
    final isLast = _currentStep == _steps.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _steps.length; i++)
                GestureDetector(
                  onTap: () => _goToStep(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentStep ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: _completedSteps.contains(i)
                          ? const Color(0xFF4CAF50)
                          : i == _currentStep
                              ? (_steps[i].isSide ? AppColors.amber : _themeColor)
                              : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ZoomIn(
              key: ValueKey(_currentStep),
              duration: const Duration(milliseconds: 260),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: (step.isSide ? AppColors.amber : _themeColor).withValues(alpha: 0.2)),
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
                              color: (step.isSide ? AppColors.amber : _themeColor).withValues(alpha: 0.13),
                              border: Border.all(color: (step.isSide ? AppColors.amber : _themeColor).withValues(alpha: 0.27)),
                            ),
                            child: Text('${_currentStep + 1}',
                                style: TextStyle(
                                    color: step.isSide ? AppColors.amber : _themeColor,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (step.isSide)
                                  const Text('SIDE DISH',
                                      style: TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                Text(step.text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                                Text('Task ${allTasksDone ? step.tasks.length : firstUnchecked + 1}/${step.tasks.length}',
                                    style: const TextStyle(color: Color(0x6BFFFFFF), fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _currentTaskCard(step, allTasksDone, firstUnchecked),
                      const SizedBox(height: 12),
                      for (var ti = 0; ti < step.tasks.length; ti++) _taskRow(step, ti, firstUnchecked, allTasksDone),
                      if (step.timerSecs != null) ...[
                        const SizedBox(height: 12),
                        _stepTimerBox(step),
                      ],
                      if (step.tip != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.amber.withValues(alpha: 0.1)),
                          ),
                          child: Text('💡 Pro tip: ${step.tip}',
                              style: const TextStyle(color: AppColors.amber, fontSize: 11, height: 1.4)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {
              if (!allTasksDone) {
                ToastService.instance.show('🍳 Complete all tasks on this step first');
                return;
              }
              if (isLast) {
                _finishCooking();
              } else {
                _goToStep(_currentStep + 1);
              }
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: allTasksDone ? LinearGradient(colors: [_themeColor, AppColors.amber]) : null,
                color: allTasksDone ? null : Colors.white.withValues(alpha: 0.04),
                boxShadow: allTasksDone ? [BoxShadow(color: _themeColor.withValues(alpha: 0.33), blurRadius: 20)] : null,
              ),
              alignment: Alignment.center,
              child: Text(
                isLast
                    ? (allTasksDone ? '🔥 Done — Rate & Share!' : 'Complete ${step.tasks.length - (allTasksDone ? step.tasks.length : firstUnchecked)} tasks')
                    : (allTasksDone ? '✨ Next Step →' : '👀 Complete tasks to continue'),
                style: TextStyle(
                    color: allTasksDone ? Colors.white : Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentTaskCard(CookStepDef step, bool allTasksDone, int activeIdx) {
    if (allTasksDone) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0x0F4CAF50),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x334CAF50)),
        ),
        child: const Column(
          children: [
            Text('✅', style: TextStyle(fontSize: 28)),
            SizedBox(height: 6),
            Text('All tasks complete!', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Tap Next Step to continue', style: TextStyle(color: Color(0x6BFFFFFF), fontSize: 12)),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cyan.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT TASK', style: TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(step.tasks[activeIdx], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _toggleTask(_currentStep, activeIdx),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: AppColors.cyan.withValues(alpha: 0.13),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.27)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 16, color: AppColors.cyan),
                  SizedBox(width: 8),
                  Text('Mark Done', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskRow(CookStepDef step, int ti, int activeIdx, bool allTasksDone) {
    final checked = _checkedTasks.contains('$_currentStep-$ti');
    final isCurrent = ti == activeIdx && !allTasksDone;
    return GestureDetector(
      onTap: () => _toggleTask(_currentStep, ti),
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: checked ? const Color(0x0F4CAF50) : isCurrent ? AppColors.cyan.withValues(alpha: 0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: checked ? const Color(0xFF4CAF50) : Colors.transparent,
                border: Border.all(color: checked ? const Color(0xFF4CAF50) : (isCurrent ? AppColors.cyan : Colors.white.withValues(alpha: 0.15))),
              ),
              child: checked ? const Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                step.tasks[ti],
                style: TextStyle(
                  color: checked ? const Color(0x734CAF50) : isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepTimerBox(CookStepDef step) {
    final remaining = _stepTimers[_currentStep] ?? step.timerSecs!;
    final active = _stepTimerRunning == _currentStep;
    final done = remaining <= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: done ? const Color(0x0F4CAF50) : active ? AppColors.amber.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? const Color(0x4D4CAF50) : active ? AppColors.amber.withValues(alpha: 0.27) : Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Text(
            done ? '00:00' : CookData.fmtTime(remaining),
            style: TextStyle(
              color: done ? const Color(0xFF4CAF50) : active ? AppColors.amber : Colors.white.withValues(alpha: 0.3),
              fontSize: 34,
              fontWeight: FontWeight.w200,
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),
          if (!done)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () => active ? setState(() => _stepTimerRunning = null) : _startStepTimer(_currentStep),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: active ? null : LinearGradient(colors: [AppColors.amber, _themeColor]),
                    color: active ? Colors.white.withValues(alpha: 0.06) : null,
                  ),
                  child: Text(active ? 'Pause' : (_stepTimers.containsKey(_currentStep) ? 'Resume' : 'Start'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Mode B: full timeline ──

  Widget _modeB() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _steps.length,
      itemBuilder: (context, i) {
        final step = _steps[i];
        final isDone = i < _currentStep || _completedSteps.contains(i);
        final isActive = i == _currentStep;
        final isUpcoming = i > _currentStep;
        final showSideDivider = step.isSide && (i == 0 || !_steps[i - 1].isSide);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSideDivider)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Container(height: 1, color: AppColors.amber.withValues(alpha: 0.2))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('SIDES', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                    ),
                    Expanded(child: Container(height: 1, color: AppColors.amber.withValues(alpha: 0.2))),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isActive ? 16 : 12),
                color: isActive
                    ? (step.isSide ? AppColors.amber : _themeColor).withValues(alpha: 0.05)
                    : isDone
                        ? const Color(0x0A4CAF50)
                        : Colors.white.withValues(alpha: 0.02),
                border: Border.all(
                  color: isActive
                      ? (step.isSide ? AppColors.amber : _themeColor).withValues(alpha: 0.2)
                      : isDone
                          ? const Color(0x264CAF50)
                          : Colors.white.withValues(alpha: 0.04),
                ),
              ),
              child: Opacity(
                opacity: isUpcoming ? 0.4 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: isUpcoming ? null : () => _goToStep(i),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: isActive ? 12 : 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                step.text,
                                style: TextStyle(
                                  color: isDone ? Colors.white.withValues(alpha: 0.4) : isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                  fontSize: isActive ? 15 : 12,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (isDone && !isActive) const Icon(Icons.check_rounded, size: 14, color: Color(0xFF4CAF50)),
                            if (isActive) ...[
                              Text(
                                '${step.tasks.indexed.where((e) => _checkedTasks.contains('$i-${e.$1}')).length}/${step.tasks.length}',
                                style: const TextStyle(color: AppColors.muted, fontSize: 10),
                              ),
                              const SizedBox(width: 6),
                              _timelineActionButton(i, step),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (step.timerSecs != null) _timelineTimer(i, step),
                            for (var ti = 0; ti < step.tasks.length; ti++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _timelineTaskRow(i, ti, step),
                              ),
                            if (step.tip != null)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.amber.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.amber.withValues(alpha: 0.1)),
                                ),
                                child: Text('💡 ${step.tip}', style: const TextStyle(color: AppColors.amber, fontSize: 11)),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _timelineActionButton(int i, CookStepDef step) {
    final allDone = _stepAllDone(i);
    final isLast = i == _steps.length - 1;
    return GestureDetector(
      onTap: () {
        if (!allDone) {
          ToastService.instance.show(isLast ? '🍳 Complete the last step to finish' : '🍳 Complete this step\'s tasks first');
          return;
        }
        if (isLast) {
          _finishCooking();
        } else {
          setState(() => _completedSteps.add(i));
          _goToStep(i + 1);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: allDone ? const Color(0x264CAF50) : Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: allDone ? const Color(0x734CAF50) : Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text(
          isLast ? (allDone ? 'Done ✓' : 'Done ▸') : (allDone ? 'Next ▸' : 'Locked'),
          style: TextStyle(color: allDone ? const Color(0xFF4CAF50) : Colors.white.withValues(alpha: 0.3), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _timelineTimer(int i, CookStepDef step) {
    final remaining = _stepTimers[i] ?? step.timerSecs!;
    final running = _stepTimerRunning == i;
    final done = remaining <= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: done ? const Color(0x1F4CAF50) : running ? AppColors.cyan.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
            ),
            child: Text(done ? '✓ Done' : CookData.fmtTime(remaining),
                style: TextStyle(color: done ? const Color(0xFF4CAF50) : running ? AppColors.cyan : AppColors.muted, fontSize: 16, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 8),
          if (!done)
            GestureDetector(
              onTap: () => running ? setState(() => _stepTimerRunning = null) : _startStepTimer(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: running ? Colors.white.withValues(alpha: 0.08) : AppColors.cyan,
                ),
                child: Text(running ? '⏸ Pause' : '▶ Start',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _timelineTaskRow(int i, int ti, CookStepDef step) {
    final checked = _checkedTasks.contains('$i-$ti');
    return GestureDetector(
      onTap: () => _toggleTask(i, ti),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: checked ? const Color(0x0F4CAF50) : Colors.white.withValues(alpha: 0.02),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: checked ? const Color(0xFF4CAF50) : Colors.transparent,
                border: Border.all(color: checked ? const Color(0xFF4CAF50) : Colors.white.withValues(alpha: 0.15), width: 2),
              ),
              child: checked ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(step.tasks[ti],
                  style: TextStyle(
                      color: checked ? Colors.white.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      decoration: checked ? TextDecoration.lineThrough : null)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavRow(CookStepDef step) {
    final allDone = _stepAllDone(_currentStep);
    final isLast = _currentStep == _steps.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: _currentStep == 0
                ? null
                : () {
                    setState(() => _stepTimerRunning = null);
                    _goToStep(_currentStep - 1);
                  },
            child: Opacity(
              opacity: _currentStep == 0 ? 0.3 : 1,
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.glass, border: Border.all(color: AppColors.glassBorder)),
                child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!allDone) return;
                if (isLast) {
                  _finishCooking();
                } else {
                  setState(() => _stepTimerRunning = null);
                  _goToStep(_currentStep + 1);
                }
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  gradient: allDone ? LinearGradient(colors: [_themeColor, AppColors.amber]) : null,
                  color: allDone ? null : _themeColor.withValues(alpha: 0.4),
                ),
                alignment: Alignment.center,
                child: Text(
                  isLast ? "I'm Done! 🎉" : 'Next Step →',
                  style: TextStyle(color: allDone ? Colors.white : Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Timer done popup ──

  Widget _timerDonePopup() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      alignment: Alignment.center,
      child: PopIn(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x4D4CAF50)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⏰', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text("Timer's up!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Ready for the next step?', style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showTimerDonePopupFlag = false;
                    _completedSteps.add(_currentStep);
                  });
                  if (_currentStep < _steps.length - 1) _goToStep(_currentStep + 1);
                },
                child: Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(100)),
                  alignment: Alignment.center,
                  child: const Text('Yes, Next Step →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _showTimerDonePopupFlag = false),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Stay on this step', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ingredients sheet ──

  void _openIngredientsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final total = _dishes.fold<int>(0, (s, d) => s + d.items.length);
            final checked = _cookIngChecked.length;
            final unchecked = total - checked;
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
                child: ColoredBox(
                  color: AppColors.bgDark,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Column(
                          children: [
                            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4))),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('🧾 All Ingredients ($total)', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                                    Text('$checked checked · $unchecked remaining', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(sheetCtx),
                                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var di = 0; di < _dishes.length; di++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.fromLTRB(10, 0, 0, 8),
                                        decoration: BoxDecoration(border: Border(left: BorderSide(color: _dishes[di].color, width: 3))),
                                        child: Row(
                                          children: [
                                            Text(_dishes[di].emoji, style: const TextStyle(fontSize: 18)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(_dishes[di].name,
                                                  style: TextStyle(color: _dishes[di].color, fontSize: 13, fontWeight: FontWeight.w700)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      for (var ii = 0; ii < _dishes[di].items.length; ii++)
                                        _cookIngredientRow(di, ii, setSheetState),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.paddingOf(context).bottom + 16),
                        child: unchecked > 0
                            ? Column(
                                children: [
                                  Text('$unchecked missing — order now or cook anyway',
                                      style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setSheetState(() {
                                        setState(() {
                                          for (var di = 0; di < _dishes.length; di++) {
                                            for (var ii = 0; ii < _dishes[di].items.length; ii++) {
                                              _cookIngChecked.add('$di-$ii');
                                            }
                                          }
                                        });
                                      });
                                      ToastService.instance.show('✅ Ordered $unchecked items — all set to cook!');
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 46,
                                      decoration: BoxDecoration(color: const Color(0x2643A047), borderRadius: BorderRadius.circular(100)),
                                      alignment: Alignment.center,
                                      child: Text('🛒  Order $unchecked Missing Ingredient${unchecked > 1 ? 's' : ''}',
                                          style: const TextStyle(color: Color(0xFF66BB6A), fontWeight: FontWeight.w700, fontSize: 14)),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(sheetCtx);
                                      ToastService.instance.show('🔥 Cooking anyway — you got this!');
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: 36,
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(100)),
                                      alignment: Alignment.center,
                                      child: const Text('Cook Anyway 🔥', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              )
                            : GestureDetector(
                                onTap: () {
                                  Navigator.pop(sheetCtx);
                                  ToastService.instance.show(_isDrink ? "✅ All ingredients ready — let's mix!" : "✅ All ingredients ready — let's cook!");
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(100)),
                                  alignment: Alignment.center,
                                  child: Text('✅ All Ingredients Ready — ${_isDrink ? "Let's Mix!" : "Let's Cook!"}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _cookIngredientRow(int di, int ii, StateSetter setSheetState) {
    final key = '$di-$ii';
    final checked = _cookIngChecked.contains(key);
    return GestureDetector(
      onTap: () {
        setSheetState(() {
          setState(() {
            if (checked) {
              _cookIngChecked.remove(key);
            } else {
              _cookIngChecked.add(key);
            }
          });
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: checked ? const Color(0x0F4CAF50) : Colors.white.withValues(alpha: 0.02),
          border: Border.all(color: checked ? const Color(0x334CAF50) : Colors.white.withValues(alpha: 0.04)),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: checked ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)]) : null,
                border: Border.all(color: checked ? const Color(0xFF4CAF50) : Colors.white.withValues(alpha: 0.15), width: 2),
              ),
              child: checked ? const Icon(Icons.check_rounded, size: 10, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_dishes[di].items[ii],
                  style: TextStyle(
                      color: checked ? const Color(0x664CAF50) : Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      decoration: checked ? TextDecoration.lineThrough : null)),
            ),
          ],
        ),
      ),
    );
  }
}
