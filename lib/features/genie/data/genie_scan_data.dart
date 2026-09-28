/// Canned "detected ingredients" result for the fake recipe-scanner flow.
///
/// There is no camera/ML plugin in this project (see `pubspec.yaml`) and no
/// real vision backend, so `GenieScanScreen` simulates a scan → result flow
/// with a short fake delay and this fabricated but plausible result —
/// mirrors the prototype's static "🧞 4 found" detection card.
abstract final class GenieScanData {
  GenieScanData._();

  static const List<String> detectedIngredients = [
    '🍅 Tomatoes',
    '🌿 Basil',
    '🍗 Chicken',
    '🧅 Onion',
  ];

  static const String identifiedDish = 'Thai Basil Chicken';
}
