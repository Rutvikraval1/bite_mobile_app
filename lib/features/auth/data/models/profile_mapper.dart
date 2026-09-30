import '../../domain/entities/profile.dart';

/// Converts between `profiles` table rows and [Profile] entities.
abstract final class ProfileMapper {
  static Map<String, dynamic> toMap(Profile profile) => {
        if (profile.displayName.isNotEmpty) 'display_name': profile.displayName,
        if (profile.username.isNotEmpty) 'username': profile.username,
        if (profile.bio.isNotEmpty) 'bio': profile.bio,
        if (profile.avatarEmoji.isNotEmpty) 'avatar_emoji': profile.avatarEmoji,
        if (profile.dob != null)
          'dob': profile.dob!.toIso8601String().split('T').first,
        'xp': profile.xp,
        'bite_coins': profile.biteCoins,
        'streak_count': profile.streakCount,
        'longest_streak': profile.longestStreak,
        'streak_multiplier': profile.streakMultiplier,
        'streak_freezes': profile.streakFreezes,
        'daily_chest_claimed': profile.dailyChestClaimed,
        'is_premium': profile.isPremium,
        'user_tier': profile.userTier,
        'cuisines': profile.cuisines,
        'dietary': profile.dietary,
        'badges': profile.badges,
        'age_verified': profile.ageVerified,
        'location_granted': profile.locationGranted,
        if (profile.cookingSkill != null) 'cooking_skill': profile.cookingSkill,
        if (profile.cookingGoal != null) 'cooking_goal': profile.cookingGoal,
      };

  static Profile fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      displayName: (map['display_name'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      bio: (map['bio'] as String?) ?? '',
      avatarEmoji: (map['avatar_emoji'] as String?) ?? '🧑‍🍳',
      dob: map['dob'] != null ? DateTime.tryParse(map['dob'].toString()) : null,
      xp: (map['xp'] as num?)?.toInt() ?? 0,
      biteCoins: (map['bite_coins'] as num?)?.toInt() ?? 0,
      streakCount: (map['streak_count'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longest_streak'] as num?)?.toInt() ?? 0,
      streakMultiplier: ((map['streak_multiplier'] as num?) ?? 1.0).toDouble(),
      streakFreezes: (map['streak_freezes'] as num?)?.toInt() ?? 0,
      dailyChestClaimed: (map['daily_chest_claimed'] as bool?) ?? false,
      isPremium: (map['is_premium'] as bool?) ?? false,
      userTier: (map['user_tier'] as String?) ?? 'free',
      cuisines: _strings(map['cuisines']),
      dietary: _strings(map['dietary']),
      badges: _strings(map['badges']),
      ageVerified: (map['age_verified'] as bool?) ?? false,
      locationGranted: (map['location_granted'] as bool?) ?? false,
      cookingSkill: map['cooking_skill'] as String?,
      cookingGoal: map['cooking_goal'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// Eagerly filters to strings so a null/odd array element can't throw
  /// later (a lazy `.cast<String>()` fails on first read, outside any try).
  static List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  /// Default row used when creating a minimal profile.
  static Map<String, dynamic> initialMap(String userId) => {
        'id': userId,
        'display_name': '',
        'username': '',
        'bio': '',
        'avatar_emoji': '',
        'xp': 0,
        'bite_coins': 0,
        'streak_count': 0,
        'longest_streak': 0,
        'streak_multiplier': 1.0,
        'streak_freezes': 0,
        'daily_chest_claimed': false,
        'is_premium': false,
        'user_tier': 'free',
        'cuisines': const <String>[],
        'dietary': const <String>[],
        'badges': const <String>[],
        'age_verified': false,
        'location_granted': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
}
