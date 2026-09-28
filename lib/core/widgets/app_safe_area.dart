import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Common full-screen shell: an edge-to-edge background (so color/gradient
/// extends behind the notch, status bar, and home indicator) with [child]
/// inset from the device's unsafe areas via [SafeArea].
///
/// Use this instead of hand-rolling `Container(color: ...) + SafeArea(...)`
/// on every screen.
class AppSafeArea extends StatelessWidget {
  const AppSafeArea({
    super.key,
    required this.child,
    this.color = AppColors.bgDark,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
    this.minimum = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  final EdgeInsets minimum;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: color,
      child: SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        minimum: minimum,
        child: child,
      ),
    );
  }
}
