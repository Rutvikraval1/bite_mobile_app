/// All screens in the app — mirrors the JS `setScreen("name")` routes.
enum AppScreen {
  splash,
  welcome,
  auth,
  emailLogin,
  emailSignup,
  forgotPassword,
  profileSetup,
  onboardingCuisine,
  onboardingDietary,
  onboardingSkill,
  gamificationTutorial,
  drinksAgeGate,

  swipeDeck,
  socialFeed,
  saved,
  chatList,
  genie,

  recipeDetail,
  placeDetail,

  cookMode,
  postCook,

  profile,
  notifications,
  competition,
  eloVoting,
  creatorProfile,
  creatorCreate,
  shareSheet,
  settings,
  editProfile,
  communityImpact,
  premium,

  mealBuilder,
  genieChat,
  genieFilter,
  geniePlanner,
  genieMeals,
  genieScan,

  chatThread,
  cookingLevel,
  tipFlow,
  mealReminder,
}

extension AppScreenX on AppScreen {
  /// Screens skipped when walking back through history (ports the JS list).
  bool get isSkippedOnBack => switch (this) {
        AppScreen.postCook ||
        AppScreen.tipFlow ||
        AppScreen.shareSheet ||
        AppScreen.drinksAgeGate ||
        AppScreen.forgotPassword ||
        AppScreen.auth ||
        AppScreen.emailLogin ||
        AppScreen.emailSignup ||
        AppScreen.profileSetup ||
        AppScreen.onboardingCuisine ||
        AppScreen.onboardingDietary ||
        AppScreen.onboardingSkill ||
        AppScreen.splash ||
        AppScreen.gamificationTutorial ||
        AppScreen.creatorCreate ||
        AppScreen.cookMode ||
        AppScreen.eloVoting =>
          true,
        _ => false,
      };

  /// The "skip →" dev shortcut flow map.
  AppScreen? get skipNext => switch (this) {
        AppScreen.auth => AppScreen.profileSetup,
        AppScreen.emailLogin => AppScreen.profileSetup,
        AppScreen.emailSignup => AppScreen.profileSetup,
        AppScreen.profileSetup => AppScreen.onboardingCuisine,
        AppScreen.onboardingCuisine => AppScreen.onboardingDietary,
        AppScreen.onboardingDietary => AppScreen.onboardingSkill,
        AppScreen.onboardingSkill => AppScreen.gamificationTutorial,
        _ => null,
      };

  bool get isAuthOrOnboarding => switch (this) {
        AppScreen.splash ||
        AppScreen.welcome ||
        AppScreen.auth ||
        AppScreen.emailLogin ||
        AppScreen.emailSignup ||
        AppScreen.forgotPassword ||
        AppScreen.profileSetup ||
        AppScreen.onboardingCuisine ||
        AppScreen.onboardingDietary ||
        AppScreen.onboardingSkill ||
        AppScreen.gamificationTutorial =>
          true,
        _ => false,
      };

  bool get showsBottomNav => switch (this) {
        AppScreen.swipeDeck ||
        AppScreen.socialFeed ||
        AppScreen.saved ||
        AppScreen.chatList =>
          true,
        _ => false,
      };
}
