import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/services/xp_float_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/glass.dart';
import '../blocs/auth_cubit.dart';
import '../onboarding_edit_mode.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/onboarding_scaffold.dart';

/// Onboarding step 2 — dietary needs. Ports `OnboardingDietaryScreen`.
class OnboardingDietaryScreen extends StatefulWidget {
  const OnboardingDietaryScreen({super.key});

  @override
  State<OnboardingDietaryScreen> createState() =>
      _OnboardingDietaryScreenState();
}

class _OnboardingDietaryScreenState extends State<OnboardingDietaryScreen> {
  static const _sections = [
    _Section(
      label: 'DIET',
      color: AppColors.coral,
      items: [
        'Vegetarian 🥬',
        'Vegan 🌱',
        'Pescatarian 🐟',
        'Keto 🥑',
        'Paleo',
        'Halal',
        'Kosher',
      ],
    ),
    _Section(
      label: 'ALLERGIES',
      color: AppColors.amber,
      items: [
        'Gluten-Free',
        'Dairy-Free 🥛',
        'Nut-Free 🥜',
        'Shellfish-Free 🦐',
        'Egg-Free 🥚',
        'Soy-Free',
      ],
    ),
    _Section(
      label: 'PREFERENCES',
      color: AppColors.cyan,
      items: [
        'Low Sodium',
        'Low Sugar',
        'High Protein 💪',
        'Low Calorie',
        'Organic',
      ],
    ),
  ];

  late List<String> _selected;
  bool _showSkipAlert = false;
  final Map<String, int> _sectionPtsCounts = {};

  @override
  void initState() {
    super.initState();
    final dietary = context.read<AuthCubit>().state.profile?.dietary;
    _selected = dietary == null ? [] : List.of(dietary);
  }

  void _toggle(String item) {
    final isAdding = !_selected.contains(item);
    final sec = _sections.firstWhere((s) => s.items.contains(item));
    final secKey = sec.label;
    final selectedInSection = _selected.where(sec.items.contains).length;

    setState(() {
      if (isAdding) {
        _selected.add(item);
        final newCount = _selected.where(sec.items.contains).length;
        if (newCount <= 2) {
          _sectionPtsCounts[secKey] = newCount;
          XpFloatService.instance.show(
            5,
            x: 15 + (item.hashCode.abs() % 70).toDouble(),
            y: 35,
          );
        }
      } else {
        _selected.remove(item);
        final newCount = _selected.where(sec.items.contains).length;
        if (selectedInSection <= 2 && newCount < selectedInSection) {
          _sectionPtsCounts[secKey] = newCount;
          XpFloatService.instance.show(
            -5,
            x: 15 + (item.hashCode.abs() % 70).toDouble(),
            y: 35,
          );
        }
      }
    });
  }

  void _selectAllSection(_Section sec, int sectionIdx) {
    final secKey = sec.label;
    final currentCount = _sectionPtsCounts[secKey] ?? 0;
    final remaining = (2 - currentCount).clamp(0, 2);
    setState(() {
      _selected = {..._selected, ...sec.items}.toList();
      if (remaining > 0) {
        _sectionPtsCounts[secKey] = 2;
      }
    });
    for (var i = 0; i < remaining; i++) {
      Future<void>.delayed(
        Duration(milliseconds: i * 150 + sectionIdx * 250),
        () {
          XpFloatService.instance.show(
            5,
            x: 15 + (i * 23) % 60,
            y: 22 + sectionIdx * 20,
          );
        },
      );
    }
  }

  void _clearSection(_Section sec, int sectionIdx) {
    final earned = (_sectionPtsCounts[sec.label] ?? 0).clamp(0, 2);
    setState(() {
      _selected = _selected.where((x) => !sec.items.contains(x)).toList();
      _sectionPtsCounts[sec.label] = 0;
    });
    for (var i = 0; i < earned; i++) {
      Future<void>.delayed(Duration(milliseconds: i * 120), () {
        XpFloatService.instance.show(
          -5,
          x: 20 + (i * 30) % 60,
          y: 22 + sectionIdx * 20,
        );
      });
    }
  }

  void _selectAll() {
    for (var i = 0; i < _sections.length; i++) {
      _selectAllSection(_sections[i], i);
    }
  }

  void _clearAll() {
    final totalEarned = _sectionPtsCounts.values.fold<int>(
      0,
      (sum, c) => sum + c.clamp(0, 2),
    );
    setState(() {
      _selected = [];
      _sectionPtsCounts.clear();
    });
    for (var i = 0; i < totalEarned; i++) {
      Future<void>.delayed(Duration(milliseconds: i * 120), () {
        XpFloatService.instance.show(
          -5,
          x: 10 + (i * 12) % 80,
          y: 20 + (i % 3) * 18,
        );
      });
    }
  }

  bool _saving = false;

  /// Saves this step to the `profiles` table (insert or update).
  /// Returns false and shows a toast if the write failed.
  Future<bool> _persist() async {
    setState(() => _saving = true);
    final result = await context.read<AuthCubit>().updateProfile({
      'dietary': _selected,
    });
    if (!mounted) return false;
    setState(() => _saving = false);
    if (!result.isSuccess) {
      ToastService.instance.show("⚠️ Couldn't save. Try again.");
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final n = _selected.length;
    return OnboardingScaffold(
      step: 2,
      title: 'Any dietary needs?',
      subtitle: "We'll filter out what doesn't fit. Select all that apply.",
      onSkip: () {
        if (!OnboardingEditMode.exit(flow)) {
          setState(() => _showSkipAlert = true);
        }
      },
      onBack: () {
        if (!OnboardingEditMode.exit(flow)) {
          flow.setScreen(AppScreen.onboardingCuisine);
        }
      },
      overlay: _showSkipAlert
          ? OnboardingSkipDialog(
              title: 'Skip dietary settings?',
              warning: "⚠️ You'll miss up to 30 onboarding bonus points",
              onSkipStep: () {
                setState(() => _showSkipAlert = false);
                flow.setScreen(AppScreen.onboardingSkill);
              },
              onSkipAll: () {
                setState(() => _showSkipAlert = false);
                flow.skipToHome();
              },
              onClose: () => setState(() => _showSkipAlert = false),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var si = 0; si < _sections.length; si++)
            _section(_sections[si], si),
          const SizedBox(height: 8),
          Glass(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.muted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can always change these in Settings. We\'ll filter recipes based on your selections.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '⚠️ Dietary filters are best-effort and may not catch all ingredients. Always verify ingredients if you have severe allergies or medical dietary restrictions. b🌶te is not a substitute for medical advice. Consult your doctor for allergy-related concerns.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0x26FFFFFF),
              fontSize: 10,
              height: 1.4,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ThumbPill(
                  label: '✓  Select All',
                  color: const Color(0xFF66BB6A),
                  background: const Color(0x0F4CAF50),
                  borderColor: const Color(0x334CAF50),
                  onTap: _selectAll,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ThumbPill(
                  label: '✕  Clear All',
                  color: _selected.isNotEmpty
                      ? AppColors.coral
                      : const Color(0x33FFFFFF),
                  background: _selected.isNotEmpty
                      ? AppColors.coral.withValues(alpha: 0.03)
                      : const Color(0x05FFFFFF),
                  borderColor: _selected.isNotEmpty
                      ? AppColors.coral.withValues(alpha: 0.2)
                      : const Color(0x14FFFFFF),
                  onTap: _clearAll,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            n == 0
                ? 'Select any dietary needs or preferences'
                : n >= 3
                ? '💯 $n+ — dietary perfection!'
                : n >= 2
                ? '✨ $n set — we\'ll filter out what doesn\'t fit!'
                : '👍 1 set — add any others that apply',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: n >= 3
                  ? const Color(0xFF4CAF50)
                  : n >= 1
                  ? AppColors.amber
                  : AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          AuthPrimaryButton(
            label: n >= 3
                ? 'Continue · $n set ✓'
                : n > 0
                ? 'Continue ($n selected)'
                : 'Continue — none apply',
            enabled: !_saving,
            loading: _saving,
            gradient: n >= 3
                ? const [Color(0xFF4CAF50), Color(0xFF66BB6A)]
                : n >= 2
                ? const [AppColors.amber, Color(0xFFFFC107)]
                : n >= 1
                ? [
                    AppColors.coral.withValues(alpha: 0.53),
                    AppColors.coral.withValues(alpha: 0.33),
                  ]
                : null,
            glow: n >= 2,
            onTap: () async {
              if (_saving) return;
              if (await _persist() && mounted) {
                if (!OnboardingEditMode.exit(flow, saved: true)) {
                  flow.setScreen(AppScreen.onboardingSkill);
                }
              }
            },
          ),
          if (_sectionPtsCounts.values.any((c) => c >= 2))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '✨ Max bonus reached for ${_sectionPtsCounts.entries.where((e) => e.value >= 2).map((e) => e.key).join(', ')}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.amber, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(_Section sec, int sectionIdx) {
    final secSelected = sec.items.where(_selected.contains).length;
    final sectionDelay = Duration(milliseconds: sectionIdx * 350);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SlideUp(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sec.label,
                style: TextStyle(
                  color: sec.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  shadows: [
                    Shadow(
                      color: sec.color.withValues(alpha: 0.27),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _SectionPill(
                    label: '✓ All',
                    color: const Color(0xFF66BB6A),
                    background: secSelected == sec.items.length
                        ? const Color(0x264CAF50)
                        : const Color(0x0F4CAF50),
                    borderColor: secSelected == sec.items.length
                        ? const Color(0x664CAF50)
                        : const Color(0x2E4CAF50),
                    onTap: () => _selectAllSection(sec, sectionIdx),
                  ),
                  const SizedBox(width: 6),
                  _SectionPill(
                    label: '✕ Clear',
                    color: secSelected > 0
                        ? AppColors.coral
                        : const Color(0x33FFFFFF),
                    background: secSelected > 0
                        ? AppColors.coral.withValues(alpha: 0.03)
                        : const Color(0x05FFFFFF),
                    borderColor: secSelected > 0
                        ? AppColors.coral.withValues(alpha: 0.16)
                        : const Color(0x0FFFFFFF),
                    onTap: () => _clearSection(sec, sectionIdx),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var ii = 0; ii < sec.items.length; ii++)
              _itemChip(sec, ii, sectionDelay),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _itemChip(_Section sec, int ii, Duration sectionDelay) {
    final item = sec.items[ii];
    final sel = _selected.contains(item);
    final selIdx = _selected.indexOf(item);
    final total = _selected.length;
    final itemColor = !sel
        ? null
        : total >= 4
        ? const Color(0xFF4CAF50)
        : selIdx == 0
        ? AppColors.coral
        : selIdx == 1
        ? AppColors.amber
        : selIdx == 2
        ? const Color(0xFFFFD700)
        : const Color(0xFF4CAF50);
    return SlideUp(
      duration: Duration(milliseconds: 350 + ii * 60),
      child: GestureDetector(
        onTap: () => _toggle(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? itemColor : AppColors.glass,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: sel ? itemColor! : Colors.transparent),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: itemColor!.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Text(
            item,
            style: TextStyle(
              color: sel ? Colors.white : AppColors.muted,
              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _Section {
  const _Section({
    required this.label,
    required this.color,
    required this.items,
  });

  final String label;
  final Color color;
  final List<String> items;
}

class _SectionPill extends StatelessWidget {
  const _SectionPill({
    required this.label,
    required this.color,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ThumbPill extends StatelessWidget {
  const _ThumbPill({
    required this.label,
    required this.color,
    required this.background,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color background;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
