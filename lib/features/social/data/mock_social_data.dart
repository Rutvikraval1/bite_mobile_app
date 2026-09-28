import 'package:flutter/material.dart';

import '../../../core/router/app_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../content/data/image_urls.dart';

/// Pexels avatar photo ids for known creator handles — mirrors the JS
/// `AVATAR_MAP` in `theme.js`, so the same faces show up across the social
/// screens as they do in the prototype.
abstract final class SocialAvatars {
  static const Map<String, String> _ids = {
    '@chefpriya': '34238049',
    '@noodlequeen': '1820559',
    '@foodielisa': '38366748',
    '@homecook_dan': '35681211',
    '@marco.eats': '19420186',
    '@bangkokbites': '16120625',
    '@sarah_bakes': '1820575',
    '@barista_ko': '19248892',
    '@grillmaster': '14950779',
    '@abuelitas_kitchen': '30269649',
    '@healthnut_amy': '9271168',
    '@pastaking': '33970123',
    '@seoulfoods': '19244211',
    '@sundaychef': '35490803',
    '@foodienyc': '6102841',
    '@sushilover': '30795870',
  };

  static String? urlFor(String handle) {
    final id = _ids[handle];
    return id == null ? null : ImageUrls.avatar(id);
  }
}

/// One item in the "Activity" feed wall — ports the JS `activityFeed` shape
/// built from `activityTemplates` + live recipes in `SocialFeedScreen`.
class FeedActivity {
  const FeedActivity({
    required this.type,
    required this.user,
    required this.avatarEmoji,
    required this.action,
    this.target = '',
    this.rating,
    required this.time,
    this.hasPhoto = false,
    required this.likes,
    required this.comments,
    this.caption,
    this.tierColor = AppColors.saveGreen,
    this.photoColor = AppColors.coral,
  });

  /// cooked | rated | achievement | tipped | created | text
  final String type;
  final String user;
  final String avatarEmoji;
  final String action;
  final String target;

  /// Spice-level emoji (🟢/🟠/🔴/🌶) shown after the target, or null.
  final String? rating;
  final String time;
  final bool hasPhoto;
  final int likes;
  final int comments;
  final String? caption;
  final Color tierColor;
  final Color photoColor;

  String? get avatarUrl => SocialAvatars.urlFor(user);
}

const List<FeedActivity> mockActivityFeed = [
  FeedActivity(
    type: 'cooked',
    user: '@chefpriya',
    avatarEmoji: '🍗',
    action: 'cooked',
    target: 'Gochujang Glazed Fried Chicken',
    rating: '🔴',
    time: '12m',
    hasPhoto: true,
    likes: 61,
    comments: 24,
    caption: "This one's a keeper 🔥",
    tierColor: AppColors.coral,
    photoColor: AppColors.coral,
  ),
  FeedActivity(
    type: 'rated',
    user: '@marco.eats',
    avatarEmoji: '🍄',
    action: 'rated',
    target: 'Truffle Mushroom Risotto',
    rating: '🌶',
    time: '25m',
    likes: 76,
    comments: 32,
    tierColor: AppColors.amber,
  ),
  FeedActivity(
    type: 'cooked',
    user: '@tastythai',
    avatarEmoji: '🥭',
    action: 'cooked',
    target: 'Mango Sticky Rice Bowl',
    rating: '🟠',
    time: '1h',
    hasPhoto: true,
    likes: 212,
    comments: 58,
    caption: 'Weeknight win ⚡',
    tierColor: Color(0xFF4CAF50),
    photoColor: AppColors.amber,
  ),
  FeedActivity(
    type: 'achievement',
    user: '@sushilover',
    avatarEmoji: '🍣',
    action: 'leveled up to',
    target: 'Chef 🧑‍🍳',
    time: '1.5h',
    likes: 44,
    comments: 6,
    tierColor: Color(0xFF9C27B0),
  ),
  FeedActivity(
    type: 'cooked',
    user: '@abuelitas_kitchen',
    avatarEmoji: '🌮',
    action: 'cooked',
    target: 'Birria Street Tacos',
    rating: '🔴',
    time: '2h',
    hasPhoto: true,
    likes: 324,
    comments: 91,
    caption: 'Extra garlic is the move 🧄',
    tierColor: AppColors.amber,
    photoColor: AppColors.cyan,
  ),
  FeedActivity(
    type: 'tipped',
    user: '@sarah_bakes',
    avatarEmoji: '🦞',
    action: 'tipped',
    target: '\$5 tip',
    time: '3h',
    likes: 18,
    comments: 3,
    caption: 'Amazing recipe!',
    tierColor: Color(0xFF4CAF50),
  ),
  FeedActivity(
    type: 'created',
    user: '@bangkokbites',
    avatarEmoji: '🥘',
    action: 'published',
    target: 'Pad See Ew',
    time: '4h',
    hasPhoto: true,
    likes: 152,
    comments: 47,
    caption: 'New recipe alert! 🍽️',
    tierColor: AppColors.coral,
    photoColor: AppColors.placesPurple,
  ),
  FeedActivity(
    type: 'cooked',
    user: '@barista_ko',
    avatarEmoji: '🍳',
    action: 'mixed',
    target: 'Shakshuka',
    rating: '🟠',
    time: '5h',
    hasPhoto: true,
    likes: 39,
    comments: 11,
    caption: 'So smooth',
    tierColor: Color(0xFF64B5F6),
    photoColor: Color(0xFF4CAF50),
  ),
  FeedActivity(
    type: 'text',
    user: '@healthnut_amy',
    avatarEmoji: '🍛',
    action: 'shared a thought',
    time: '5.5h',
    likes: 88,
    comments: 15,
    caption:
        "PSA: let your steak rest as long as you cooked it. Changed my "
        'whole game 🥩',
    tierColor: AppColors.cyan,
  ),
  FeedActivity(
    type: 'cooked',
    user: '@grillmaster',
    avatarEmoji: '🥡',
    action: 'cooked',
    target: 'Kung Pao Chicken',
    rating: '🟠',
    time: '7h',
    hasPhoto: true,
    likes: 71,
    comments: 20,
    caption: 'Slow cooked for hours 🤤',
    tierColor: AppColors.placesPurple,
    photoColor: Color(0xFF64B5F6),
  ),
  FeedActivity(
    type: 'cooked',
    user: '@foodielisa',
    avatarEmoji: '🫒',
    action: 'cooked',
    target: 'Grilled Lamb Souvlaki',
    rating: '🔴',
    time: '9h',
    hasPhoto: true,
    likes: 55,
    comments: 14,
    caption: 'Simple perfection 🧀',
    tierColor: AppColors.coral,
  ),
  FeedActivity(
    type: 'text',
    user: '@pastaking',
    avatarEmoji: '🥐',
    action: 'asked',
    time: '10h',
    likes: 63,
    comments: 41,
    caption: "What's everyone cooking this week? Need inspo 💭",
    tierColor: AppColors.amber,
  ),
  FeedActivity(
    type: 'rated',
    user: '@seoulfoods',
    avatarEmoji: '🍜',
    action: 'rated',
    target: 'Pho Bo',
    rating: '🟠',
    time: '12h',
    likes: 29,
    comments: 5,
    tierColor: AppColors.coral,
  ),
];

/// "Cooks You Might Like" suggested-creator card.
class SuggestedCreator {
  const SuggestedCreator({
    required this.handle,
    required this.avatarEmoji,
    required this.reason,
    required this.followers,
    required this.recipes,
  });

  final String handle;
  final String avatarEmoji;
  final String reason;
  final String followers;
  final int recipes;

  String? get avatarUrl => SocialAvatars.urlFor(handle);
}

const List<SuggestedCreator> mockSuggestedCreators = [
  SuggestedCreator(
    handle: '@spice.mama',
    avatarEmoji: '👩‍🍳',
    reason: 'Loves spicy · Near you',
    followers: '2.1K',
    recipes: 34,
  ),
  SuggestedCreator(
    handle: '@keto.king',
    avatarEmoji: '🥑',
    reason: 'Same diet · Keto',
    followers: '5.8K',
    recipes: 67,
  ),
  SuggestedCreator(
    handle: '@seoul.eats',
    avatarEmoji: '🍜',
    reason: 'Korean cuisine fan',
    followers: '12K',
    recipes: 89,
  ),
  SuggestedCreator(
    handle: '@plantbased.pro',
    avatarEmoji: '🥬',
    reason: 'Vegan community',
    followers: '8.3K',
    recipes: 112,
  ),
];

/// A recipe-style card used by the For You / Trending / Following tabs.
class FeedCard {
  const FeedCard({
    required this.title,
    required this.user,
    required this.emoji,
    required this.color,
    this.big = false,
    this.trend,
    this.comment,
  });

  final String title;
  final String user;
  final String emoji;
  final Color color;
  final bool big;
  final String? trend;
  final String? comment;
}

const List<FeedCard> mockForYouCards = [
  FeedCard(title: 'Gochujang Glazed Fried Chicken', user: '@chefpriya', emoji: '🍗', color: AppColors.coral, big: true),
  FeedCard(title: 'Truffle Mushroom Risotto', user: '@marco.eats', emoji: '🍄', color: AppColors.amber),
  FeedCard(title: 'Mango Sticky Rice Bowl', user: '@tastythai', emoji: '🥭', color: AppColors.coralDark),
  FeedCard(title: 'Spicy Tuna Crispy Rice', user: '@sushilover', emoji: '🍣', color: AppColors.drinksBlue),
];

const List<FeedCard> mockTrendingCards = [
  FeedCard(title: 'Birria Street Tacos', user: '@abuelitas_kitchen', emoji: '🌮', color: AppColors.amber, big: true, trend: '#1', comment: '6,300 hearts this week'),
  FeedCard(title: 'Lobster Mac & Cheese', user: '@sarah_bakes', emoji: '🦞', color: AppColors.coral, trend: '#2', comment: '3,000 hearts this week'),
  FeedCard(title: 'Pad See Ew', user: '@bangkokbites', emoji: '🥘', color: Color(0xFF8B4513), trend: '#3', comment: '2,900 hearts this week'),
  FeedCard(title: 'Gochujang Glazed Fried Chicken', user: '@chefpriya', emoji: '🍗', color: AppColors.coralDark, big: true, trend: '#4', comment: '1,200 hearts this week'),
];

const List<FeedCard> mockFollowingCards = [
  FeedCard(title: 'Shakshuka', user: '@barista_ko', emoji: '🍳', color: AppColors.amber, big: true, comment: '"Shakshuka night!" — 2h ago'),
  FeedCard(title: 'Kung Pao Chicken', user: '@grillmaster', emoji: '🥡', color: AppColors.drinksBlue, comment: '"Kung Pao Chicken night!" — 4h ago'),
  FeedCard(title: 'Grilled Lamb Souvlaki', user: '@foodielisa', emoji: '🫒', color: Color(0xFF4CAF50), comment: '"Grilled Lamb Souvlaki night!" — 6h ago'),
];

/// A creator card in the Creators tab.
class CreatorCard {
  const CreatorCard({
    required this.handle,
    required this.name,
    required this.emoji,
    required this.recipes,
    required this.followers,
    required this.badge,
  });

  final String handle;
  final String name;
  final String emoji;
  final int recipes;
  final String followers;
  final String badge;

  String? get avatarUrl => SocialAvatars.urlFor(handle);
}

const List<CreatorCard> mockCreatorCards = [
  CreatorCard(handle: '@chefpriya', name: 'Chefpriya', emoji: '🍗', recipes: 37, followers: '24.0K', badge: '🏆 Top Creator'),
  CreatorCard(handle: '@marco.eats', name: 'Marco Eats', emoji: '🍄', recipes: 74, followers: '36.0K', badge: '🔥 Trending Cook'),
  CreatorCard(handle: '@bangkokbites', name: 'Bangkokbites', emoji: '🥘', recipes: 111, followers: '76.0K', badge: '⭐ Rising Star'),
  CreatorCard(handle: '@sarah_bakes', name: 'Sarah Bakes', emoji: '🦞', recipes: 148, followers: '60.0K', badge: '💎 Community Fave'),
];

/// A local food event card in the Events tab.
class LocalEvent {
  const LocalEvent({
    required this.title,
    required this.venue,
    required this.emoji,
    required this.date,
    required this.distance,
    required this.price,
    required this.color,
    required this.attending,
    required this.spots,
    this.soldOut = false,
  });

  final String title;
  final String venue;
  final String emoji;
  final String date;
  final String distance;
  final String price;
  final Color color;
  final int attending;
  final String spots;
  final bool soldOut;
}

const List<LocalEvent> mockEvents = [
  LocalEvent(title: 'Thai Street Food Pop-Up', venue: 'The Kitchen Collective', emoji: '🥘', date: 'Mar 12 · 6 PM', distance: '1.8 mi', price: '\$25/person', color: AppColors.coral, attending: 67, spots: '12 spots left'),
  LocalEvent(title: 'Wine & Cheese Pairing Night', venue: 'Cellar Door Wine Bar', emoji: '🍷', date: 'Mar 14 · 7:30 PM', distance: '3.2 mi', price: '\$45/person', color: AppColors.placesPurple, attending: 42, spots: '8 spots left'),
  LocalEvent(title: 'Beginner Sushi Rolling Class', venue: 'Omakase by Sato', emoji: '🍣', date: 'Mar 15 · 2 PM', distance: '0.8 mi', price: '\$60/person', color: AppColors.drinksBlue, attending: 18, spots: '6 spots left'),
  LocalEvent(title: 'BBQ & Brew Festival', venue: 'Riverside Park', emoji: '🍖', date: 'Mar 18 · 12 PM', distance: '4.1 mi', price: 'Free entry', color: AppColors.amber, attending: 412, spots: 'Open event'),
  LocalEvent(title: 'Sourdough Bread Workshop', venue: 'Flour Power Bakery', emoji: '🍞', date: 'Mar 20 · 10 AM', distance: '2.5 mi', price: '\$35/person', color: Color(0xFF8B4513), attending: 24, spots: '4 spots left'),
  LocalEvent(title: 'Farm-to-Table Dinner', venue: 'Green Acres Farm', emoji: '🌿', date: 'Mar 22 · 6:30 PM', distance: '8.3 mi', price: '\$85/person', color: Color(0xFF4CAF50), attending: 36, spots: 'Sold out', soldOut: true),
];

/// A single comment row in the comment sheet.
class SocialComment {
  const SocialComment({
    required this.user,
    required this.avatarEmoji,
    required this.text,
    required this.time,
    required this.likes,
    this.isYou = false,
  });

  final String user;
  final String avatarEmoji;
  final String text;
  final String time;
  final int likes;
  final bool isYou;

  String? get avatarUrl => SocialAvatars.urlFor(user);
}

const List<SocialComment> mockSampleComments = [
  SocialComment(user: '@noodlequeen', avatarEmoji: '🍜', text: 'This looks incredible! 🔥', time: '2m', likes: 12),
  SocialComment(user: '@marco.eats', avatarEmoji: '🍄', text: 'Need the recipe ASAP!', time: '8m', likes: 5),
  SocialComment(user: '@sarah_bakes', avatarEmoji: '🍰', text: 'The plating is gorgeous 😍', time: '15m', likes: 8),
  SocialComment(user: '@bangkokbites', avatarEmoji: '🍗', text: "Reminds me of my grandma's version", time: '1h', likes: 3),
  SocialComment(user: '@foodielisa', avatarEmoji: '👩‍🍳', text: 'Added to my must-try list!', time: '2h', likes: 2),
  SocialComment(user: '@chefpriya', avatarEmoji: '👩‍🍳', text: 'Try adding a pinch of MSG, game changer 🤌', time: '3h', likes: 24),
  SocialComment(user: '@spiceroute', avatarEmoji: '🌶', text: 'Made this last night, my family DEVOURED it', time: '4h', likes: 18),
  SocialComment(user: '@tastythai', avatarEmoji: '🥭', text: 'Substituted with what I had in the fridge, still 🔥', time: '6h', likes: 7),
  SocialComment(user: '@wok_master', avatarEmoji: '🥡', text: 'Pro tip: rest the protein 5 min before saucing', time: '8h', likes: 31),
  SocialComment(user: '@home_cook_42', avatarEmoji: '🍳', text: 'First time cooking this cuisine, easier than I thought!', time: '12h', likes: 4),
  SocialComment(user: '@sushilab', avatarEmoji: '🍣', text: 'Could you do a video version of this?', time: '14h', likes: 9),
  SocialComment(user: '@abuelitas_kitchen', avatarEmoji: '🌮', text: "10/10 would marry whoever made this", time: '1d', likes: 47),
  SocialComment(user: '@brunch_baby', avatarEmoji: '🥞', text: 'saving this for the weekend ❤️', time: '1d', likes: 6),
  SocialComment(user: '@late_night_eats', avatarEmoji: '🌙', text: 'perfect 2am craving fix tbh', time: '2d', likes: 11),
];

/// Chat quick-reply / comment quick-chip pool.
const List<String> commentQuickChips = ['🔥 Fire!', '😍 Love this!', 'Need recipe!', '💯 Amazing', 'Saving this'];

// ── Chat list ──

class ChatPreview {
  const ChatPreview({
    required this.name,
    required this.preview,
    required this.time,
    required this.unread,
    this.isGenie = false,
  });

  final String name;
  final String preview;
  final String time;
  final bool unread;
  final bool isGenie;
}

const List<ChatPreview> mockChats = [
  ChatPreview(name: '🧞 Food Genie', preview: 'Here are 3 recipes based on your pantry scan...', time: '2m', unread: true, isGenie: true),
  ChatPreview(name: 'Sarah Chen', preview: 'omg you HAVE to try this birria recipe 🌮', time: '12m', unread: true),
  ChatPreview(name: 'Marcus Johnson', preview: "Thanks for the ramen tips! Here's my attempt...", time: '1h', unread: true),
  ChatPreview(name: 'Emily Park', preview: 'Are you joining the taco challenge this weekend?', time: '3h', unread: false),
  ChatPreview(name: 'James Liu', preview: "Recipe swap? I'll trade my pad thai for your...", time: 'Yesterday', unread: false),
  ChatPreview(name: 'Maria Garcia', preview: "The Genie suggested we'd both love this!", time: '2d', unread: false),
  ChatPreview(name: 'Tyler Brooks', preview: 'Brunch crew this Sunday? I found a place 🥐', time: '2d', unread: false),
  ChatPreview(name: 'Jin-Soo Park', preview: 'Sent you the gochujang plug from H-mart 🌶', time: '3d', unread: false),
  ChatPreview(name: 'Olivia Reyes', preview: 'That cookie recipe was 🔥🔥🔥 making again', time: '4d', unread: false),
  ChatPreview(name: 'Devon Walsh', preview: 'Reservation confirmed for Friday 7:30pm 🍽', time: '5d', unread: false),
];

class ChatRequest {
  const ChatRequest({
    required this.name,
    required this.preview,
    required this.time,
    required this.avatarEmoji,
    this.mutual,
  });

  final String name;
  final String preview;
  final String time;
  final String avatarEmoji;
  final String? mutual;
}

const List<ChatRequest> mockChatRequests = [
  ChatRequest(name: 'Alex Rivera', preview: 'Hey! Loved your fried chicken post 🍗', time: '1h', avatarEmoji: '🌮', mutual: '2 mutual connections'),
  ChatRequest(name: 'Priya Patel', preview: 'Can you share your gochujang source?', time: '3h', avatarEmoji: '🍛', mutual: '1 mutual connection'),
  ChatRequest(name: 'Jake Thompson', preview: 'Your ramen pics are insane! 🍜', time: '1d', avatarEmoji: '🍕'),
  ChatRequest(name: 'Sofia Ramos', preview: "We met at the dumpling pop-up — let's connect!", time: '2d', avatarEmoji: '🥟', mutual: '4 mutual connections'),
  ChatRequest(name: 'Hassan Ali', preview: 'Saw your account from the Critics group ✨', time: '3d', avatarEmoji: '🍢'),
];

class LiveKitchen {
  const LiveKitchen({
    required this.name,
    required this.emoji,
    required this.members,
    required this.active,
    required this.isLive,
    required this.color,
  });

  final String name;
  final String emoji;
  final String members;
  final String active;
  final bool isLive;
  final Color color;
}

const List<LiveKitchen> mockLiveKitchens = [
  LiveKitchen(name: "@chefpriya's Kitchen", emoji: '👩‍🍳', members: '2.4K', active: '🟢 Live', isLive: true, color: AppColors.coral),
  LiveKitchen(name: '@marcusfoods Ramen Lab', emoji: '🍜', members: '890', active: '12m ago', isLive: false, color: AppColors.amber),
  LiveKitchen(name: '@sarah_bakes Bakery', emoji: '🧁', members: '1.1K', active: '🟢 Live', isLive: true, color: Color(0xFFE91E63)),
];

class CommunityGroup {
  const CommunityGroup({
    required this.name,
    required this.emoji,
    required this.members,
    required this.desc,
    required this.newCount,
    this.unlock,
  });

  final String name;
  final String emoji;
  final String members;
  final String desc;
  final int newCount;
  final String? unlock;
}

const Map<String, List<CommunityGroup>> mockCommunityGroups = {
  'foodies': [
    CommunityGroup(name: "What's Good Near Me", emoji: '📍', members: '34.5K', desc: 'Restaurant recs, hidden spots, where to eat tonight', newCount: 67),
    CommunityGroup(name: 'Date Night Eats', emoji: '💕', members: '18.2K', desc: 'Restaurant picks for couples — impress every time', newCount: 24),
    CommunityGroup(name: 'Street Food Hunters', emoji: '🌍', members: '45.2K', desc: "Tacos, dumplings, kebabs — if it's on a cart, it's here", newCount: 89),
    CommunityGroup(name: 'Meal Prep Crew', emoji: '📦', members: '15.7K', desc: 'Batch cook Sunday, eat all week', newCount: 8, unlock: 'Beginner'),
    CommunityGroup(name: 'Late Night Bites', emoji: '🌙', members: '31.8K', desc: '3am cravings hit different', newCount: 42),
  ],
  'creators': [
    CommunityGroup(name: 'Recipe Workshop', emoji: '🧪', members: '5.4K', desc: 'Test recipes, get feedback before publishing', newCount: 19, unlock: 'Beginner'),
    CommunityGroup(name: 'Food Photography', emoji: '📸', members: '11.2K', desc: 'Lighting, angles, styling — make it look insane', newCount: 31),
    CommunityGroup(name: 'Creator Economy', emoji: '💰', members: '2.1K', desc: 'Tips, earnings, brand deals & growth strategies', newCount: 5, unlock: 'Sous Chef'),
    CommunityGroup(name: 'Fermentation Lab', emoji: '🫙', members: '9.3K', desc: 'Kimchi, sourdough, kombucha & beyond', newCount: 12, unlock: 'Home Cook'),
    CommunityGroup(name: 'World Fusion', emoji: '🌍', members: '7.8K', desc: 'Mash up cuisines — Korean-Mexican? Thai-Italian? Yes.', newCount: 16),
  ],
  'critics': [
    CommunityGroup(name: 'Rate Everything', emoji: '📊', members: '6.2K', desc: 'Honest takes only', newCount: 14, unlock: 'Beginner'),
    CommunityGroup(name: 'Restaurant Roasts', emoji: '🍽', members: '3.8K', desc: 'Honest reviews, no sugar coating, no influencer bias', newCount: 7, unlock: 'Home Cook'),
    CommunityGroup(name: 'Spice Scale Debate', emoji: '🔥', members: '4.1K', desc: 'Is that really a 3-pepper? Prove it.', newCount: 23, unlock: 'Beginner'),
    CommunityGroup(name: 'Hidden Gems', emoji: '💎', members: '9.7K', desc: 'Underrated spots and slept-on recipes', newCount: 11),
    CommunityGroup(name: 'The Pepper Panel', emoji: '🫑', members: '1.2K', desc: 'Elite raters — 50+ ratings required', newCount: 3, unlock: 'Sous Chef'),
  ],
};

class MyGroup {
  const MyGroup({
    required this.name,
    required this.emoji,
    required this.members,
    required this.lastMsg,
    required this.time,
  });

  final String name;
  final String emoji;
  final int members;
  final String lastMsg;
  final String time;
}

const List<MyGroup> mockMyGroups = [
  MyGroup(name: 'Family Dinner Planning', emoji: '🏠', members: 4, lastMsg: 'Jake: Can we have tacos? 🌮', time: '2h'),
  MyGroup(name: 'Roommate Meals', emoji: '🍳', members: 3, lastMsg: "Emma: I'll cook tonight!", time: '5h'),
];

// ── Chat thread ──

class ChatMessage {
  const ChatMessage({
    required this.from,
    this.text,
    this.isRecipe = false,
    this.recipeTitle,
    this.recipeCreator,
    this.recipeMeta,
    this.recipeEmoji = '🌮',
  });

  /// 'me' | 'them'
  final String from;
  final String? text;
  final bool isRecipe;
  final String? recipeTitle;
  final String? recipeCreator;
  final String? recipeMeta;
  final String recipeEmoji;
}

const List<ChatMessage> mockThreadMessages = [
  ChatMessage(from: 'them', text: 'omg you HAVE to try this birria recipe 🌮'),
  ChatMessage(
    from: 'them',
    isRecipe: true,
    recipeTitle: 'Birria Tacos',
    recipeCreator: '@abuelitas_kitchen',
    recipeMeta: '45 min · Medium',
  ),
  ChatMessage(from: 'me', text: "That looks incredible! I've been on a Mexican food kick lately"),
  ChatMessage(from: 'them', text: 'RIGHT? I made it last weekend and my roommates lost their minds 🤯'),
  ChatMessage(from: 'me', text: 'Saving it now! Want to do a cook-along this Friday?'),
  ChatMessage(from: 'them', text: "YES! 🙌 Friday 7pm? I'll prep ingredients Thursday night"),
];

const List<String> mockThreadReplies = [
  'Omg yes! That sounds amazing 🤩',
  "I'm def trying that this weekend! 🍳",
  'Haha so true! Love that 😂',
  'Have you seen the new Korean BBQ recipe? 🥩🔥',
  'Send me the recipe link! I need it 🙏',
];

const List<String> mockThreadQuickReplies = ['Sounds great! 🙌', 'Friday works!', "Can't wait 🔥", 'Send recipe?'];

// ── Notification center ──

class RateTarget {
  const RateTarget({
    required this.name,
    required this.emoji,
    required this.color,
    this.isPlace = false,
  });

  final String name;
  final String emoji;
  final Color color;
  final bool isPlace;
}

class AppNotification {
  const AppNotification({
    required this.icon,
    required this.text,
    required this.time,
    required this.color,
    this.actionLabel,
    this.isSmart = false,
    this.rateTarget,
    this.hasChevron = false,
    this.actionDest,
  });

  final String icon;
  final String text;
  final String time;
  final Color color;
  final String? actionLabel;
  final bool isSmart;
  final RateTarget? rateTarget;
  final bool hasChevron;

  /// Screen to navigate to when tapped/actioned (chevron row or a smart
  /// notification whose action isn't a rating, e.g. "View").
  final AppScreen? actionDest;
}

final List<AppNotification> mockNotifications = [
  AppNotification(
    icon: '📍',
    text: 'We noticed you visited Tanaka Ramen House yesterday. How was it?',
    time: '2m',
    color: AppColors.placesPurple,
    actionLabel: 'Rate Visit',
    isSmart: true,
    rateTarget: const RateTarget(name: 'Tanaka Ramen House', emoji: '🍜', color: AppColors.placesPurple, isPlace: true),
  ),
  AppNotification(
    icon: '🍳',
    text: 'You made Birria Tacos 5 days ago and skipped the rating. Rate now?',
    time: '15m',
    color: AppColors.coral,
    actionLabel: 'Rate Now',
    isSmart: true,
    rateTarget: const RateTarget(name: 'Birria Tacos', emoji: '🌮', color: AppColors.coral),
  ),
  const AppNotification(
    icon: '✨',
    text: 'New Korean Fried Chicken recipe matches your preferences!',
    time: '30m',
    color: AppColors.amber,
    actionLabel: 'View',
    isSmart: true,
    actionDest: AppScreen.recipeDetail,
  ),
  const AppNotification(
    icon: '🧞',
    text: 'Genie found 3 Korean recipes matching your taste!',
    time: '1h',
    color: AppColors.amber,
    hasChevron: true,
    actionDest: AppScreen.genieChat,
  ),
  const AppNotification(
    icon: '👩‍🍳',
    text: '@chefpriya posted a new recipe',
    time: '2h',
    color: AppColors.coral,
    hasChevron: true,
    actionDest: AppScreen.creatorProfile,
  ),
  const AppNotification(
    icon: '❤️',
    text: 'Sarah liked your Birria Tacos cook',
    time: '3h',
    color: AppColors.coral,
    hasChevron: true,
    actionDest: AppScreen.socialFeed,
  ),
  const AppNotification(
    icon: '🏆',
    text: 'Weekend Taco Challenge — 47h remaining!',
    time: '5h',
    color: AppColors.amber,
    hasChevron: true,
    actionDest: AppScreen.competition,
  ),
  const AppNotification(
    icon: '🔥',
    text: '5-day cooking streak! +50 bonus pts',
    time: '1d',
    color: AppColors.amber,
    hasChevron: true,
    actionDest: AppScreen.cookingLevel,
  ),
  const AppNotification(
    icon: '💬',
    text: "Marcus: 'Thanks for the ramen tips!'",
    time: '1d',
    color: AppColors.cyan,
    hasChevron: true,
    actionDest: AppScreen.chatThread,
  ),
  AppNotification(
    icon: '🍸',
    text: 'Did you try that Smoked Old Fashioned you saved? Rate it!',
    time: '2d',
    color: AppColors.drinksBlue,
    actionLabel: 'Rate',
    isSmart: true,
    rateTarget: const RateTarget(name: 'Smoked Old Fashioned', emoji: '🥃', color: AppColors.drinksBlue),
  ),
];
