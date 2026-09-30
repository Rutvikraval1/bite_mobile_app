import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image that is disk-cached and decoded at the size it's shown at,
/// not the source resolution. Full-size photo decodes were the main source of
/// memory spikes and jank on the deck and detail screens.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final WidgetBuilder? errorBuilder;

  /// Upper bound for decoded width in physical pixels.
  static const int _maxDecodeWidth = 1440;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final logical = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mq.size.width;
        final decodeWidth = (logical * mq.devicePixelRatio)
            .round()
            .clamp(1, _maxDecodeWidth);
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: width,
          height: height,
          memCacheWidth: decodeWidth,
          fadeInDuration: const Duration(milliseconds: 200),
          errorWidget: (context, _, _) =>
              errorBuilder?.call(context) ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
