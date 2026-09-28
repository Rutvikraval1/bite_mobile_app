import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_safe_area.dart';
import '../../../../core/widgets/glass.dart';

/// Shared labeled input used across auth screens.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.onTap,
    this.onChanged,
    this.obscure = false,
    this.keyboardType,
    this.prefix,
    this.errorText,
    this.suffix,
    this.valid = false,
    this.maxLength,
    this.filled,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? prefix;
  final String? errorText;
  final Widget? suffix;
  final bool valid;
  final int? maxLength;
  final bool? filled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (suffix != null) ...[const SizedBox(width: 6), suffix!],
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              obscureText: obscure,
              keyboardType: keyboardType,
              maxLength: maxLength,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                counterText: '',
                prefixText: prefix,
                errorText: errorText,
                fillColor: filled ?? false ? AppColors.glass : AppColors.glass,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: valid
                        ? AppColors.coral.withValues(alpha: 0.25)
                        : AppColors.glassBorder,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Primary pill CTA button.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
    this.color = AppColors.coral,
    this.gradient,
    this.glow = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool loading;
  final Color color;
  final List<Color>? gradient;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final usable = enabled && !loading;
    return GestureDetector(
      onTap: usable ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: gradient != null
                ? LinearGradient(colors: gradient!)
                : null,
            color: gradient != null ? null : color,
            borderRadius: BorderRadius.circular(100),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
        ),
      ),
    );
  }
}

/// Auth screen shell with centered content.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppSafeArea(
      child: SingleChildScrollView(
        padding: padding,
        child: Material(color: Colors.transparent, child: child),
      ),
    );
  }
}

/// Back button used at the top of auth screens.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onTap, this.label = 'Back'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_ios_new,
              size: 14,
              color: AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// "or" divider.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0x1AFFFFFF))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: TextStyle(color: Color(0x40FFFFFF), fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Color(0x1AFFFFFF))),
      ],
    );
  }
}

/// OAuth row (Google / Apple).
class OAuthRow extends StatelessWidget {
  const OAuthRow({super.key, required this.onGoogle, required this.onApple});

  final VoidCallback onGoogle;
  final VoidCallback onApple;

  @override
  Widget build(BuildContext context) {
    Widget button(String label, String emoji, VoidCallback onTap) {
      return Expanded(
        child: Glass(
          onTap: onTap,
          borderRadius: 100,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        button('Google', 'G', onGoogle),
        const SizedBox(width: 12),
        button('Apple', '', onApple),
      ],
    );
  }
}

/// Error banner shown above the submit button.
class AuthErrorText extends StatelessWidget {
  const AuthErrorText({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ZoomIn(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.coral,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
