import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A single chat bubble — mirrors the JS `{ from, text }` shape.
@immutable
class GenieChatMessage {
  const GenieChatMessage({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

/// A recipe suggestion card shown inline in the Genie chat.
@immutable
class GenieRecipeSuggestion {
  const GenieRecipeSuggestion({
    required this.title,
    required this.time,
    required this.difficulty,
    required this.emoji,
    required this.color,
  });

  final String title;
  final String time;
  final String difficulty;
  final String emoji;
  final Color color;
}

/// Canned "AI" chat content + a tiny keyword-matching reply engine.
///
/// There is no real LLM backend (see repo constraints) — this mirrors the
/// prototype's `genieResponses` map and typing-delay illusion exactly:
/// a fixed greeting/surprise reply plus a random pick from a default pool,
/// keyed off simple keyword matches in the user's message.
abstract final class GenieChatData {
  GenieChatData._();

  static const List<GenieChatMessage> seedMessages = [
    GenieChatMessage(
      fromUser: false,
      text:
          "Hey! 👋 I'm your Food Genie. I know you're into spicy Korean "
          'food and quick weeknight meals. What are we cooking today?',
    ),
    GenieChatMessage(
      fromUser: true,
      text:
          'I have chicken thighs and a bunch of vegetables. Something '
          'spicy and under 30 minutes?',
    ),
    GenieChatMessage(
      fromUser: false,
      text: "Ooh, I've got 3 ideas based on what you like:",
    ),
  ];

  static const List<GenieRecipeSuggestion> suggestions = [
    GenieRecipeSuggestion(
      title: 'Spicy Chicken Stir-Fry',
      time: '20 min',
      difficulty: 'Easy',
      emoji: '🍗',
      color: AppColors.coral,
    ),
    GenieRecipeSuggestion(
      title: 'Thai Basil Chicken',
      time: '25 min',
      difficulty: 'Medium',
      emoji: '🍗',
      color: AppColors.amber,
    ),
    GenieRecipeSuggestion(
      title: 'Firecracker Chicken',
      time: '22 min',
      difficulty: 'Easy',
      emoji: '🍗',
      color: AppColors.cyan,
    ),
  ];

  static const String followUp =
      'The stir-fry is your fastest option. Want me to add any to your deck? 🌶';

  static const List<String> quickReplies = [
    'Show me the stir-fry',
    'Something different',
    'Surprise me',
  ];

  static const List<String> _defaultResponses = [
    "Great question! Based on your taste profile, I'd suggest trying "
        'something with gochujang — it’s trending right now 🔥',
    'I love your vibe! Let me pull up some recipes that match. Check the '
        'deck for new suggestions! 🌶',
    'Hmm, interesting! I found 3 recipes that fit. Swipe through your deck '
        '— I’ve bumped them to the top 🧞',
  ];

  static const String greeting =
      'Hey there! Ready to discover something delicious? Tell me what '
      "you're in the mood for, or I can surprise you! 🧞‍♂️";

  static const String surprise =
      "Okay, chef — I'm feeling Butter Chicken with Coconut Jasmine Rice "
      'tonight. Trust me on this one 🔥 Check your deck!';

  static final Random _random = Random();

  /// Picks a canned reply for [userMessage] — keyword match first, else a
  /// random pick from the default pool (mirrors the JS `handleSend`).
  static String replyFor(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('hi') ||
        lower.contains('hey') ||
        lower.contains('hello')) {
      return greeting;
    }
    if (lower.contains('surprise') ||
        lower.contains('random') ||
        lower.contains('anything')) {
      return surprise;
    }
    return _defaultResponses[_random.nextInt(_defaultResponses.length)];
  }

  /// Reply used for quick-reply chip taps — mirrors the JS `c.includes`
  /// check plus `default[i % length]` indexing.
  static String replyForQuickReply(String chip, int index) {
    if (chip.contains('Surprise')) return surprise;
    return _defaultResponses[index % _defaultResponses.length];
  }
}
