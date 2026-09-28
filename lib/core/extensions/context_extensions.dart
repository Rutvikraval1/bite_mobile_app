import 'package:flutter/material.dart';

import '../services/toast_service.dart';

/// Context extensions used across the app.
extension BuildContextX on BuildContext {
  /// Shortcut to push a new route (when using go_router adapters).
  void pop() => Navigator.of(this).pop();

  /// Whether the device has reduced-motion enabled (mirrors
  /// `prefers-reduced-motion`).
  bool get reduceMotion => MediaQuery.of(this).disableAnimations;

  /// Width of the prototype frame (capped at [maxFrameWidth]).
  Size get biteSize => MediaQuery.sizeOf(this);

  /// True when the frame is shown on a wide screen (web/desktop).
  bool get isWide => biteSize.width > 500;

  void showToast(String message) =>
      ToastService.instance.show(message);
}
