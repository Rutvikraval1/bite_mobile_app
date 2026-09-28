import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar — network image with an emoji fallback. Ports `AvatarImg`.
class AvatarImg extends StatelessWidget {
  const AvatarImg({
    super.key,
    required this.emoji,
    this.imageUrl,
    this.size = 32,
    this.borderWidth = 2,
    this.borderColor = const Color(0xFF0D0D0D),
  });

  final String emoji;
  final String? imageUrl;
  final double size;
  final double borderWidth;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: url != null && url.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _emojiFallback(context),
              placeholder: (_, _) => _emojiFallback(context),
            )
          : _emojiFallback(context),
    );
  }

  Widget _emojiFallback(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}
