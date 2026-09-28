import 'package:flutter_test/flutter_test.dart';

import 'package:bite/core/router/app_screen.dart';
import 'package:bite/core/router/flow_cubit.dart';

/// Pumps past the async transition timers (120ms in + 140ms out).
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 400));

void main() {
  group('FlowCubit', () {
    test('starts on the splash screen without a transition', () {
      final flow = FlowCubit();
      expect(flow.state.screen, AppScreen.splash);
      expect(flow.state.transitionVisible, isFalse);
    });

    test('setScreen with the same screen is a no-op', () {
      final flow = FlowCubit();
      flow.setScreen(AppScreen.splash);
      expect(flow.state.screen, AppScreen.splash);
      expect(flow.state.previous, AppScreen.splash);
    });

    test('splash -> auth swaps immediately with no overlay', () {
      final flow = FlowCubit();
      flow.setScreen(AppScreen.auth);
      expect(flow.state.screen, AppScreen.auth);
      expect(flow.state.transitionVisible, isFalse);
    });

    test('setScreen animates a transition then swaps', () async {
      final flow = FlowCubit();
      flow.setScreen(AppScreen.auth); // bypass splash fast-path
      flow.setScreen(AppScreen.emailSignup);

      expect(flow.state.screen, AppScreen.auth);
      expect(flow.state.transitionVisible, isTrue);

      await settle();
      expect(flow.state.screen, AppScreen.emailSignup);
      expect(flow.state.transitionVisible, isFalse);
    });

    test('goBack skips flow screens and falls back to swipeDeck', () async {
      final flow = FlowCubit();
      flow.resetTo(AppScreen.swipeDeck);
      flow.setScreen(AppScreen.emailLogin);
      await settle();

      expect(flow.state.screen, AppScreen.emailLogin);

      flow.goBack();
      await settle();
      // emailLogin is block-listed, so back lands on swipeDeck.
      expect(flow.state.screen, AppScreen.swipeDeck);
    });

    test('resetTo clears history and emits without a transition', () {
      final flow = FlowCubit();
      flow.setScreen(AppScreen.auth);
      flow.resetTo(AppScreen.swipeDeck);

      expect(flow.state.screen, AppScreen.swipeDeck);
      expect(flow.state.transitionVisible, isFalse);
    });

    test('skipNext walks the onboarding shortcut', () async {
      final flow = FlowCubit();
      flow.resetTo(AppScreen.auth);
      flow.skipNext();
      await settle();
      expect(flow.state.screen, AppScreen.profileSetup);
    });

    test('skipNext falls back to home at the end of the chain', () async {
      final flow = FlowCubit();
      flow.resetTo(AppScreen.gamificationTutorial);
      flow.skipNext();
      expect(flow.state.screen, AppScreen.swipeDeck);
    });

    test('skipToHome resets straight to the deck', () {
      final flow = FlowCubit();
      flow.resetTo(AppScreen.onboardingSkill);
      flow.skipToHome();
      expect(flow.state.screen, AppScreen.swipeDeck);
    });
  });
}
