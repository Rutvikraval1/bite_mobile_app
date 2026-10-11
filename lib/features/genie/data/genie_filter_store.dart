import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/table_names.dart';
import '../../../core/network/supabase_client_provider.dart';
import '../../../core/state/app_state.dart';
import '../../content/domain/entities/bite_card.dart';
import '../domain/genie_filters.dart';

/// Result of loading a user's saved Genie filters.
class GenieFiltersSnapshot {
  const GenieFiltersSnapshot({
    required this.byKind,
    required this.hasSaved,
    this.fromCache = false,
  });

  final Map<GenieFilterKind, GenieFilters> byKind;

  /// False when the user has never saved filters (UI may seed defaults).
  final bool hasSaved;

  /// True when the DB was unreachable and the device cache was used.
  final bool fromCache;

  GenieFilters of(GenieFilterKind kind) =>
      byKind[kind] ?? GenieFilters.empty;
}

/// Persists Genie filters to `profiles.genie_filters` (jsonb, one object per
/// deck kind) with a shared_preferences copy as an offline fallback, and
/// holds the filters currently applied to the swipe deck.
///
/// Filters are applied to the deck only after the user taps "Show" in the
/// filter sheet during this session, so a fresh launch always opens on the
/// full deck; the saved selections are restored when the sheet is reopened.
class GenieFilterStore {
  GenieFilterStore._();

  static final GenieFilterStore instance = GenieFilterStore._();

  static const String _column = 'genie_filters';
  static const String _cachePrefix = 'genie_filters_';

  /// Filters currently narrowing the swipe deck, by kind.
  final ValueNotifier<Map<GenieFilterKind, GenieFilters>> applied =
      ValueNotifier(const {});

  /// User the [applied] filters belong to.
  String? _appliedFor;

  static GenieFilterKind? kindFor(DeckTab tab) => switch (tab) {
    DeckTab.food => GenieFilterKind.food,
    DeckTab.drinks => GenieFilterKind.drinks,
    DeckTab.places => null,
  };

  /// Filters applied to [tab]'s deck, or null when none are active.
  GenieFilters? appliedFor(DeckTab tab) {
    final kind = kindFor(tab);
    if (kind == null || !_belongsToCurrentUser()) return null;
    final f = applied.value[kind];
    return f == null || f.isEmpty ? null : f;
  }

  /// Narrows [cards] with the filters applied to [tab]'s deck, if any.
  List<BiteCard> applyTo(DeckTab tab, List<BiteCard> cards) {
    final f = appliedFor(tab);
    final kind = kindFor(tab);
    if (f == null || kind == null) return cards;
    return f.apply(cards, kind);
  }

  void activate(String? userId, GenieFilterKind kind, GenieFilters filters) {
    _appliedFor = userId;
    applied.value = {...applied.value, kind: filters};
  }

  void deactivate(GenieFilterKind kind) {
    if (!applied.value.containsKey(kind)) return;
    applied.value = {...applied.value}..remove(kind);
  }

  bool _belongsToCurrentUser() {
    if (applied.value.isEmpty) return false;
    final current = _currentUserId();
    if (current != _appliedFor) {
      // Another account signed in — drop the previous user's filters.
      _appliedFor = null;
      applied.value = const {};
      return false;
    }
    return true;
  }

  static String? _currentUserId() {
    final provider = SupabaseClientProvider.instance;
    if (!provider.isInitialized) return null;
    try {
      return provider.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  // ── Persistence ──

  Future<GenieFiltersSnapshot> load(String? userId) async {
    if (userId != null && SupabaseClientProvider.instance.isInitialized) {
      try {
        final row = await SupabaseClientProvider.instance.client
            .from(TableNames.profiles)
            .select(_column)
            .eq('id', userId)
            .maybeSingle();
        final raw = row?[_column];
        final snapshot = _decode(raw is Map ? raw.cast<String, dynamic>() : null);
        await _writeCache(userId, raw is Map ? raw.cast<String, dynamic>() : null);
        return snapshot;
      } catch (e) {
        debugPrint('[genie] load filters failed, using cache: $e');
      }
    }
    final cached = await _readCache(userId);
    final snapshot = _decode(cached);
    return GenieFiltersSnapshot(
      byKind: snapshot.byKind,
      hasSaved: snapshot.hasSaved,
      fromCache: userId != null,
    );
  }

  /// Saves [filters] for [kind], keeping the other kind's saved filters.
  /// Returns an error message when the DB write failed (the device cache
  /// is still updated so the selection isn't lost).
  Future<String?> save(
    String? userId,
    GenieFilterKind kind,
    GenieFilters filters,
    GenieFiltersSnapshot current,
  ) async {
    final byKind = {...current.byKind, kind: filters};
    final json = _encode(byKind);
    await _writeCache(userId, json);
    if (userId == null) return 'Sign in to sync filters across devices';
    return _writeDb(userId, json);
  }

  /// Clears [kind]'s saved filters in the DB (and the whole column when no
  /// other kind has filters left).
  Future<String?> reset(
    String? userId,
    GenieFilterKind kind,
    GenieFiltersSnapshot current,
  ) async {
    deactivate(kind);
    final byKind = {...current.byKind}..remove(kind);
    final remaining = byKind.values.any((f) => !f.isEmpty);
    final json = remaining ? _encode(byKind) : null;
    await _writeCache(userId, json);
    if (userId == null) return null;
    return _writeDb(userId, json);
  }

  Future<String?> _writeDb(String userId, Map<String, dynamic>? json) async {
    if (!SupabaseClientProvider.instance.isInitialized) {
      return 'Offline — saved on this device';
    }
    try {
      await SupabaseClientProvider.instance.client
          .from(TableNames.profiles)
          .update({
            _column: json,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId);
      return null;
    } on PostgrestException catch (e) {
      debugPrint('[genie] save filters failed: ${e.code} ${e.message}');
      return e.code == 'PGRST204' || e.code == '42703'
          ? 'Database is out of date — run the latest Supabase migration'
          : 'Saved on this device — couldn’t sync';
    } catch (e) {
      debugPrint('[genie] save filters failed: $e');
      return 'Saved on this device — couldn’t sync';
    }
  }

  static Map<String, dynamic> _encode(Map<GenieFilterKind, GenieFilters> m) => {
    for (final e in m.entries)
      if (!e.value.isEmpty) e.key.name: e.value.toJson(),
  };

  static GenieFiltersSnapshot _decode(Map<String, dynamic>? json) {
    if (json == null) {
      return const GenieFiltersSnapshot(byKind: {}, hasSaved: false);
    }
    final byKind = <GenieFilterKind, GenieFilters>{};
    for (final kind in GenieFilterKind.values) {
      final raw = json[kind.name];
      if (raw is Map) {
        byKind[kind] = GenieFilters.fromJson(raw.cast<String, dynamic>());
      }
    }
    return GenieFiltersSnapshot(byKind: byKind, hasSaved: true);
  }

  static String _cacheKey(String? userId) => '$_cachePrefix${userId ?? 'guest'}';

  Future<Map<String, dynamic>?> _readCache(String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(userId));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } catch (e) {
      debugPrint('[genie] read filter cache failed: $e');
      return null;
    }
  }

  Future<void> _writeCache(String? userId, Map<String, dynamic>? json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (json == null) {
        await prefs.remove(_cacheKey(userId));
      } else {
        await prefs.setString(_cacheKey(userId), jsonEncode(json));
      }
    } catch (e) {
      debugPrint('[genie] write filter cache failed: $e');
    }
  }
}
