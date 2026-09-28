import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_safe_area.dart';
import 'auth_widgets.dart';

/// Shared onboarding scaffold — progress steps, skip, back.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.onSkip,
    required this.onBack,
    required this.child,
    this.overlay,
  });

  final int step; // 1-based
  final String title;
  final String subtitle;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final Widget child;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return AppSafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StepsIndicator(step: step),
                    GestureDetector(
                      onTap: onSkip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x0AFFFFFF),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0x14FFFFFF)),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Color(0x59FFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AuthBackButton(onTap: onBack, label: 'Back'),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 20),
                child,
              ],
            ),
          ),
          ?overlay,
        ],
      ),
    );
  }
}

class _StepsIndicator extends StatelessWidget {
  const _StepsIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const colors = [AppColors.coral, AppColors.amber, AppColors.cyan];
    return Row(
      children: [
        for (var i = 1; i <= 3; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: i == step ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: i < step
                  ? const Color(0xFF4CAF50)
                  : i == step
                  ? colors[step - 1]
                  : const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          'Step $step of 3',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }
}

/// Skip confirm dialog shared by onboarding steps.
class OnboardingSkipDialog extends StatelessWidget {
  const OnboardingSkipDialog({
    super.key,
    required this.title,
    required this.warning,
    required this.onSkipStep,
    required this.onSkipAll,
    required this.onClose,
  });

  final String title;
  final String warning;
  final VoidCallback onSkipStep;
  final VoidCallback onSkipAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () {},
            child: PopIn(
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      warning,
                      style: const TextStyle(
                        color: AppColors.coral,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: onSkipStep,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x0FFFFFFF),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        child: const Text(
                          'Skip This Step →',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onSkipAll,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x15FF6B6B),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0x33FF6B6B)),
                        ),
                        child: const Text(
                          'Skip Entire Tutorial',
                          style: TextStyle(
                            color: AppColors.coral,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
