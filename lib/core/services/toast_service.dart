import 'dart:async';

/// Global toast bus — ports the `bite-toast` CustomEvent.
class ToastService {
  ToastService._();

  static final ToastService instance = ToastService._();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  /// Automatically clears after [displayDuration] on the widget side.
  Duration get displayDuration => const Duration(milliseconds: 2500);

  void show(String message) {
    if (!_controller.isClosed) {
      _controller.add(message);
    }
  }

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
