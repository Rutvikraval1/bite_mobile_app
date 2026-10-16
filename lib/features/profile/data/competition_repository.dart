import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/table_names.dart';
import '../../../core/network/supabase_client_provider.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

DateTime? _date(Object? v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();

Color _hex(String? hex, Color fallback) {
  final h = (hex ?? '').replaceFirst('#', '');
  final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return v == null ? fallback : Color(v);
}

/// "2d 4h", "5h 12m", "8m" — time left until [end], or "ended".
String timeLeft(DateTime? end) {
  if (end == null) return '';
  final d = end.difference(DateTime.now());
  if (d.isNegative) return 'ended';
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  return '${d.inMinutes.clamp(1, 59)}m';
}

/// A user as shown on competition and cook-off cards.
@immutable
class CompUser {
  const CompUser({required this.id, required this.handle, required this.avatarEmoji, this.avatarUrl});

  factory CompUser.fromJson(Map<String, dynamic> j) => CompUser(
        id: j['id']?.toString() ?? '',
        handle: (j['handle'] as String?) ?? '@cook',
        avatarEmoji: (j['avatar_emoji'] as String?) ?? '🧑‍🍳',
        avatarUrl: j['avatar_url'] as String?,
      );

  final String id;
  final String handle;
  final String avatarEmoji;
  final String? avatarUrl;
}

@immutable
class CompPrize {
  const CompPrize(this.place, this.prize);
  final String place;
  final String prize;
}

@immutable
class Competition {
  const Competition({
    required this.id,
    required this.title,
    required this.emoji,
    required this.sponsor,
    required this.theme,
    required this.prizes,
    required this.entryCoins,
    required this.endsAt,
    required this.entrants,
    required this.entered,
    required this.avatarUrls,
  });

  factory Competition.fromJson(Map<String, dynamic> j) => Competition(
        id: j['id'].toString(),
        title: (j['title'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '🏆',
        sponsor: j['sponsor'] as String?,
        theme: (j['theme'] as String?) ?? '',
        prizes: [
          for (final p in (j['prizes'] as List?) ?? const [])
            if (p is Map) CompPrize(p['place']?.toString() ?? '', p['prize']?.toString() ?? ''),
        ],
        entryCoins: _int(j['entry_coins']),
        endsAt: _date(j['ends_at']),
        entrants: _int(j['entrants']),
        entered: j['entered'] == true,
        avatarUrls: [for (final a in (j['avatars'] as List?) ?? const []) a.toString()],
      );

  final String id;
  final String title;
  final String emoji;
  final String? sponsor;
  final String theme;
  final List<CompPrize> prizes;
  final int entryCoins;
  final DateTime? endsAt;
  final int entrants;
  final bool entered;
  final List<String> avatarUrls;
}

@immutable
class CompetitionTier {
  const CompetitionTier({
    required this.id,
    required this.label,
    required this.icon,
    required this.desc,
    required this.info,
    required this.requirement,
    required this.color,
    required this.minCooks,
    required this.comps,
  });

  factory CompetitionTier.fromJson(Map<String, dynamic> j) => CompetitionTier(
        id: j['id'].toString(),
        label: (j['label'] as String?) ?? '',
        icon: (j['icon'] as String?) ?? '🏆',
        desc: (j['description'] as String?) ?? '',
        info: (j['info'] as String?) ?? '',
        requirement: j['requirement'] as String?,
        color: _hex(j['color'] as String?, const Color(0xFF4CAF50)),
        minCooks: _int(j['min_cooks']),
        comps: [
          for (final c in (j['competitions'] as List?) ?? const [])
            Competition.fromJson(Map<String, dynamic>.from(c as Map)),
        ],
      );

  final String id;
  final String label;
  final String icon;
  final String desc;
  final String info;
  final String? requirement;
  final Color color;
  final int minCooks;
  final List<Competition> comps;

  /// "Free" or "100 Coins OR 10+ cooks", from the tier rule.
  String entryLabel(Competition c) {
    if (minCooks == 0 || c.entryCoins == 0) return 'Free';
    return '${c.entryCoins} Coins OR $minCooks+ cooks';
  }
}

@immutable
class CompetitionBoard {
  const CompetitionBoard({required this.tiers, required this.cookedCount});

  final List<CompetitionTier> tiers;
  final int cookedCount;
}

/// A dish from the user's `cook_history`, used to enter competitions and
/// start cook-offs.
@immutable
class CookedDish {
  const CookedDish({required this.id, required this.title, required this.emoji, this.imageUrl});

  final String id;
  final String title;
  final String emoji;
  final String? imageUrl;
}

@immutable
class EloEntry {
  const EloEntry({
    required this.id,
    required this.title,
    required this.emoji,
    required this.imageUrl,
    required this.elo,
    required this.mine,
    required this.creator,
  });

  factory EloEntry.fromJson(Map<String, dynamic> j) => EloEntry(
        id: j['id'].toString(),
        title: (j['title'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '🍽',
        imageUrl: j['image_url'] as String?,
        elo: _int(j['elo']),
        mine: j['mine'] == true,
        creator: CompUser.fromJson(Map<String, dynamic>.from((j['creator'] as Map?) ?? const {})),
      );

  final String id;
  final String title;
  final String emoji;
  final String? imageUrl;
  final int elo;
  final bool mine;
  final CompUser creator;

  EloEntry withElo(int value) =>
      EloEntry(id: id, title: title, emoji: emoji, imageUrl: imageUrl, elo: value, mine: mine, creator: creator);

  /// Stable card gradient derived from the id (entries have no colour column).
  List<Color> get gradient {
    const palettes = [
      [Color(0xFF3D1C00), Color(0xFF8B4513), Color(0xFFCD853F)],
      [Color(0xFF2D0000), Color(0xFF8B0000), Color(0xFFFF6347)],
      [Color(0xFF331A00), Color(0xFFFF8C00), Color(0xFFFFA500)],
      [Color(0xFF001A1A), Color(0x884ECDC4), Color(0xFF4ECDC4)],
      [Color(0xFF1A0000), Color(0xFFB22222), Color(0xFFDC143C)],
      [Color(0xFF001A00), Color(0xFF228B22), Color(0xFF32CD32)],
    ];
    return palettes[id.hashCode.abs() % palettes.length];
  }
}

@immutable
class EloBoard {
  const EloBoard({required this.entries, required this.votesToday, required this.dailyCap});

  final List<EloEntry> entries;
  final int votesToday;
  final int dailyCap;
}

@immutable
class EloVoteResult {
  const EloVoteResult({required this.capped, required this.votesToday, this.winnerElo, this.loserElo, this.newXp});

  final bool capped;
  final int votesToday;
  final int? winnerElo;
  final int? loserElo;
  final int? newXp;
}

@immutable
class CookOff {
  const CookOff({
    required this.id,
    required this.recipeTitle,
    required this.emoji,
    required this.difficulty,
    required this.note,
    required this.cookHours,
    required this.status,
    required this.openUntil,
    required this.cookDeadline,
    required this.votingEndsAt,
    required this.defender,
    required this.challenger,
    required this.votesDefender,
    required this.votesChallenger,
    required this.myVote,
    required this.mine,
  });

  factory CookOff.fromJson(Map<String, dynamic> j) => CookOff(
        id: j['id'].toString(),
        recipeTitle: (j['recipe_title'] as String?) ?? '',
        emoji: (j['emoji'] as String?) ?? '🍽',
        difficulty: (j['difficulty'] as String?) ?? 'Medium',
        note: (j['note'] as String?) ?? '',
        cookHours: _int(j['cook_hours']),
        status: (j['status'] as String?) ?? 'open',
        openUntil: _date(j['open_until']),
        cookDeadline: _date(j['cook_deadline']),
        votingEndsAt: _date(j['voting_ends_at']),
        defender: CompUser.fromJson(Map<String, dynamic>.from((j['defender'] as Map?) ?? const {})),
        challenger: j['challenger'] is Map ? CompUser.fromJson(Map<String, dynamic>.from(j['challenger'] as Map)) : null,
        votesDefender: _int(j['votes_defender']),
        votesChallenger: _int(j['votes_challenger']),
        myVote: j['my_vote'] as String?,
        mine: j['mine'] == true,
      );

  final String id;
  final String recipeTitle;
  final String emoji;
  final String difficulty;
  final String note;
  final int cookHours;

  /// open | expired | cooking | voting | done
  final String status;
  final DateTime? openUntil;
  final DateTime? cookDeadline;
  final DateTime? votingEndsAt;
  final CompUser defender;
  final CompUser? challenger;
  final int votesDefender;
  final int votesChallenger;

  /// challenger | defender | null
  final String? myVote;
  final bool mine;
}

@immutable
class CookOffBoard {
  const CookOffBoard({required this.active, required this.open, required this.mine});

  final List<CookOff> active;
  final List<CookOff> open;
  final List<CookOff> mine;
}

/// Holds which competition [EloVotingScreen] should rate — set by the
/// Competition screen before navigating there.
class CompetitionSelection {
  CompetitionSelection._();

  static final CompetitionSelection instance = CompetitionSelection._();

  ({String id, String title, String emoji})? current;
}

/// Competitions, Elo voting and cook-offs. All writes go through RPCs in
/// `20261016120000_competitions_elo_impact.sql`, so rules (entry cost,
/// daily vote cap, Elo maths, XP) are enforced on the server.
class CompetitionRepository {
  CompetitionRepository({SupabaseClientProvider? provider})
    : _provider = provider ?? SupabaseClientProvider.instance;

  final SupabaseClientProvider _provider;

  SupabaseClient get _client => _provider.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<Map<String, dynamic>> _rpc(String fn, [Map<String, dynamic>? params]) async {
    final res = await _client.rpc(fn, params: params);
    return Map<String, dynamic>.from(res as Map);
  }

  List<CookOff> _cookOffs(Object? list) =>
      [for (final c in (list as List?) ?? const []) CookOff.fromJson(Map<String, dynamic>.from(c as Map))];

  Future<CompetitionBoard> fetchBoard() async {
    final j = await _rpc('competition_board');
    return CompetitionBoard(
      cookedCount: _int(j['cooked_count']),
      tiers: [
        for (final t in (j['tiers'] as List?) ?? const [])
          CompetitionTier.fromJson(Map<String, dynamic>.from(t as Map)),
      ],
    );
  }

  /// The signed-in user's cooked dishes, newest first, one per title.
  Future<List<CookedDish>> fetchCookedDishes() async {
    final uid = currentUserId;
    if (uid == null) return const [];
    final rows = await _client
        .from(TableNames.cookHistory)
        .select('id, title, emoji, image_url')
        .eq('user_id', uid)
        .order('cooked_at', ascending: false)
        .limit(60);
    final seen = <String>{};
    return [
      for (final r in rows)
        if (seen.add((r['title'] as String? ?? '').toLowerCase()))
          CookedDish(
            id: r['id'].toString(),
            title: (r['title'] as String?) ?? '',
            emoji: (r['emoji'] as String?) ?? '🍽',
            imageUrl: r['image_url'] as String?,
          ),
    ];
  }

  /// Returns the user's coin balance after any entry fee.
  Future<({bool alreadyEntered, int coinsPaid, int? newCoins})> enter(String competitionId, String dishId) async {
    final j = await _rpc('enter_competition', {'p_competition_id': competitionId, 'p_cook_history_id': dishId});
    return (
      alreadyEntered: j['already_entered'] == true,
      coinsPaid: _int(j['coins_paid']),
      newCoins: (j['new_coins'] as num?)?.toInt(),
    );
  }

  Future<EloBoard> fetchEloBoard(String competitionId) async {
    final j = await _rpc('elo_board', {'p_competition_id': competitionId});
    return EloBoard(
      votesToday: _int(j['votes_today']),
      dailyCap: _int(j['daily_cap']),
      entries: [
        for (final e in (j['entries'] as List?) ?? const [])
          EloEntry.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }

  Future<EloVoteResult> castEloVote({required String winnerId, required String loserId}) async {
    final j = await _rpc('cast_elo_vote', {'p_winner': winnerId, 'p_loser': loserId});
    return EloVoteResult(
      capped: j['capped'] == true,
      votesToday: _int(j['votes_today']),
      winnerElo: (j['winner_elo'] as num?)?.toInt(),
      loserElo: (j['loser_elo'] as num?)?.toInt(),
      newXp: (j['new_xp'] as num?)?.toInt(),
    );
  }

  Future<CookOffBoard> fetchCookOffs() async {
    final j = await _rpc('cook_off_board');
    return CookOffBoard(active: _cookOffs(j['active']), open: _cookOffs(j['open']), mine: _cookOffs(j['mine']));
  }

  Future<void> startCookOff({required String dishId, required String difficulty, required String note}) =>
      _client.rpc('start_cook_off', params: {
        'p_cook_history_id': dishId,
        'p_difficulty': difficulty,
        'p_note': note,
      });

  Future<CookOff> acceptCookOff(String id) async =>
      CookOff.fromJson(await _rpc('accept_cook_off', {'p_cook_off_id': id}));

  /// [side] is `challenger` or `defender`.
  Future<CookOff> voteCookOff(String id, String side) async =>
      CookOff.fromJson(await _rpc('vote_cook_off', {'p_cook_off_id': id, 'p_side': side}));

  /// True when the competitions migration hasn't been applied.
  static bool isMissingBackend(Object e) =>
      e is PostgrestException && (e.code == 'PGRST202' || e.code == 'PGRST205' || e.code == '42P01' || e.code == '42883');

  /// Short user-facing message for an RPC error (`raise exception '…'`).
  static String messageFor(Object e) {
    final raw = e is PostgrestException ? e.message : e.toString();
    if (isMissingBackend(e)) return 'Competitions aren’t set up on the server yet.';
    return switch (raw) {
      'not_enough_coins' => "You don't have enough b🌶te Coins for this entry.",
      'requirement_not_met' => "You don't meet this tier's requirement yet.",
      'competition_closed' => 'This competition is closed.',
      'dish_not_found' => 'Pick a dish from your cooked history.',
      'own_entry' => "You can't vote on your own entry.",
      'own_cook_off' => "That's your own cook-off.",
      'already_taken' => 'Someone already accepted this challenge.',
      'cook_off_expired' => 'This challenge has expired.',
      'not_voting' => 'Voting is not open for this cook-off.',
      'not_authenticated' => 'Sign in to take part.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
