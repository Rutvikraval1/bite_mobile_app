import 'dart:async';

import 'package:flutter/material.dart';

import '../services/toast_service.dart';
import '../theme/app_colors.dart';
import 'animations/entrance.dart';

/// Renders global toast messages fed by [ToastService].
class ToastOverlay extends StatefulWidget {
  const ToastOverlay({super.key});

  @override
  State<ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<ToastOverlay> {
  StreamSubscription<String>? _sub;
  String? _current;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _sub = ToastService.instance.stream.listen((message) {
      if (!mounted) return;
      setState(() => _current = message);
      _hideTimer?.cancel();
      _hideTimer = Timer(ToastService.instance.displayDuration, () {
        if (mounted) setState(() => _current = null);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _current;
    if (message == null) return const SizedBox.shrink();
    return Positioned(
      left: 20,
      right: 20,
      bottom: 110,
      child: SlideUp(
        key: ValueKey(message),
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
