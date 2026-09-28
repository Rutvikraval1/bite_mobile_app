/// Form validation helpers — mirrors `src/lib/validation.ts`.
library;

import '../extensions/string_extensions.dart';

abstract final class Validators {
  static final RegExp _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValidEmail(String email) => _emailRe.hasMatch(email.trim());

  /// Password rules: min 8 chars, one uppercase, one digit.
  static String? validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password needs an uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password needs a number';
    }
    return null;
  }

  static String normalizeUsername(String raw) => raw.toUsernameSafe();

  static String? validateUsername(String username) {
    final clean = normalizeUsername(username);
    if (clean.length < 3) return 'Username must be at least 3 characters';
    if (clean.length > 20) return 'Username must be 20 characters or fewer';
    return null;
  }

  /// Profile is "complete" when display name ≥2 chars and username ≥3 chars.
  static bool isProfileComplete({
    required String displayName,
    required String username,
  }) {
    return displayName.trim().length >= 2 && username.trim().length >= 3;
  }

  /// Age (years) from a birth date.
  static int ageFrom(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Drinks gate: birth year ≤ 2005 ⇒ 21+ in 2026.
  static bool isOfDrinkingAge(int year) => year <= 2005;
}
