import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable loading / empty / error states — ports `states.tsx`.
/// Styled to match the b🌶te dark theme.

class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.label = 'Loading…',
    this.height,
    this.backgroundColor = AppColors.bgDark,
  });

  final String label;
  final double? height;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? MediaQuery.sizeOf(context).height,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.coral,
              backgroundColor: AppColors.coral.withValues(alpha: 0.13),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.emoji = '🍽',
    this.title = 'Nothing here yet',
    this.message = 'Check back soon — new dishes are on the way.',
    this.action,
    this.compact = false,
  });

  final String emoji;
  final String title;
  final String message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: compact ? 0 : 200),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 16 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: compact ? 28 : 40)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = "We couldn't load your content. Check your connection and try again.",
    this.onRetry,
    this.backgroundColor = AppColors.bgDark,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.19)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.coral,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Wires a fetched list up to the four states above — Loading while
/// [loading] and nothing has arrived yet, Error when [error] is set with no
/// data to fall back on, Empty once loaded with no items, else [builder]
/// renders the success view. Pass [loadingBuilder]/[emptyBuilder]/
/// [errorBuilder] to swap in screen-specific looks (e.g. a bespoke shimmer
/// skeleton) while keeping this same state-selection structure.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.loading,
    required this.error,
    required this.items,
    required this.builder,
    this.onRetry,
    this.loadingBuilder,
    this.emptyBuilder,
    this.errorBuilder,
  });

  final bool loading;
  final String? error;
  final List<T> items;
  final Widget Function(BuildContext context, List<T> items) builder;
  final VoidCallback? onRetry;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (loading && items.isEmpty) {
      return (loadingBuilder ?? (_) => const LoadingState())(context);
    }
    if (error != null && items.isEmpty) {
      return (errorBuilder ?? (_) => ErrorState(message: error!, onRetry: onRetry))(context);
    }
    if (items.isEmpty) {
      return (emptyBuilder ?? (_) => const EmptyState())(context);
    }
    return builder(context, items);
  }
}
