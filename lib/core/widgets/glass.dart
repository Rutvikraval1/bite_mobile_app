import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Glassmorphism container — ports the `Glass` primitive.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.padding,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? AppColors.glass,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.glassBorder,
              width: borderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
