import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'avatar_img.dart';

/// Stacked avatar cluster — ports `SocialProofAvatars` from `ui.jsx`.
class SocialProofAvatars extends StatelessWidget {
  const SocialProofAvatars({super.key, required this.urls, this.count = 4, this.size = 20});

  final List<String> urls;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final shown = count.clamp(0, urls.length);
    final step = size * 0.6;
    final totalWidth = shown == 0 ? 0.0 : size + (shown - 1) * step;
    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown; i++)
            Positioned(
              left: i * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bgDark, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: AvatarImg(emoji: '👤', imageUrl: urls[i % urls.length]),
              ),
            ),
        ],
      ),
    );
  }
}
