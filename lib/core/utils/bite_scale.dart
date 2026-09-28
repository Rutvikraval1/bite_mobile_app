import 'package:flutter/widgets.dart';

/// Responsive sizing helper — ports `useBiteScale()` from `utils.js`.
///
/// The app renders inside a max-width [core.config.AppConfig.maxFrameWidth]
/// frame; this class exposes the same width/height tiers the prototype used
/// to scale typography, spacing and the bottom nav.
class BiteScale {
  const BiteScale({required this.width, required this.height});

  factory BiteScale.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return BiteScale(width: size.width, height: size.height);
  }

  final double width;
  final double height;

  /// width tiers: xs(≤360) s(≤390) m(≤420) l(≤480) xl(>480)
  String get widthTier {
    if (width <= 360) return 'xs';
    if (width <= 390) return 's';
    if (width <= 420) return 'm';
    if (width <= 480) return 'l';
    return 'xl';
  }

  bool get isXS => widthTier == 'xs';
  bool get isS => widthTier == 's';
  bool get isTiny => height < 600;
  bool get isCompact => height < 750;
  bool get isSmall => isXS || isTiny;
  bool get isMedium => isS || isCompact;

  /// Bottom nav collapses when the frame is short.
  bool get navTiny => height < 600;

  @override
  String toString() =>
      'BiteScale(${width.toStringAsFixed(0)}x${height.toStringAsFixed(0)})';
}
