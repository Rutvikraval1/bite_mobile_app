import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_client_provider.dart';

/// Today's chest state for the signed-in user.
@immutable
class DailyChestStatus {
  const DailyChestStatus({
    required this.claimedToday,
    required this.chestStreak,
    required this.nextAt,
  });

  final bool claimedToday;

  /// Consecutive days claimed (0 if the streak is broken).
  final int chestStreak;

  /// When the next chest unlocks (the user's next local midnight).
  final DateTime nextAt;
}

/// Result of [DailyChestService.claim].
@immutable
class DailyChestClaim {
  const DailyChestClaim({
    required this.alreadyClaimed,
    required this.nextAt,
    this.type = 'free',
    this.coins = 0,
    this.streakBonus = 0,
    this.xp = 0,
    this.shard,
    this.chestStreak = 0,
  });

  final bool alreadyClaimed;
  final DateTime nextAt;
  final String type;

  /// Total coins, including [streakBonus].
  final int coins;
  final int streakBonus;
  final int xp;
  final String? shard;
  final int chestStreak;

  bool get premium => type == 'premium';

  factory DailyChestClaim.fromJson(Map<String, dynamic> j) => DailyChestClaim(
        alreadyClaimed: j['already_claimed'] == true,
        nextAt: DateTime.tryParse(j['next_at']?.toString() ?? '')?.toLocal() ??
            DailyChestService.nextLocalMidnight(),
        type: (j['type'] as String?) ?? 'free',
        coins: (j['coins'] as num?)?.toInt() ?? 0,
        streakBonus: (j['streak_bonus'] as num?)?.toInt() ?? 0,
        xp: (j['xp'] as num?)?.toInt() ?? 0,
        shard: j['shard'] as String?,
        chestStreak: (j['chest_streak'] as num?)?.toInt() ?? 0,
      );
}

/// Daily chest backed by the `daily_chest_status` / `claim_daily_chest`
/// RPCs: rewards are rolled and granted on the server, once per local day.
class DailyChestService {
  DailyChestService._();
  static final DailyChestService instance = DailyChestService._();

  /// Null until loaded (or when signed out).
  final ValueNotifier<DailyChestStatus?> status = ValueNotifier(null);

  SupabaseClient get _client => SupabaseClientProvider.instance.client;

  static int get _offsetMin => DateTime.now().timeZoneOffset.inMinutes;

  static DateTime nextLocalMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  /// True when the `daily_chest` migration hasn't been applied.
  static bool isNotSetUp(Object e) =>
      e is PostgrestException &&
      (e.code == 'PGRST202' || e.code == '42883' || e.code == 'PGRST205');

  /// Reloads today's status. Clears it when signed out.
  Future<DailyChestStatus?> refresh() async {
    try {
      // Throws if Supabase isn't initialised (e.g. widget tests).
      if (_client.auth.currentUser == null) {
        status.value = null;
        return null;
      }
      final res = await _client.rpc(
        'daily_chest_status',
        params: {'p_utc_offset_min': _offsetMin},
      );
      final j = (res as Map).cast<String, dynamic>();
      final s = DailyChestStatus(
        claimedToday: j['claimed_today'] == true,
        chestStreak: (j['chest_streak'] as num?)?.toInt() ?? 0,
        nextAt: DateTime.tryParse(j['next_at']?.toString() ?? '')?.toLocal() ??
            nextLocalMidnight(),
      );
      status.value = s;
      return s;
    } catch (e) {
      debugPrint('[chest] status failed: $e');
      return status.value;
    }
  }

  /// Opens today's chest. Throws on network / server errors.
  Future<DailyChestClaim> claim({required bool premium}) async {
    final res = await _client.rpc(
      'claim_daily_chest',
      params: {'p_premium': premium, 'p_utc_offset_min': _offsetMin},
    );
    final result =
        DailyChestClaim.fromJson((res as Map).cast<String, dynamic>());
    final prev = status.value;
    status.value = DailyChestStatus(
      claimedToday: true,
      chestStreak: result.alreadyClaimed
          ? (prev?.chestStreak ?? 0)
          : result.chestStreak,
      nextAt: result.nextAt,
    );
    return result;
  }
}
