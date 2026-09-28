import 'package:flutter/foundation.dart';

import 'app_screen.dart';

/// The app's screen-flow state. Mirrors the JS `setScreen`/`goBack`
/// state machine including the fade-transition timing (120ms fade-in →
/// swap → 140ms fade-out, with a 600ms safety cutoff) and the back-skip list.
@immutable
class FlowState {
  const FlowState({
    required this.screen,
    required this.previous,
    this.transitionVisible = false,
  });

  final AppScreen screen;
  final AppScreen previous;
  final bool transitionVisible;

  FlowState copyWith({
    AppScreen? screen,
    AppScreen? previous,
    bool? transitionVisible,
  }) {
    return FlowState(
      screen: screen ?? this.screen,
      previous: previous ?? this.previous,
      transitionVisible: transitionVisible ?? this.transitionVisible,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FlowState &&
        other.screen == screen &&
        other.previous == previous &&
        other.transitionVisible == transitionVisible;
  }

  @override
  int get hashCode => Object.hash(screen, previous, transitionVisible);
}
