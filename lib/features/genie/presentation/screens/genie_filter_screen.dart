import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Genie's smart-filter bottom sheet — vibes, cuisine, dietary chips plus
/// precision sliders (calories, protein, sweetness, spiciness). Ports
/// `GenieFilterScreen` from `screens-genie.jsx`.
class GenieFilterScreen extends StatefulWidget {
  const GenieFilterScreen({super.key});

  @override
  State<GenieFilterScreen> createState() => _GenieFilterScreenState();
}

class _GenieFilterScreenState extends State<GenieFilterScreen> {
  static const List<({String emoji, String label})> _vibes = [
    (emoji: '🌙', label: 'Date Night'),
    (emoji: '⚡', label: 'Under 30 Min'),
    (emoji: '📦', label: 'Meal Prep'),
    (emoji: '🛋', label: 'Comfort Food'),
    (emoji: '🎉', label: 'Impress Friends'),
    (emoji: '🥗', label: 'Healthy'),
  ];

  static const List<({String emoji, String label})> _cuisines = [
    (emoji: '🇰🇷', label: 'Korean'),
    (emoji: '🍝', label: 'Italian'),
    (emoji: '🌮', label: 'Mexican'),
    (emoji: '🥘', label: 'Thai'),
    (emoji: '🍔', label: 'American'),
    (emoji: '🍛', label: 'Indian'),
  ];

  static const List<({String emoji, String label})> _dietary = [
    (emoji: '🌱', label: 'Vegetarian'),
    (emoji: '🥬', label: 'Vegan'),
    (emoji: '🚫', label: 'Gluten-Free'),
    (emoji: '🥛', label: 'Dairy-Free'),
  ];

  Set<String> _selectedVibes = {'Under 30 Min', 'Healthy'};
  Set<String> _selectedCuisine = {'Korean'};
  double _calories = 60;
  double _spice = 50;

  void _reset() {
    setState(() {
      _selectedVibes = {};
      _selectedCuisine = {};
      _calories = 60;
      _spice = 50;
    });
    ToastService.instance.show('🔄 Filters reset!');
  }

  Color _spiceColor() {
    if (_spice > 80) return const Color(0xFFD32F2F);
    if (_spice > 60) return const Color(0xFFF44336);
    if (_spice > 40) return const Color(0xFFFF9800);
    if (_spice > 20) return const Color(0xFFFFEB3B);
    return AppColors.saveGreen;
  }

  String _spiceLabel() {
    if (_spice > 80) return '🌶 Fire';
    if (_spice > 60) return '🔴 Hot';
    if (_spice > 40) return '🟠 Medium';
    if (_spice > 20) return '🟡 Mild';
    return '🫑 None';
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final height = MediaQuery.sizeOf(context).height;
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
                                const Text(
                                  'Filter Food 🍽',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _reset,
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(
                                      color: AppColors.coral,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel('VIBES'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final v in _vibes)
                                  _FilterChip(
                                    label: '${v.emoji} ${v.label}',
                                    selected: _selectedVibes.contains(v.label),
                                    onTap: () {
                                      HapticsService.selection();
                                      setState(() {
                                        if (_selectedVibes.contains(v.label)) {
                                          _selectedVibes.remove(v.label);
                                        } else {
                                          _selectedVibes.add(v.label);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel('CUISINE'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in _cuisines)
                                  _FilterChip(
                                    label: '${c.emoji} ${c.label}',
                                    selected: _selectedCuisine.contains(
                                      c.label,
                                    ),
                                    onTap: () {
                                      HapticsService.selection();
                                      setState(() {
                                        if (_selectedCuisine.contains(
                                          c.label,
                                        )) {
                                          _selectedCuisine.remove(c.label);
                                        } else {
                                          _selectedCuisine.add(c.label);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionLabel('DIETARY'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final d in _dietary)
                                  _FilterChip(
                                    label: '${d.emoji} ${d.label}',
                                    selected: false,
                                    onTap: () => ToastService.instance.show(
                                      '✓ Filter toggled',
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _sectionLabel('PRECISION FILTERS'),
                            const SizedBox(height: 16),
                            _SliderRow(
                              label: 'Calories',
                              valueLabel: '200 - 600 cal',
                              value: _calories,
                              activeColor: AppColors.coral,
                              valueColor: AppColors.coral,
                              onChanged: (v) => setState(() => _calories = v),
                            ),
                            const SizedBox(height: 20),
                            _SliderRow(
                              label: 'Protein',
                              valueLabel: '> 20g',
                              value: 40,
                              activeColor: AppColors.coral,
                              valueColor: AppColors.coral,
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: 20),
                            _SliderRow(
                              label: 'Sweetness 🍯',
                              valueLabel: 'Balanced',
                              value: 50,
                              activeColor: AppColors.amber,
                              valueColor: AppColors.amber,
                              onChanged: (_) {},
                              footer: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Dry',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    'Sweet',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildSpicySlider(),
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
                                onPressed: () =>
                                    flow.setScreen(AppScreen.swipeDeck),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.coral,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                                child: const Text(
                                  'Show Recipes 🍽',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '47 recipes match',
                              style: TextStyle(
                                color: AppColors.muted,
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

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    ),
  );

  Widget _buildSpicySlider() {
    final color = _spiceColor();
    final peppers = <({String emoji, double max, Color color})>[
      (emoji: '🫑', max: 20, color: AppColors.saveGreen),
      (emoji: '🟡', max: 40, color: const Color(0xFFFFEB3B)),
      (emoji: '🟠', max: 60, color: const Color(0xFFFF9800)),
      (emoji: '🔴', max: 80, color: const Color(0xFFF44336)),
      (emoji: '🌶', max: 100, color: const Color(0xFFD32F2F)),
    ];
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
              _spiceLabel(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < peppers.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticsService.selection();
                    setState(() => _spice = peppers[i].max);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: _spice >= (i == 0 ? 0 : peppers[i - 1].max)
                          ? peppers[i].color.withValues(alpha: 0.09)
                          : Colors.white.withValues(alpha: 0.02),
                      border: Border(
                        bottom: BorderSide(
                          color: _spice >= (i == 0 ? 0 : peppers[i - 1].max)
                              ? peppers[i].color
                              : Colors.white.withValues(alpha: 0.06),
                          width: 3,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: _spice >= (i == 0 ? 0 : peppers[i - 1].max)
                            ? 1
                            : 0.3,
                        child: Text(
                          peppers[i].emoji,
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
            activeTrackColor: color,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: _spice,
            min: 0,
            max: 100,
            onChanged: (v) => setState(() => _spice = v),
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
    this.footer,
  });

  final String label;
  final String valueLabel;
  final double value;
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
          child: Slider(value: value, min: 0, max: 100, onChanged: onChanged),
        ),
        ?footer,
      ],
    );
  }
}
