import 'dart:async';

/// A badge-award request — ports the `bite-badge-award` CustomEvent.
class BadgeAward {
  const BadgeAward({required this.ids});

  final List<String> ids;
}

/// Global badge-award bus consumed by the gamification layer.
class BadgeService {
  BadgeService._();

  static final BadgeService instance = BadgeService._();

  final StreamController<List<String>> _controller =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get stream => _controller.stream;

  void award(List<String> ids) {
    if (ids.isEmpty || _controller.isClosed) return;
    _controller.add(ids);
  }

  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}
