import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../../content/domain/entities/bite_card.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../data/genie_filter_store.dart';
import '../../domain/genie_filters.dart';

/// Genie's smart-filter bottom sheet — vibes, cuisine, dietary chips plus
/// precision controls (max time, difficulty, spiciness). Ports
/// `GenieFilterScreen` from `screens-genie.jsx`.
///
/// Selections are saved per user to `profiles.genie_filters` (with a device
/// cache as offline fallback), restored on open, and applied to the swipe
/// deck via [GenieFilterStore] when the user taps "Show". Every chip and
/// slider maps to real card data (tags, cuisine, time, difficulty, heat) and
/// the match count is computed live from the loaded catalog.
class GenieFilterScreen extends StatefulWidget {
  const GenieFilterScreen({super.key});

  @override
  State<GenieFilterScreen> createState() => _GenieFilterScreenState();
}

class _GenieFilterScreenState extends State<GenieFilterScreen> {
  static const List<({String emoji, String label, Color color})> _heatLevels =
      [
        (emoji: '🫑', label: '🫑 No heat', color: AppColors.saveGreen),
        (emoji: '🟡', label: '🟡 Up to mild', color: Color(0xFFFFEB3B)),
        (emoji: '🟠', label: '🟠 Up to medium', color: Color(0xFFFF9800)),
        (emoji: '🔴', label: '🔴 Up to hot', color: Color(0xFFF44336)),
        (emoji: '🌶', label: '🌶 Any heat', color: Color(0xFFD32F2F)),
      ];

  final GenieFilterStore _store = GenieFilterStore.instance;

  late final GenieFilterKind _kind;
  GenieFilters _filters = GenieFilters.empty;
  GenieFiltersSnapshot _snapshot = const GenieFiltersSnapshot(
    byKind: {},
    hasSaved: false,
  );
  bool _loading = true;
  bool _saving = false;

  String? get _userId => context.read<AuthCubit>().state.user?.id;

  bool get _isDrinks => _kind == GenieFilterKind.drinks;

  @override
  void initState() {
    super.initState();
    final tab = context.read<AppStateCubit>().state.subTab;
    _kind = GenieFilterStore.kindFor(tab) ?? GenieFilterKind.food;
    // Show what's currently applied right away, then refresh from the DB.
    final applied = _store.applied.value[_kind];
    if (applied != null) {
      _filters = applied;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final snapshot = await _store.load(_userId);
    if (!mounted) return;
    var filters = snapshot.of(_kind);
    if (!snapshot.hasSaved && _kind == GenieFilterKind.food) {
      // First time: start from the dietary needs chosen in onboarding.
      final dietary = context.read<AuthCubit>().state.profile?.dietary;
      if (dietary != null && dietary.isNotEmpty) {
        filters = filters.copyWith(
          dietary: GenieFilters.dietaryFromProfile(dietary),
        );
      }
    }
    setState(() {
      _snapshot = snapshot;
      // Don't clobber edits the user made while the load was in flight.
      if (_loading) _filters = filters;
      _loading = false;
    });
  }

  List<BiteCard> _pool(ContentState content) =>
      _isDrinks ? content.drinks : content.recipes;

  Future<void> _reset() async {
    HapticsService.light();
    setState(() {
      _filters = GenieFilters.empty;
      _saving = true;
    });
    final error = await _store.reset(_userId, _kind, _snapshot);
    if (!mounted) return;
    setState(() {
      _snapshot = GenieFiltersSnapshot(
        byKind: {..._snapshot.byKind}..remove(_kind),
        hasSaved: _snapshot.byKind.length > 1,
      );
      _saving = false;
    });
    ToastService.instance.show(error == null ? '🔄 Filters cleared' : '⚠️ $error');
  }

  Future<void> _apply(int matchCount) async {
    if (_saving) return;
    HapticsService.medium();
    setState(() => _saving = true);
    final userId = _userId;
    final error = await _store.save(userId, _kind, _filters, _snapshot);
    if (!mounted) return;
    setState(() => _saving = false);
    if (_filters.isEmpty) {
      _store.deactivate(_kind);
    } else {
      _store.activate(userId, _kind, _filters);
    }
    final noun = _isDrinks ? 'drinks' : 'recipes';
    ToastService.instance.show(
      error != null
          ? '⚠️ $error'
          : _filters.isEmpty
          ? '🍽 Showing all $noun'
          : '🎯 Showing $matchCount matching $noun',
    );
    final appState = context.read<AppStateCubit>();
    appState.setSubTab(_isDrinks ? DeckTab.drinks : DeckTab.food);
    appState.setActiveCardIndex(0);
    context.read<FlowCubit>().setScreen(AppScreen.swipeDeck);
  }

  Set<String> _toggle(Set<String> set, String value) {
    HapticsService.selection();
    final next = {...set};
    if (!next.remove(value)) next.add(value);
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final height = MediaQuery.sizeOf(context).height;
    final content = context.watch<ContentCubit>().state;
    final favorites = context.select<AppStateCubit, List<String>>(
      (c) => c.state.userCuisines,
    );
    final pool = _pool(content);
    final matches = _filters.apply(pool, _kind).length;
    final vibes = GenieFilterCatalog.vibesFor(_kind);
    final dietary = GenieFilterCatalog.dietaryFor(_kind);
    final cuisines = _cuisineOptions(pool, favorites);
    final noun = _isDrinks ? 'drinks' : 'recipes';

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: flow.goBack,
            // ClipRect bounds the blur to this layer's own rect.
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: height * 0.82),
                height: height * 0.78,
                decoration: const BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: flow.goBack,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isDrinks
                                      ? 'Filter Drinks 🍹'
                                      : 'Filter Food 🍽',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _saving || _loading ? null : _reset,
                                  child: Text(
                                    'Reset',
                                    style: TextStyle(
                                      color: _filters.isEmpty
                                          ? AppColors.muted
                                          : AppColors.coral,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_snapshot.fromCache) ...[
                              const SizedBox(height: 6),
                              const Text(
                                'Offline — showing filters saved on this device',
                                style: TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (_loading)
                              const Padding(
                                padding: EdgeInsets.only(top: 40),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.coral,
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              _chipSection(
                                vibes.title,
                                [
                                  for (final o in vibes.options)
                                    (label: o.label, emoji: o.emoji),
                                ],
                                _filters.vibes,
                                (v) => setState(
                                  () => _filters = _filters.copyWith(
                                    vibes: _toggle(_filters.vibes, v),
                                  ),
                                ),
                              ),
                              if (cuisines.isNotEmpty)
                                _chipSection(
                                  'CUISINE',
                                  cuisines,
                                  _filters.cuisines,
                                  (v) => setState(
                                    () => _filters = _filters.copyWith(
                                      cuisines: _toggle(_filters.cuisines, v),
                                    ),
                                  ),
                                ),
                              _chipSection(
                                dietary.title,
                                [
                                  for (final o in dietary.options)
                                    (label: o.label, emoji: o.emoji),
                                ],
                                _filters.dietary,
                                (v) => setState(
                                  () => _filters = _filters.copyWith(
                                    dietary: _toggle(_filters.dietary, v),
                                  ),
                                ),
                              ),
                              if (!_isDrinks) ...[
                                const SizedBox(height: 4),
                                _sectionLabel('PRECISION FILTERS'),
                                const SizedBox(height: 16),
                                _buildTimeSlider(),
                                const SizedBox(height: 20),
                                _chipSection(
                                  'DIFFICULTY',
                                  [
                                    for (final d
                                        in GenieFilterCatalog.difficulties)
                                      (label: d, emoji: ''),
                                  ],
                                  _filters.difficulty,
                                  (v) => setState(
                                    () => _filters = _filters.copyWith(
                                      difficulty: _toggle(
                                        _filters.difficulty,
                                        v,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildSpicySlider(),
                              ],
                            ],
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    _loading ||
                                        _saving ||
                                        content.loading ||
                                        matches == 0
                                    ? null
                                    : () => _apply(matches),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.coral,
                                  disabledBackgroundColor: AppColors.coral
                                      .withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        _isDrinks
                                            ? 'Show Drinks 🍹'
                                            : 'Show Recipes 🍽',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              content.loading
                                  ? 'Loading $noun…'
                                  : matches == 0
                                  ? 'No $noun match — try removing a filter'
                                  : '$matches of ${pool.length} $noun match',
                              style: TextStyle(
                                color: matches == 0 && !content.loading
                                    ? AppColors.coral
                                    : AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cuisines present in the catalog, the user's favorites first, plus any
  /// saved selection no longer in the catalog (so it can be deselected).
  List<({String label, String emoji})> _cuisineOptions(
    List<BiteCard> pool,
    List<String> favorites,
  ) {
    final names = GenieFilters.cuisinesIn(pool);
    final fav = {for (final f in favorites) f.toLowerCase()};
    names.sort((a, b) {
      final fa = fav.contains(a.toLowerCase()) ? 0 : 1;
      final fb = fav.contains(b.toLowerCase()) ? 0 : 1;
      return fa.compareTo(fb);
    });
    for (final s in _filters.cuisines) {
      if (!names.contains(s)) names.add(s);
    }
    return [
      for (final n in names)
        (label: n, emoji: GenieFilterCatalog.cuisineEmoji(n)),
    ];
  }

  Widget _chipSection(
    String title,
    List<({String label, String emoji})> options,
    Set<String> selected,
    ValueChanged<String> onToggle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(title),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in options)
                _FilterChip(
                  label: o.emoji.isEmpty ? o.label : '${o.emoji} ${o.label}',
                  selected: selected.contains(o.label),
                  onTap: () => onToggle(o.label),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    ),
  );

  Widget _buildTimeSlider() {
    final value = (_filters.maxMinutes ?? GenieFilters.minutesCap).toDouble();
    final any = _filters.maxMinutes == null;
    return _SliderRow(
      label: 'Total time ⏱',
      valueLabel: any ? 'Any time' : '≤ ${_filters.maxMinutes} min',
      value: value,
      min: 10,
      max: GenieFilters.minutesCap.toDouble(),
      divisions: (GenieFilters.minutesCap - 10) ~/ 5,
      activeColor: AppColors.coral,
      valueColor: AppColors.coral,
      onChanged: (v) {
        final mins = v.round();
        setState(
          () => _filters = mins >= GenieFilters.minutesCap
              ? _filters.copyWith(clearMaxMinutes: true)
              : _filters.copyWith(maxMinutes: mins),
        );
      },
      footer: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('10 min', style: TextStyle(color: AppColors.muted, fontSize: 10)),
          Text('Any', style: TextStyle(color: AppColors.muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSpicySlider() {
    // Level 0..3 caps the dish's heat; level 4 means no cap.
    final level = _filters.maxHeat ?? GenieFilters.heatCap;
    final current = _heatLevels[level.clamp(0, _heatLevels.length - 1)];

    void setLevel(int l) {
      setState(
        () => _filters = l >= GenieFilters.heatCap
            ? _filters.copyWith(clearMaxHeat: true)
            : _filters.copyWith(maxHeat: l),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Spiciness',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              current.label,
              style: TextStyle(
                color: current.color,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _heatLevels.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticsService.selection();
                    setLevel(i);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: i <= level
                          ? _heatLevels[i].color.withValues(alpha: 0.09)
                          : Colors.white.withValues(alpha: 0.02),
                      border: Border(
                        bottom: BorderSide(
                          color: i <= level
                              ? _heatLevels[i].color
                              : Colors.white.withValues(alpha: 0.06),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: i <= level ? 1 : 0.3,
                        child: Text(
                          _heatLevels[i].emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: current.color,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: level.toDouble(),
            min: 0,
            max: GenieFilters.heatCap.toDouble(),
            divisions: GenieFilters.heatCap,
            onChanged: (v) => setLevel(v.round()),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : AppColors.glass,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.activeColor,
    required this.valueColor,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.footer,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Color activeColor;
  final Color valueColor;
  final ValueChanged<double> onChanged;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              valueLabel,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: activeColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        ?footer,
      ],
    );
  }
}
