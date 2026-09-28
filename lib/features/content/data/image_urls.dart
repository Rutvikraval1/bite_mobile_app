/// Pexels image URL helpers — mirror `theme.js` `_P/_I/_S/_A` constants.
abstract final class ImageUrls {
  static const String _base = 'https://images.pexels.com/photos/';
  static const String _large = '?auto=compress&cs=tinysrgb&w=600';
  static const String _small = '?auto=compress&cs=tinysrgb&w=400';
  static const String _avatar = '?auto=compress&cs=tinysrgb&w=80';

  /// Card image (600px).
  static String large(String id) => '$_base$id$_large';

  /// Thumbnail (400px).
  static String small(String id) => '$_base$id$_small';

  /// Tiny avatar crop (80px).
  static String avatar(String id) => '$_base$id$_avatar';
}
