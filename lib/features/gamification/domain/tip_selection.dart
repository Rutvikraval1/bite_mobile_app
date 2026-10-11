/// Hands the creator being tipped (and a preselected amount) to
/// `TipFlowScreen`, which the router builds with no constructor args. Set
/// right before navigating to `AppScreen.tipFlow` (Creator Profile → Tip,
/// Post Cook → Send tip).
class TipSelection {
  TipSelection._();

  static final TipSelection instance = TipSelection._();

  String? handle;
  String? emoji;
  String? tagline;

  /// Preselected tip in dollars (may be a custom amount).
  int? amount;

  void select({required String handle, String? emoji, String? tagline, int? amount}) {
    this.handle = handle;
    this.emoji = emoji;
    this.tagline = tagline;
    this.amount = amount;
  }
}
