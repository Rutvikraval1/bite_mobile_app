import 'dart:ui';

import 'package:flutter/widgets.dart';

/// Backdrop blur for the bottom detail sheets.
///
/// The sheet ([child]) is opaque and covers the bottom [sheetHeightFactor]
/// of the screen, so the blur is only visible in the strip above it (plus
/// the sheet's rounded top corners). Instead of wrapping the whole screen in
/// a [BackdropFilter] — a full-screen blur re-rasterized on every scroll or
/// animation frame — the filter is clipped to that strip.
class SheetBackdropBlur extends StatelessWidget {
  const SheetBackdropBlur({
    super.key,
    required this.child,
    this.sigma = 8,
    this.sheetHeightFactor = 0.88,
    this.cornerRadius = 24,
  });

  final Widget child;
  final double sigma;
  final double sheetHeightFactor;
  final double cornerRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stripHeight =
            constraints.maxHeight * (1 - sheetHeightFactor) + cornerRadius;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: stripHeight.clamp(0.0, constraints.maxHeight),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            child,
          ],
        );
      },
    );
  }
}
