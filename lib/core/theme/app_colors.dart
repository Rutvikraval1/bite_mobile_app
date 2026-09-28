import 'package:flutter/material.dart';

/// Brand palette — mirrors `src/bite/theme.js`.
abstract final class AppColors {
  static const Color coral = Color(0xFFFF6B6B);
  static const Color coralDark = Color(0xFFE8625C);
  static const Color amber = Color(0xFFF5A623);
  static const Color cyan = Color(0xFF4ECDC4);
  static const Color drinksBlue = Color(0xFF4A90D9);
  static const Color placesPurple = Color(0xFF9B59B6);

  static const Color bgDark = Color(0xFF0D0D0D);
  static const Color bgCard = Color(0xFF1A1A1A);

  static const Color glass = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color glassBorder = Color(0x1AFFFFFF); // 0.10

  static const Color muted = Color(0x9EFFFFFF); // rgba(255,255,255,0.62)

  static const Color saveGreen = Color(0xFF4CAF50);
  static const Color saveGreenLight = Color(0xFF66BB6A);
  static const Color passNeutral = Color(0xFF9E9E9E);

  static const Color white = Color(0xFFFFFFFF);

  /// Chili logo lockup — rotated to sit inside the "b🌶te" wordmark.
  static const double chiliLogoRotation = -18;
}

/// Emoji-category color/glow helpers ported from `theme.js`.
abstract final class EmojiThemes {
  static const List<String> _meat = ['🍗', '🥩', '🍖', '🐔', '🌮', '🥘', '🍛'];
  static const List<String> _veg = ['🥗', '🥦', '🍜', '🫒', '🥐', '🌿', '🍝', '🥡'];
  static const List<String> _seafood = ['🦞', '🍣', '🐟', '🦐'];
  static const List<String> _drink = [
    '🍹', '🥂', '🍸', '🥃', '💜', '🧋', '🥛', '🍶', '☕', '🍊', '🌸', '🍵',
  ];
  static const List<String> _dessert = ['🍰', '🍩', '🧁', '🥭', '🫐'];

  static String _category(String emoji) {
    if (_meat.contains(emoji)) return 'meat';
    if (_veg.contains(emoji)) return 'veg';
    if (_seafood.contains(emoji)) return 'seafood';
    if (_drink.contains(emoji)) return 'drink';
    if (_dessert.contains(emoji)) return 'dessert';
    return 'other';
  }

  /// Card background gradient by emoji category.
  static List<Color> cardBg(String emoji) {
    switch (_category(emoji)) {
      case 'meat':
        return const [Color(0xFF0A0F2E), Color(0xFF0D1F2B), Color(0xFF0D2B2B)];
      case 'veg':
        return const [Color(0xFF0F0F0F), Color(0xFF0A1A0D), Color(0xFF0F200F)];
      case 'seafood':
        return const [Color(0xFF050D1F), Color(0xFF071A2E), Color(0xFF0A2040)];
      case 'drink':
        return const [Color(0xFF0A0010), Color(0xFF120020), Color(0xFF1A0030)];
      case 'dessert':
        return const [Color(0xFF100800), Color(0xFF1A0A00), Color(0xFF201000)];
      default:
        return const [Color(0xFF0A0A0F), Color(0xFF0F0F18), Color(0xFF12121A)];
    }
  }

  /// Radial plate-glow tint by emoji category.
  static Color plateGlow(String emoji) {
    switch (_category(emoji)) {
      case 'meat':
        return const Color(0x29FFD9A8);
      case 'dessert':
        return const Color(0x2EFFC9A0);
      case 'veg':
        return const Color(0x21B5E0B0);
      case 'seafood':
        return const Color(0x21A8D0E6);
      case 'drink':
        return const Color(0x24D4C5F9);
      default:
        return const Color(0x1FF0E6D2);
    }
  }

  /// Dish accent color by emoji category.
  static Color dishAccent(String emoji) {
    switch (_category(emoji)) {
      case 'meat':
        return const Color(0xFFFFD9A8);
      case 'dessert':
        return const Color(0xFFFFC9A0);
      case 'veg':
        return const Color(0xFFB5E0B0);
      case 'seafood':
        return const Color(0xFFA8D0E6);
      case 'drink':
        return const Color(0xFFD4C5F9);
      default:
        return const Color(0xFFF0E6D2);
    }
  }

  /// Ambient emoji spread around a dish hero.
  static List<String> spreadEmojis(String emoji) {
    const spreads = <String, List<String>>{
      '🍗': ['🌶', '🧄', '🍚', '🥢', '🧅', '🌿'],
      '🍄': ['🧀', '🌿', '🧈', '🍷', '🧅', '🥄'],
      '🥭': ['🍚', '🥥', '🌸', '🍃', '🧈', '✨'],
      '🍣': ['🥢', '🍶', '🫚', '🥑', '🧄', '🌿'],
      '🌮': ['🧅', '🌶', '🫘', '🍋', '🧀', '🌿'],
      '🦞': ['🧀', '🍝', '🧈', '🌿', '🍋', '🥄'],
      '🥘': ['🍚', '🥬', '🧄', '🌶', '🧅', '🫚'],
      '🍳': ['🫑', '🧅', '🌶', '🧀', '🍞', '🧈'],
      '🍛': ['🍚', '🧄', '🌿', '🫚', '🧅', '🌶'],
      '🥡': ['🥜', '🌶', '🧄', '🥬', '🫚', '🥢'],
      '🫒': ['🍋', '🧅', '🌿', '🫓', '🧀', '🍷'],
      '🥐': ['🥚', '🍓', '🧈', '☕', '🍯', '✨'],
      '🍜': ['🥬', '🌿', '🧄', '🫚', '🥢', '🥚'],
      '🐔': ['🫑', '🥒', '🍞', '🧈', '🌶', '🥄'],
      '🐟': ['🥑', '🍋', '🌶', '🥒', '🧄', '🌿'],
      '🥗': ['🍋', '🫒', '🧀', '🥒', '🥑', '🌿'],
      '🍝': ['🧀', '🧄', '🌿', '🍷', '🫒', '🌶'],
      '🫐': ['🍌', '🥥', '🍓', '🍃', '🍯', '✨'],
      '🍸': ['🫒', '🍋', '🍊', '🧊', '🌿', '✨'],
      '🥃': ['🍒', '🍊', '🧊', '🪵', '🌿', '✨'],
      '🍹': ['🍋', '🍓', '🍍', '🌶', '🧊', '🌿'],
      '💜': ['🍇', '🍓', '🫐', '🌸', '🧊', '🌿'],
      '🧋': ['🥥', '🍓', '🫧', '🌸', '🧊', '🍃'],
      '🥛': ['🍓', '🍌', '🥭', '🍯', '🧊', '✨'],
      '🍶': ['🍋', '🌸', '🫚', '❄', '🧊', '🌿'],
      '☕': ['🥥', '🍫', '🌰', '🍃', '🧊', '🍯'],
      '🍊': ['🍋', '🍓', '🌸', '🍃', '🧊', '✨'],
      '🌸': ['🍊', '🍋', '🍇', '✨', '🧊', '🌿'],
      '🍵': ['🍃', '🌸', '🍯', '🌰', '🧊', '✨'],
      '🌿': ['🍋', '🫐', '🍓', '✨', '🌸', '🍃'],
      '🍷': ['🍇', '🧀', '🌰', '🍒', '🌿', '✨'],
      '🍺': ['🌾', '🍋', '🥨', '🍊', '🌿', '✨'],
      '🥂': ['🍓', '🍇', '✨', '🌸', '🧊', '🌿'],
    };
    return spreads[emoji] ?? const ['✨', '🍃', '🌶', '🧄', '🧅', '🌿'];
  }
}
