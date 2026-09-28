import 'package:flutter_test/flutter_test.dart';

import 'package:bite/core/router/app_screen.dart';

void main() {
  group('AppScreenX.isSkippedOnBack', () {
    test('marks flow screens as skipped', () {
      const skipped = [
        AppScreen.splash,
        AppScreen.auth,
        AppScreen.emailLogin,
        AppScreen.emailSignup,
        AppScreen.forgotPassword,
        AppScreen.profileSetup,
        AppScreen.onboardingCuisine,
        AppScreen.onboardingDietary,
        AppScreen.onboardingSkill,
        AppScreen.gamificationTutorial,
        AppScreen.drinksAgeGate,
      ];
      for (final screen in skipped) {
        expect(screen.isSkippedOnBack, isTrue, reason: screen.name);
      }
    });

    test('keeps core screens in back history', () {
      expect(AppScreen.swipeDeck.isSkippedOnBack, isFalse);
      expect(AppScreen.profile.isSkippedOnBack, isFalse);
      expect(AppScreen.settings.isSkippedOnBack, isFalse);
    });
  });

  group('AppScreenX.skipNext', () {
    test('walks the dev shortcut chain', () {
      expect(AppScreen.auth.skipNext, AppScreen.profileSetup);
      expect(AppScreen.emailLogin.skipNext, AppScreen.profileSetup);
      expect(AppScreen.emailSignup.skipNext, AppScreen.profileSetup);
      expect(AppScreen.profileSetup.skipNext, AppScreen.onboardingCuisine);
      expect(AppScreen.onboardingCuisine.skipNext, AppScreen.onboardingDietary);
      expect(AppScreen.onboardingDietary.skipNext, AppScreen.onboardingSkill);
      expect(AppScreen.onboardingSkill.skipNext, AppScreen.gamificationTutorial);
      expect(AppScreen.gamificationTutorial.skipNext, isNull);
    });
  });

  group('AppScreenX.isAuthOrOnboarding', () {
    test('true for auth and onboarding screens', () {
      expect(AppScreen.splash.isAuthOrOnboarding, isTrue);
      expect(AppScreen.welcome.isAuthOrOnboarding, isTrue);
      expect(AppScreen.emailLogin.isAuthOrOnboarding, isTrue);
      expect(AppScreen.gamificationTutorial.isAuthOrOnboarding, isTrue);
    });

    test('false for home screens', () {
      expect(AppScreen.swipeDeck.isAuthOrOnboarding, isFalse);
      expect(AppScreen.profile.isAuthOrOnboarding, isFalse);
    });
  });

  group('AppScreenX.showsBottomNav', () {
    test('true for the tab screens', () {
      for (final screen in [
        AppScreen.swipeDeck,
        AppScreen.socialFeed,
        AppScreen.saved,
        AppScreen.chatList,
      ]) {
        expect(screen.showsBottomNav, isTrue, reason: screen.name);
      }
    });

    test('false for non-tab screens', () {
      expect(AppScreen.profile.showsBottomNav, isFalse);
      expect(AppScreen.auth.showsBottomNav, isFalse);
    });
  });
}
