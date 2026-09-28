/// Minimal debounce helper matching `utils.js` `debounced()`.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  final Duration delay;
  final Map<String, bool> _locked = {};

  /// Runs [fn] once per [delay] window for the given [key].
  void run(String key, void Function() fn) {
    if (_locked[key] ?? false) return;
    _locked[key] = true;
    fn();
    Future<void>.delayed(delay, () => _locked[key] = false);
  }

  void clear() => _locked.clear();
}
