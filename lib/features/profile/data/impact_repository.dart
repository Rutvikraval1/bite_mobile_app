import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/table_names.dart';
import '../../../core/network/supabase_client_provider.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// "$12.47", "$48,230".
String formatCents(int cents) {
  final dollars = cents ~/ 100;
  final rest = cents % 100;
  final whole = dollars.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return dollars >= 1000 || rest == 0 ? '\$$whole' : '\$$whole.${rest.toString().padLeft(2, '0')}';
}

/// "96,460" / "3.5M".
String formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  return n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

@immutable
class Charity {
  const Charity({
    required this.id,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.impactLabel,
    required this.centsPerUnit,
    this.totalCents = 0,
  });

  factory Charity.fromJson(Map<String, dynamic> j) => Charity(
        id: _int(j['id']),
        emoji: (j['emoji'] as String?) ?? '💚',
        name: (j['name'] as String?) ?? '',
        desc: (j['description'] as String?) ?? '',
        impactLabel: (j['impact_label'] as String?) ?? '',
        centsPerUnit: _int(j['cents_per_unit']).clamp(1, 1 << 31),
        totalCents: _int(j['total_cents']),
      );

  final int id;
  final String emoji;
  final String name;
  final String desc;
  final String impactLabel;
  final int centsPerUnit;
  final int totalCents;

  int unitsFor(int cents) => cents ~/ centsPerUnit;
}

@immutable
class MyImpact {
  const MyImpact({required this.charity, required this.donatedCents, required this.monthCents});

  final Charity charity;
  final int donatedCents;
  final int monthCents;
}

@immutable
class CommunityImpact {
  const CommunityImpact({required this.mine, required this.totalCents, required this.donors, required this.charities});

  /// Null when the user hasn't chosen a cause.
  final MyImpact? mine;
  final int totalCents;
  final int donors;

  /// Sorted by total donated, highest first.
  final List<Charity> charities;
}

/// Charities (`charities`), the user's chosen cause (`profiles.charity_id`)
/// and donation totals (`community_impact` RPC over `donations`).
class ImpactRepository {
  ImpactRepository({SupabaseClientProvider? provider})
    : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  Future<List<Charity>> fetchCharities() async {
    final rows = await _client
        .from('charities')
        .select('id, emoji, name, description, impact_label, cents_per_unit')
        .eq('active', true)
        .order('sort');
    return [for (final r in rows) Charity.fromJson(r)];
  }

  Future<int?> fetchMyCharityId() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client.from(TableNames.profiles).select('charity_id').eq('id', uid).maybeSingle();
    return (row?['charity_id'] as num?)?.toInt();
  }

  /// [charityId] null clears the choice ("No donation").
  Future<void> setMyCharity(int? charityId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    await _client.from(TableNames.profiles).update({'charity_id': charityId}).eq('id', uid);
  }

  Future<CommunityImpact> fetchImpact() async {
    final j = Map<String, dynamic>.from(await _client.rpc('community_impact') as Map);
    final my = j['my_charity'];
    return CommunityImpact(
      mine: my is Map
          ? MyImpact(
              charity: Charity.fromJson(Map<String, dynamic>.from(my)),
              donatedCents: _int(my['donated_cents']),
              monthCents: _int(my['month_cents']),
            )
          : null,
      totalCents: _int(j['total_cents']),
      donors: _int(j['donors']),
      charities: [
        for (final c in (j['charities'] as List?) ?? const []) Charity.fromJson(Map<String, dynamic>.from(c as Map)),
      ],
    );
  }
}
