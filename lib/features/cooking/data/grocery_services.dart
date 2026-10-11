import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/toast_service.dart';

/// A grocery delivery service we can hand a shopping list to. There is no
/// cart API integration — we open the service's own search for the missing
/// items and the user completes the order there.
class GroceryService {
  const GroceryService({
    required this.key,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.color,
    required this.searchUrl,
  });

  final String key;
  final String emoji;
  final String name;
  final String desc;
  final Color color;

  /// Builds the search URL for an already-encoded query.
  final Uri Function(String query) searchUrl;

  static final List<GroceryService> all = [
    GroceryService(
      key: 'instacart',
      emoji: '🛒',
      name: 'Instacart',
      desc: 'Search your missing items on Instacart',
      color: const Color(0xFF66BB6A),
      searchUrl: (q) => Uri.https('www.instacart.com', '/store/s', {'k': q}),
    ),
    GroceryService(
      key: 'amazonfresh',
      emoji: '📦',
      name: 'Amazon Fresh',
      desc: 'Search your missing items on Amazon Fresh',
      color: const Color(0xFFFF9900),
      searchUrl: (q) =>
          Uri.https('www.amazon.com', '/s', {'k': q, 'i': 'amazonfresh'}),
    ),
    GroceryService(
      key: 'walmart',
      emoji: '🔵',
      name: 'Walmart',
      desc: 'Search your missing items on Walmart',
      color: const Color(0xFF0071CE),
      searchUrl: (q) => Uri.https('www.walmart.com', '/search', {'q': q}),
    ),
  ];

  /// Opens this service in the browser / its app, searching for [items]
  /// (ingredient names). Shows an honest toast either way.
  Future<bool> open(List<String> items) async {
    final query = searchQuery(items);
    if (query.isEmpty) {
      ToastService.instance.show('🛒 Nothing missing to search for');
      return false;
    }
    ToastService.instance.show('🛒 Opening $name…');
    try {
      final ok = await launchUrl(
        searchUrl(query),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) ToastService.instance.show("⚠️ Couldn't open $name.");
      return ok;
    } catch (e) {
      debugPrint('[grocery] launch $key failed: $e');
      ToastService.instance.show("⚠️ Couldn't open $name.");
      return false;
    }
  }

  /// "2 cups jasmine rice" → "jasmine rice"; de-duplicated, comma-joined.
  static String searchQuery(List<String> items) {
    final seen = <String>{};
    final names = <String>[];
    for (final raw in items) {
      final name = ingredientName(raw);
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      names.add(name);
    }
    return names.join(', ');
  }

  static final RegExp _qtyPrefix = RegExp(
    r'^\s*(?:[\d½¼¾⅓⅔⅛.,/\s-]+)?\s*'
    r'(?:(?:g|kg|ml|l|oz|lb|lbs|cups?|tsp|tbsp|pinch(?:es)?|cloves?|slices?|cans?|dash(?:es)?|bunch(?:es)?)\.?\s+)?'
    r'(?:of\s+)?',
    caseSensitive: false,
  );

  /// Strips a leading quantity / unit and any trailing ", prep note".
  static String ingredientName(String line) {
    var s = line.replaceFirst(_qtyPrefix, '').trim();
    final comma = s.indexOf(',');
    if (comma > 0) s = s.substring(0, comma).trim();
    final paren = s.indexOf('(');
    if (paren > 0) s = s.substring(0, paren).trim();
    return s;
  }
}
