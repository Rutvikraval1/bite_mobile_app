import 'package:flutter/foundation.dart';

import '../../content/domain/entities/bite_card.dart';
import '../../content/domain/entities/cook_entry.dart';
import '../../content/domain/entities/saved_item.dart';
import 'genie_filters.dart';

/// A Genie pick plus the human reason it was picked.
@immutable
class GenieSuggestion {
  const GenieSuggestion({required this.card, required this.reason});

  final BiteCard card;
  final String reason;
}

/// Ranks real catalog cards for the signed-in user from their favorite
/// cuisines, saved items and cook history. No AI — a transparent scoring
/// heuristic so every pick can explain itself.
abstract final class GenieSuggestions {
  static List<GenieSuggestion> rank({
    required List<BiteCard> pool,
    List<String> favoriteCuisines = const [],
    List<SavedItem> saved = const [],
    List<CookEntry> cookHistory = const [],
    GenieFilters? filters,
    GenieFilterKind kind = GenieFilterKind.food,
    DateTime? now,
    int limit = 3,
  }) {
    if (pool.isEmpty) return const [];
    final today = now ?? DateTime.now();
    final favs = {for (final c in favoriteCuisines) c.toLowerCase()};
    final savedIds = {for (final s in saved) s.itemId};
    final recentCutoff = today.subtract(const Duration(days: 7));
    final cookedRecently = {
      for (final c in cookHistory)
        if (c.recipeId != null && c.cookedAt.isAfter(recentCutoff)) c.recipeId!,
    };
    final cookedEver = {
      for (final c in cookHistory)
        if (c.recipeId != null) c.recipeId!,
    };
    // Cuisines the user actually cooks count as soft preferences too.
    final cookedCuisines = <String>{};
    for (final c in cookHistory) {
      final id = c.recipeId;
      if (id == null) continue;
      for (final card in pool) {
        if (card.id == id) cookedCuisines.add(card.cuisine.toLowerCase());
      }
    }
    final daySeed = today.year * 1000 + _dayOfYear(today);

    final candidates = filters == null || filters.isEmpty
        ? pool
        : filters.apply(pool, kind);

    final scored = <({BiteCard card, double score, String reason})>[];
    for (final card in candidates) {
      if (card.isDraft) continue;
      var score = 0.0;
      var reason = '';
      var reasonWeight = 0.0;
      void add(double w, String why) {
        score += w;
        if (w > reasonWeight) {
          reasonWeight = w;
          reason = why;
        }
      }

      final cuisine = card.cuisine.toLowerCase();
      if (savedIds.contains(card.id) && !cookedEver.contains(card.id)) {
        add(3.5, 'You saved this — time to make it');
      }
      if (cuisine.isNotEmpty && favs.contains(cuisine)) {
        add(3, 'Because you love ${card.cuisine}');
      } else if (cuisine.isNotEmpty && cookedCuisines.contains(cuisine)) {
        add(2, 'You cook a lot of ${card.cuisine}');
      }
      final mins = GenieFilters.minutesOf(card);
      if (mins != null && mins <= 20) add(1.2, 'Ready in $mins min');
      final popularity = _parseCount(card.hearts);
      if (popularity >= 5000) {
        add(1, 'Trending — ${card.hearts} ❤️');
      } else {
        score += popularity / 10000;
      }
      if (cookedRecently.contains(card.id)) score -= 5;
      if (filters != null && !filters.isEmpty && reason.isEmpty) {
        reason = 'Matches your Genie filters';
      }
      // Stable per-day jitter so picks rotate without flickering.
      score += ((card.id * 2654435761 + daySeed) % 1000) / 2000;
      scored.add((
        card: card,
        score: score,
        reason: reason.isEmpty ? 'Something new to try' : reason,
      ));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return [
      for (final s in scored.take(limit))
        GenieSuggestion(card: s.card, reason: s.reason),
    ];
  }

  /// Places ranked by rating (open ones first), favoring loved cuisines.
  static List<GenieSuggestion> rankPlaces({
    required List<BiteCard> places,
    List<String> favoriteCuisines = const [],
    int limit = 3,
  }) {
    final favs = {for (final c in favoriteCuisines) c.toLowerCase()};
    bool loved(BiteCard p) =>
        favs.any((f) => p.cuisine.toLowerCase().contains(f));
    bool open(BiteCard p) => (p.status ?? '').toLowerCase().contains('open') &&
        !(p.status ?? '').toLowerCase().contains('closed');
    final sorted = [...places]
      ..sort((a, b) {
        double score(BiteCard p) =>
            (p.rating ?? 0) + (open(p) ? 1 : 0) + (loved(p) ? 0.5 : 0);
        return score(b).compareTo(score(a));
      });
    return [
      for (final p in sorted.take(limit))
        GenieSuggestion(
          card: p,
          reason: loved(p)
              ? 'You love ${p.cuisine.split('·').first.trim()}'
              : p.rating != null
              ? '★ ${p.rating!.toStringAsFixed(1)}'
                    '${p.distance != null ? ' · ${p.distance}' : ''}'
              : (p.distance ?? 'Nearby'),
        ),
    ];
  }

  /// Parses display counts like "2.4K", "890", "1.1M".
  static double _parseCount(String s) {
    final t = s.trim().toUpperCase();
    final m = RegExp(r'^([\d.]+)\s*([KM]?)').firstMatch(t);
    if (m == null) return 0;
    final n = double.tryParse(m.group(1)!) ?? 0;
    return switch (m.group(2)) {
      'K' => n * 1000,
      'M' => n * 1000000,
      _ => n,
    };
  }

  static int _dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year)).inDays + 1;
}
