/// Cross-screen handoff for the Cook Mode → Post Cook flow.
///
/// The prototype smuggles ephemeral session data (pace ratio, which dish was
/// being cooked) across screens via `window.__bitePace`. Screens in this app
/// are re-created with no constructor arguments and the shared `AppState`
/// must not be touched by this phase, so this singleton plays the same role
/// scoped entirely to the cooking feature.
class CookSession {
  CookSession._();

  static final CookSession instance = CookSession._();

  /// Ratio of actual time spent vs. the target time. <1 means finished
  /// early, ~1 means on pace, >1.3 means ran over.
  double paceRatio = 1.0;

  /// Title of the dish being cooked, captured when Cook Mode starts so
  /// Post Cook can reference it even if the active card changes later.
  String dishTitle = 'this recipe';

  String creator = '@chefpriya';

  bool isDrink = false;

  /// Heat level (0-3) of the dish, used to gate the "Spice Seeker" badge.
  int heat = 0;
}
