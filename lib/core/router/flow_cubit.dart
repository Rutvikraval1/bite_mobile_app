import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_screen.dart';
import 'flow_state.dart';

/// Screen-flow controller — a faithful port of the prototype's `setScreen`,
/// `goBack`, `restartDemo` and `skipNextScreen` behaviors.
class FlowCubit extends Cubit<FlowState> {
  FlowCubit({AppScreen initial = AppScreen.splash})
      : super(FlowState(screen: initial, previous: initial));

  static const int _historyCap = 20;

  static const Duration fadeIn = Duration(milliseconds: 120);
  static const Duration fadeOut = Duration(milliseconds: 140);
  static const Duration safetyTimeout = Duration(milliseconds: 600);

  final List<AppScreen> _history = [];
  int _generation = 0;

  /// Appends [AppScreen.splash] so back-navigation from the first real screen
  /// still behaves (the JS initializes history with `["swipeDeck"]`).
  void seedHistory(AppScreen screen) {
    _history
      ..clear()
      ..add(screen);
  }

  /// Navigate to [next] with the standard fade transition.
  void setScreen(AppScreen next) {
    if (next == state.screen) return;
    final prev = state.screen;
    _history.add(prev);
    if (_history.length > _historyCap) _history.removeAt(0);

    // Splash → auth handoff skips the overlay (matches the JS).
    if (prev == AppScreen.splash) {
      emit(FlowState(
        screen: next,
        previous: prev,
        transitionVisible: false,
      ));
      return;
    }

    _transition(next, prev);
  }

  /// Navigate back through history, skipping the block-listed screens.
  void goBack() {
    while (_history.isNotEmpty && _history.last == state.screen) {
      _history.removeLast();
    }
    AppScreen? target;
    while (_history.isNotEmpty) {
      final candidate = _history.removeLast();
      if (!candidate.isSkippedOnBack) {
        target = candidate;
        break;
      }
    }
    target ??= AppScreen.swipeDeck;
    if (target == state.screen) return;
    final prev = state.screen;
    _transition(target, prev);
  }

  /// Jump straight to [next] without transition (session-aware boot,
  /// restarts, sign-out). Mirrors `setScreenRaw`.
  void resetTo(
    AppScreen next, {
    bool clearHistory = true,
    AppScreen? previous,
  }) {
    _generation++;
    if (clearHistory) {
      seedHistory(next);
    }
    emit(FlowState(
      screen: next,
      previous: previous ?? (clearHistory ? next : state.previous),
      transitionVisible: false,
    ));
  }

  /// Dev "skip →" shortcut.
  void skipNext() {
    final next = state.screen.skipNext;
    if (next != null) {
      setScreen(next);
    } else {
      skipToHome();
    }
  }

  /// Fast-track straight to the home deck.
  void skipToHome() => resetTo(AppScreen.swipeDeck);

  void _transition(AppScreen next, AppScreen prev) {
    final gen = ++_generation;
    emit(state.copyWith(transitionVisible: true));

    Future<void>.delayed(fadeIn, () {
      if (isClosed || gen != _generation) return;
      emit(FlowState(
        screen: next,
        previous: prev,
        transitionVisible: false,
      ));
      Future<void>.delayed(fadeOut, () {
        if (isClosed || gen != _generation) return;
        emit(state.copyWith(transitionVisible: false));
      });
    });

    // Safety: force the overlay off no matter what.
    Future<void>.delayed(safetyTimeout, () {
      if (isClosed || gen != _generation) return;
      emit(state.copyWith(transitionVisible: false));
    });
  }
}
