/// A user's app profile — mirrors the `profiles` table.
class Profile {
  const Profile({
    required this.id,
    this.displayName = '',
    this.username = '',
    this.bio = '',
    this.avatarEmoji = '🧑‍🍳',
    this.avatarUrl,
    this.dob,
    this.xp = 0,
    this.biteCoins = 0,
    this.streakCount = 0,
    this.longestStreak = 0,
    this.streakMultiplier = 1.0,
    this.streakFreezes = 0,
    this.dailyChestClaimed = false,
    this.isPremium = false,
    this.userTier = 'free',
    this.cuisines = const [],
    this.dietary = const [],
    this.badges = const [],
    this.ageVerified = false,
    this.locationGranted = false,
    this.cookingSkill,
    this.cookingGoal,
    this.cookedCount = 0,
    this.pushEnabled = true,
    this.mealRemindersEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String displayName;
  final String username;
  final String bio;
  final String avatarEmoji;

  /// Uploaded profile photo (Supabase Storage `avatars` bucket). Takes
  /// precedence over [avatarEmoji] wherever the avatar is shown.
  final String? avatarUrl;
  final DateTime? dob;
  final int xp;
  final int biteCoins;
  final int streakCount;
  final int longestStreak;
  final double streakMultiplier;
  final int streakFreezes;
  final bool dailyChestClaimed;
  final bool isPremium;
  final String userTier;
  final List<String> cuisines;
  final List<String> dietary;
  final List<String> badges;
  final bool ageVerified;
  final bool locationGranted;
  final String? cookingSkill;
  final String? cookingGoal;

  /// Number of rows in `cook_history` (kept in sync by a DB trigger).
  final int cookedCount;
  final bool pushEnabled;
  final bool mealRemindersEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get age {
    final d = dob;
    if (d == null) return 0;
    return DateTime.now().year - d.year;
  }

  bool get isProfileComplete =>
      displayName.trim().length >= 2 && username.trim().length >= 3;

  Profile copyWith({
    String? displayName,
    String? username,
    String? bio,
    String? avatarEmoji,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    DateTime? dob,
    int? xp,
    int? biteCoins,
    int? streakCount,
    int? longestStreak,
    double? streakMultiplier,
    int? streakFreezes,
    bool? dailyChestClaimed,
    bool? isPremium,
    String? userTier,
    List<String>? cuisines,
    List<String>? dietary,
    List<String>? badges,
    bool? ageVerified,
    bool? locationGranted,
    String? cookingSkill,
    String? cookingGoal,
    int? cookedCount,
    bool? pushEnabled,
    bool? mealRemindersEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
      dob: dob ?? this.dob,
      xp: xp ?? this.xp,
      biteCoins: biteCoins ?? this.biteCoins,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      streakMultiplier: streakMultiplier ?? this.streakMultiplier,
      streakFreezes: streakFreezes ?? this.streakFreezes,
      dailyChestClaimed: dailyChestClaimed ?? this.dailyChestClaimed,
      isPremium: isPremium ?? this.isPremium,
      userTier: userTier ?? this.userTier,
      cuisines: cuisines ?? this.cuisines,
      dietary: dietary ?? this.dietary,
      badges: badges ?? this.badges,
      ageVerified: ageVerified ?? this.ageVerified,
      locationGranted: locationGranted ?? this.locationGranted,
      cookingSkill: cookingSkill ?? this.cookingSkill,
      cookingGoal: cookingGoal ?? this.cookingGoal,
      cookedCount: cookedCount ?? this.cookedCount,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      mealRemindersEnabled: mealRemindersEnabled ?? this.mealRemindersEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Result of a profile fetch.
class ProfileResult {
  const ProfileResult.success(this.profile) : error = null;

  const ProfileResult.failure(this.error) : profile = null;

  final Profile? profile;
  final String? error;

  bool get hasError => error != null;
}

/// Result of a profile write.
class ProfileWriteResult {
  const ProfileWriteResult({this.error});

  final String? error;

  bool get isSuccess => error == null;

  static const ProfileWriteResult ok = ProfileWriteResult();
}
