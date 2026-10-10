import 'package:flutter/material.dart';

/// "#FF6B6B" → Color; falls back to [fallback] on bad input.
Color colorFromHex(String? hex, {Color fallback = const Color(0xFFFF6B6B)}) {
  final h = (hex ?? '').replaceFirst('#', '');
  final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return v == null ? fallback : Color(v);
}

DateTime _date(Object? v) =>
    DateTime.tryParse(v?.toString() ?? '')?.toLocal() ?? DateTime.now();

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

List<Map<String, dynamic>> _maps(Object? v) =>
    (v as List? ?? const []).whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();

/// A profile chip on the creator page, e.g. "🏆 2x Winner".
@immutable
class CreatorHighlight {
  const CreatorHighlight({required this.emoji, required this.label, required this.color});

  final String emoji;
  final String label;
  final Color color;
}

/// A "Recent tips received" row on the creator page.
@immutable
class CreatorTip {
  const CreatorTip({
    required this.user,
    required this.amount,
    required this.dish,
    required this.emoji,
    required this.hoursAgo,
  });

  final String user;
  final String amount;
  final String dish;
  final String emoji;
  final int hoursAgo;
}

/// One row of `public.creators` — the public identity behind a "@handle".
@immutable
class Creator {
  const Creator({
    required this.handle,
    this.profileId,
    this.displayName = '',
    this.avatarEmoji = '🧑‍🍳',
    this.avatarUrl,
    this.bio = '',
    this.tagline = '',
    this.badge = '',
    this.reason = '',
    this.specialties = const [],
    this.highlights = const [],
    this.recentTips = const [],
    this.xp = 0,
    this.followers = 0,
    this.following = 0,
    this.recipes = 0,
    this.featuredRecipeId,
    this.isFeatured = false,
    this.isSuggested = false,
  });

  final String handle;

  /// Set for real users; null for seeded catalog creators.
  final String? profileId;
  final String displayName;
  final String avatarEmoji;
  final String? avatarUrl;
  final String bio;
  final String tagline;
  final String badge;
  final String reason;
  final List<String> specialties;
  final List<CreatorHighlight> highlights;
  final List<CreatorTip> recentTips;
  final int xp;
  final int followers;
  final int following;
  final int recipes;
  final int? featuredRecipeId;
  final bool isFeatured;
  final bool isSuggested;

  String get name => displayName.isEmpty ? handle : displayName;

  /// Only real users can receive messages.
  bool get canMessage => profileId != null;

  /// Columns + embedded profile XP for [Creator.fromRow].
  static const String select = '*, profile:profiles(xp)';

  factory Creator.fromRow(Map<String, dynamic> r) {
    final profile = r['profile'] as Map?;
    return Creator(
      handle: r['handle'] as String,
      profileId: r['profile_id'] as String?,
      displayName: (r['display_name'] as String?) ?? '',
      avatarEmoji: (r['avatar_emoji'] as String?) ?? '🧑‍🍳',
      avatarUrl: r['avatar_url'] as String?,
      bio: (r['bio'] as String?) ?? '',
      tagline: (r['tagline'] as String?) ?? '',
      badge: (r['badge'] as String?) ?? '',
      reason: (r['reason'] as String?) ?? '',
      specialties: (r['specialties'] as List? ?? const []).cast<String>(),
      highlights: [
        for (final h in _maps(r['highlights']))
          CreatorHighlight(
            emoji: (h['emoji'] as String?) ?? '',
            label: (h['label'] as String?) ?? '',
            color: colorFromHex(h['color'] as String?),
          ),
      ],
      recentTips: [
        for (final t in _maps(r['recent_tips']))
          CreatorTip(
            user: (t['user'] as String?) ?? '',
            amount: (t['amount'] as String?) ?? '',
            dish: (t['dish'] as String?) ?? '',
            emoji: (t['emoji'] as String?) ?? '🌶',
            hoursAgo: _int(t['hours_ago']),
          ),
      ],
      xp: profile != null ? _int(profile['xp']) : _int(r['base_xp']),
      followers: _int(r['base_followers']) + _int(r['followers_count']),
      following: _int(r['base_following']) + _int(r['following_count']),
      recipes: _int(r['base_recipes']) + _int(r['recipes_count']),
      featuredRecipeId: (r['featured_recipe_id'] as num?)?.toInt(),
      isFeatured: r['is_featured'] == true,
      isSuggested: r['is_suggested'] == true,
    );
  }
}

/// One Activity-feed item (`public.feed_posts`).
@immutable
class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorHandle,
    required this.type,
    required this.createdAt,
    this.userId,
    this.action = '',
    this.target = '',
    this.rating,
    this.caption,
    this.photoUrl,
    this.hasPhoto = false,
    this.recipeId,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.creator,
  });

  final String id;

  /// Author's user id; null for seeded posts.
  final String? userId;
  final String authorHandle;

  /// cooked | rated | achievement | tipped | created | text
  final String type;
  final String action;
  final String target;

  /// Spice emoji shown after the target, or null.
  final String? rating;
  final String? caption;
  final String? photoUrl;
  final bool hasPhoto;
  final int? recipeId;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final Creator? creator;

  static const String select = '*, creator:creators(${Creator.select})';

  factory FeedPost.fromRow(Map<String, dynamic> r) {
    final creator = r['creator'] as Map?;
    return FeedPost(
      id: r['id'] as String,
      userId: r['user_id'] as String?,
      authorHandle: r['author_handle'] as String,
      type: (r['type'] as String?) ?? 'text',
      action: (r['action'] as String?) ?? '',
      target: (r['target'] as String?) ?? '',
      rating: r['rating'] as String?,
      caption: r['caption'] as String?,
      photoUrl: r['photo_url'] as String?,
      hasPhoto: r['has_photo'] == true || r['photo_url'] != null,
      recipeId: (r['recipe_id'] as num?)?.toInt(),
      likesCount: _int(r['likes_count']),
      commentsCount: _int(r['comments_count']),
      createdAt: _date(r['created_at']),
      creator: creator == null ? null : Creator.fromRow(creator.cast<String, dynamic>()),
    );
  }

  FeedPost copyWith({int? likesCount, int? commentsCount}) => FeedPost(
        id: id,
        userId: userId,
        authorHandle: authorHandle,
        type: type,
        action: action,
        target: target,
        rating: rating,
        caption: caption,
        photoUrl: photoUrl,
        hasPhoto: hasPhoto,
        recipeId: recipeId,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount ?? this.commentsCount,
        createdAt: createdAt,
        creator: creator,
      );
}

/// A comment on a [FeedPost] (`public.post_comments`).
@immutable
class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorHandle,
    required this.body,
    required this.createdAt,
    this.userId,
    this.likesCount = 0,
    this.creator,
  });

  final String id;
  final String postId;
  final String? userId;
  final String authorHandle;
  final String body;
  final int likesCount;
  final DateTime createdAt;
  final Creator? creator;

  static const String select = '*, creator:creators(handle, avatar_emoji, avatar_url)';

  factory PostComment.fromRow(Map<String, dynamic> r) {
    final creator = r['creator'] as Map?;
    return PostComment(
      id: r['id'] as String,
      postId: r['post_id'] as String,
      userId: r['user_id'] as String?,
      authorHandle: r['author_handle'] as String,
      body: (r['body'] as String?) ?? '',
      likesCount: _int(r['likes_count']),
      createdAt: _date(r['created_at']),
      creator: creator == null ? null : Creator.fromRow(creator.cast<String, dynamic>()),
    );
  }

  PostComment copyWith({int? likesCount}) => PostComment(
        id: id,
        postId: postId,
        userId: userId,
        authorHandle: authorHandle,
        body: body,
        likesCount: likesCount ?? this.likesCount,
        createdAt: createdAt,
        creator: creator,
      );
}

/// A local food event (`public.events`).
@immutable
class SocialEvent {
  const SocialEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    this.venue = '',
    this.description = '',
    this.emoji = '🎪',
    this.category = 'tastings',
    this.endsAt,
    this.distance = '',
    this.price = '',
    this.color = const Color(0xFFFF6B6B),
    this.capacity,
    this.attending = 0,
    this.interested = 0,
    this.sampleAvatars = const [],
    this.isFeatured = false,
  });

  final String id;
  final String title;
  final String venue;
  final String description;
  final String emoji;
  final String category;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String distance;
  final String price;
  final Color color;

  /// null = open event.
  final int? capacity;
  final int attending;
  final int interested;
  final List<String> sampleAvatars;
  final bool isFeatured;

  int? get spotsLeft => capacity == null ? null : (capacity! - attending).clamp(0, capacity!);
  bool get soldOut => spotsLeft == 0;

  String get spotsLabel => switch (spotsLeft) {
        null => 'Open event',
        0 => 'Sold out',
        final n => '$n spots left',
      };

  factory SocialEvent.fromRow(Map<String, dynamic> r) => SocialEvent(
        id: r['id'] as String,
        title: (r['title'] as String?) ?? '',
        venue: (r['venue'] as String?) ?? '',
        description: (r['description'] as String?) ?? '',
        emoji: (r['emoji'] as String?) ?? '🎪',
        category: (r['category'] as String?) ?? 'tastings',
        startsAt: _date(r['starts_at']),
        endsAt: r['ends_at'] == null ? null : _date(r['ends_at']),
        distance: (r['distance'] as String?) ?? '',
        price: (r['price'] as String?) ?? '',
        color: colorFromHex(r['color'] as String?),
        capacity: (r['capacity'] as num?)?.toInt(),
        attending: _int(r['base_attending']) + _int(r['attending_count']),
        interested: _int(r['interested_count']),
        sampleAvatars: (r['sample_avatars'] as List? ?? const []).cast<String>(),
        isFeatured: r['is_featured'] == true,
      );

  SocialEvent copyWith({int? attending}) => SocialEvent(
        id: id,
        title: title,
        venue: venue,
        description: description,
        emoji: emoji,
        category: category,
        startsAt: startsAt,
        endsAt: endsAt,
        distance: distance,
        price: price,
        color: color,
        capacity: capacity,
        attending: attending ?? this.attending,
        interested: interested,
        sampleAvatars: sampleAvatars,
        isFeatured: isFeatured,
      );
}

/// A recipe's place in the Trending ranking (`trending_recipes()`).
@immutable
class TrendingRank {
  const TrendingRank({required this.recipeId, required this.heartsWeek, required this.heartsTotal});

  final int recipeId;

  /// Saves + feed likes + super-favs in the last 7 days.
  final int heartsWeek;
  final int heartsTotal;

  factory TrendingRank.fromRow(Map<String, dynamic> r) => TrendingRank(
        recipeId: _int(r['recipe_id']),
        heartsWeek: _int(r['hearts_week']),
        heartsTotal: _int(r['hearts_total']),
      );
}

// ── Chat ──

/// Another member of a DM / group, as shown in the chat list and header.
@immutable
class ChatPeer {
  const ChatPeer({
    required this.userId,
    this.displayName = '',
    this.username = '',
    this.avatarEmoji = '🧑‍🍳',
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String username;
  final String avatarEmoji;
  final String? avatarUrl;

  String get name => displayName.isNotEmpty ? displayName : (username.isNotEmpty ? username : 'b🌶te cook');
  String? get handle => username.isEmpty ? null : '@${username.toLowerCase()}';
}

/// A DM or private group the signed-in user belongs to.
@immutable
class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.kind,
    required this.status,
    required this.lastReadAt,
    this.name = '',
    this.emoji = '💬',
    this.peers = const [],
    this.muted = false,
    this.lastMessagePreview = '',
    this.lastMessageAt,
    this.lastSenderId,
    this.createdAt,
  });

  final String id;

  /// dm | group
  final String kind;

  /// accepted | pending (a message request)
  final String status;
  final String name;
  final String emoji;

  /// Members other than the signed-in user.
  final List<ChatPeer> peers;
  final bool muted;
  final DateTime lastReadAt;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final String? lastSenderId;
  final DateTime? createdAt;

  bool get isGroup => kind == 'group';
  bool get isRequest => status == 'pending';
  ChatPeer? get peer => peers.isEmpty ? null : peers.first;

  String get title => isGroup || peer == null ? (name.isEmpty ? 'Group' : name) : peer!.name;

  DateTime get sortTime => lastMessageAt ?? createdAt ?? lastReadAt;

  bool unreadFor(String userId) {
    final at = lastMessageAt;
    return at != null && lastSenderId != userId && at.isAfter(lastReadAt);
  }

  /// Parses a `conversation_members` row with the conversation embedded.
  static const String memberSelect =
      'status, muted, last_read_at, conversation:conversations(*, '
      'members:conversation_members(user_id, profile:profiles(display_name, username, avatar_emoji, avatar_url)))';

  factory ChatConversation.fromMemberRow(Map<String, dynamic> r, String myId) {
    final c = (r['conversation'] as Map).cast<String, dynamic>();
    return ChatConversation(
      id: c['id'] as String,
      kind: (c['kind'] as String?) ?? 'dm',
      status: (r['status'] as String?) ?? 'accepted',
      name: (c['name'] as String?) ?? '',
      emoji: (c['emoji'] as String?) ?? '💬',
      muted: r['muted'] == true,
      lastReadAt: _date(r['last_read_at']),
      lastMessagePreview: (c['last_message_preview'] as String?) ?? '',
      lastMessageAt: c['last_message_at'] == null ? null : _date(c['last_message_at']),
      lastSenderId: c['last_sender_id'] as String?,
      createdAt: _date(c['created_at']),
      peers: [
        for (final m in _maps(c['members']))
          if (m['user_id'] != myId)
            ChatPeer(
              userId: m['user_id'] as String,
              displayName: ((m['profile'] as Map?)?['display_name'] as String?) ?? '',
              username: ((m['profile'] as Map?)?['username'] as String?) ?? '',
              avatarEmoji: ((m['profile'] as Map?)?['avatar_emoji'] as String?) ?? '🧑‍🍳',
              avatarUrl: (m['profile'] as Map?)?['avatar_url'] as String?,
            ),
      ],
    );
  }
}

/// A public community room or live kitchen.
@immutable
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.kind,
    required this.name,
    this.emoji = '💬',
    this.description = '',
    this.tier,
    this.unlockLevel,
    this.color = const Color(0xFFFF6B6B),
    this.isLive = false,
    this.members = 0,
    this.lastMessageAt,
  });

  final String id;

  /// community | kitchen
  final String kind;
  final String name;
  final String emoji;
  final String description;

  /// foodies | creators | critics
  final String? tier;
  final String? unlockLevel;
  final Color color;
  final bool isLive;
  final int members;
  final DateTime? lastMessageAt;

  bool get isKitchen => kind == 'kitchen';

  factory ChatRoom.fromRow(Map<String, dynamic> r) => ChatRoom(
        id: r['id'] as String,
        kind: (r['kind'] as String?) ?? 'community',
        name: (r['name'] as String?) ?? '',
        emoji: (r['emoji'] as String?) ?? '💬',
        description: (r['description'] as String?) ?? '',
        tier: r['tier'] as String?,
        unlockLevel: r['unlock_level'] as String?,
        color: colorFromHex(r['color'] as String?),
        isLive: r['is_live'] == true,
        members: _int(r['base_members']) + _int(r['members_count']),
        lastMessageAt: r['last_message_at'] == null ? null : _date(r['last_message_at']),
      );
}

/// One message in a thread (`public.messages`).
@immutable
class ChatMessageItem {
  const ChatMessageItem({
    required this.id,
    required this.conversationId,
    required this.createdAt,
    this.senderId,
    this.senderName = '',
    this.body = '',
    this.recipeId,
    this.pending = false,
  });

  final String id;
  final String conversationId;
  final String? senderId;
  final String senderName;
  final String body;
  final int? recipeId;
  final DateTime createdAt;

  /// True while an optimistic send is in flight.
  final bool pending;

  factory ChatMessageItem.fromRow(Map<String, dynamic> r) => ChatMessageItem(
        id: r['id'] as String,
        conversationId: r['conversation_id'] as String,
        senderId: r['sender_id'] as String?,
        senderName: (r['sender_name'] as String?) ?? '',
        body: (r['body'] as String?) ?? '',
        recipeId: (r['recipe_id'] as num?)?.toInt(),
        createdAt: _date(r['created_at']),
      );
}
