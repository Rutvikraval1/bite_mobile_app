import 'dart:async';

/// A floating "+XP" particle — ports the `bite-xp-float` CustomEvent.
class XpFloat {
  const XpFloat({required this.id, required this.points, this.x, this.y});

  final int id;
  final int points;
  final double? x;
  final double? y;
}

/// Global XP-float bus.
class XpFloatService {
  XpFloatService._();

  static final XpFloatService instance = XpFloatService._();

  final StreamController<XpFloat> _controller =
      StreamController<XpFloat>.broadcast();

  Stream<XpFloat> get stream => _controller.stream;

  /// Visible for [displayDuration] then auto-removed by the overlay host.
  Duration get displayDuration => const Duration(milliseconds: 1800);

  int _idCounter = 0;

  void show(int points, {double? x, double? y}) {
    if (_controller.isClosed) return;
    _controller.add(XpFloat(
      id: _idCounter++,
      points: points,
      x: x,
      y: y,
    ));
  }

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
