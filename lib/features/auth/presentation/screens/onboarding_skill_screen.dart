import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/services/xp_float_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../blocs/auth_cubit.dart';
import '../onboarding_edit_mode.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/onboarding_scaffold.dart';

/// Onboarding step 3 — skill, spice/sweetness, goals. Ports `OnboardingSkillScreen`.
class OnboardingSkillScreen extends StatefulWidget {
  const OnboardingSkillScreen({super.key});

  @override
  State<OnboardingSkillScreen> createState() => _OnboardingSkillScreenState();
}

class _OnboardingSkillScreenState extends State<OnboardingSkillScreen> {
  static const _skillLevels = [
    _SkillLevel(
      id: 'beginner',
      emoji: '🍳',
      label: 'Beginner',
      desc: 'I can follow a recipe but still learning',
      color: Color(0xFF4CAF50),
    ),
    _SkillLevel(
      id: 'intermediate',
      emoji: '👨‍🍳',
      label: 'Intermediate',
      desc: 'Comfortable in the kitchen, up for a challenge',
      color: Color(0xFFFF9800),
    ),
    _SkillLevel(
      id: 'advanced',
      emoji: '🧑‍🍳',
      label: 'Advanced',
      desc: 'I improvise, experiment, and create my own',
      color: Color(0xFFF44336),
    ),
  ];
  static const _goalOptions = [
    'Find new recipes 🍽',
    'Eat healthier 🥗',
    'Learn to cook 📚',
    'Share my recipes 📸',
    'Meal prep 📦',
    'Just for fun 🎉',
    'Find cooking community 👥',
  ];
  static const _spicePeppers = [
    _Level(emoji: '🫑', label: 'None', color: Color(0xFF4CAF50)),
    _Level(emoji: '🟡', label: 'Mild', color: Color(0xFFFFEB3B)),
    _Level(emoji: '🟠', label: 'Medium', color: Color(0xFFFF9800)),
    _Level(emoji: '🔴', label: 'Hot', color: Color(0xFFF44336)),
    _Level(emoji: '🌶', label: 'Fire', color: Color(0xFFD32F2F)),
  ];
  static const _sweetLevels = [
    _Level(emoji: '🚫', label: 'None', color: AppColors.muted),
    _Level(emoji: '🤏', label: 'A little', color: Color(0xFF90CAF9)),
    _Level(emoji: '😋', label: 'Balanced', color: Color(0xFF64B5F6)),
    _Level(emoji: '🍯', label: 'Sweet', color: AppColors.amber),
    _Level(emoji: '🍭', label: 'Very Sweet', color: Color(0xFFF48FB1)),
  ];

  String? _skill;
  late List<String> _goals;
  int _spiceLevel = 2;
  int _sweetLevel = 2;
  final Set<String> _earnedKeys = {};
  bool _showSkipConfirm = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthCubit>().state.profile;
    _skill = profile?.cookingSkill;
    _goals = (profile?.cookingGoal ?? '')
        .split(', ')
        .where((g) => g.isNotEmpty)
        .toList();
  }

  void _addPts(String key, int pts) {
    if (_earnedKeys.contains(key)) return;
    setState(() => _earnedKeys.add(key));
    XpFloatService.instance.show(pts, x: 20 + (pts % 60).toDouble(), y: 35);
  }

  bool _saving = false;

  /// Saves skill + goals to the `profiles` table (insert or update).
  /// Returns false and shows a toast if the write failed.
  Future<bool> _persist() async {
    final skill = _skill;
    if (skill == null) return true;
    setState(() => _saving = true);
    final result = await context.read<AuthCubit>().updateProfile({
      'cooking_skill': skill,
      'cooking_goal': _goals.isEmpty ? null : _goals.join(', '),
    });
    if (!mounted) return false;
    setState(() => _saving = false);
    if (!result.isSuccess) {
      ToastService.instance.show("⚠️ Couldn't save. Try again.");
      return false;
    }
    return true;
  }

  void _toggleGoal(String g) {
    final sel = _goals.contains(g);
    setState(() {
      if (sel) {
        final withinRange = _goals.length <= 2;
        _goals.remove(g);
        if (withinRange) {
          _earnedKeys.remove('goal-${_goals.length + 1}');
          XpFloatService.instance.show(
            -5,
            x: 15 + (g.hashCode.abs() % 70).toDouble(),
            y: 35,
          );
        }
      } else {
        _goals.add(g);
        if (_goals.length <= 2) {
          XpFloatService.instance.show(
            5,
            x: 15 + (g.hashCode.abs() % 70).toDouble(),
            y: 35,
          );
        }
      }
    });
  }

  void _selectAllGoals() {
    final awarded = _goals.length >= 2 ? 0 : 2 - _goals.length;
    setState(() => _goals = List.of(_goalOptions));
    for (var i = 0; i < awarded; i++) {
      _addPts('goal-${_goals.length - awarded + i + 1}', 5);
    }
  }

  void _clearGoals() {
    final earnedCount = _goals.length.clamp(0, 2);
    setState(() {
      _goals = [];
      _earnedKeys
        ..remove('goal-1')
        ..remove('goal-2');
    });
    for (var i = 0; i < earnedCount; i++) {
      Future<void>.delayed(Duration(milliseconds: i * 120), () {
        XpFloatService.instance.show(
          -5,
          x: 25 + (i * 30) % 60,
          y: 35 + (i % 2) * 12,
        );
      });
    }
  }

  int get _completeness =>
      (_skill != null ? 1 : 0) + (_goals.length > 3 ? 3 : _goals.length);

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    return OnboardingScaffold(
      step: 3,
      title: 'How well do you cook?',
      subtitle: "No judgment — we'll match recipes to your level.",
      onSkip: () {
        if (!OnboardingEditMode.exit(flow)) {
          setState(() => _showSkipConfirm = true);
        }
      },
      onBack: () {
        if (!OnboardingEditMode.exit(flow)) {
          flow.setScreen(AppScreen.onboardingDietary);
        }
      },
      overlay: _showSkipConfirm
          ? OnboardingSkipDialog(
              title: 'Skip skill & preferences?',
              warning: "We'll use defaults for difficulty and spice level.",
              onSkipStep: () async {
                if (!await _persist()) return;
                if (mounted) {
                  setState(() => _showSkipConfirm = false);
                  flow.setScreen(AppScreen.gamificationTutorial);
                }
              },
              onSkipAll: () async {
                if (!await _persist()) return;
                if (mounted) {
                  setState(() => _showSkipConfirm = false);
                  flow.skipToHome();
                }
              },
              onClose: () => setState(() => _showSkipConfirm = false),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _skillLevels.length; i++) _skillCard(i),
          const SizedBox(height: 24),
          const Text(
            'How spicy do you like it? 🌶',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "We'll recommend recipes that match your heat tolerance.",
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          _SliderRow(
            levels: _spicePeppers,
            value: _spiceLevel,
            onTap: (i) {
              setState(() => _spiceLevel = i);
            },
          ),
          const SizedBox(height: 6),
          Text(
            '${_spicePeppers[_spiceLevel].label} heat',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _spicePeppers[_spiceLevel].color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sweetness preference 🍯',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'For desserts, drinks, and sauces.',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          _SliderRow(
            levels: _sweetLevels,
            value: _sweetLevel,
            onTap: (i) {
              setState(() => _sweetLevel = i);
            },
          ),
          const SizedBox(height: 6),
          Text(
            _sweetLevels[_sweetLevel].label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _sweetLevels[_sweetLevel].color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What brings you to b🌶te?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pick all that apply.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
              Row(
                children: [
                  _SectionPill(
                    label: '✓ All',
                    color: const Color(0xFF66BB6A),
                    background: _goals.length == _goalOptions.length
                        ? const Color(0x264CAF50)
                        : const Color(0x0F4CAF50),
                    borderColor: _goals.length == _goalOptions.length
                        ? const Color(0x664CAF50)
                        : const Color(0x2E4CAF50),
                    onTap: _selectAllGoals,
                  ),
                  const SizedBox(width: 6),
                  _SectionPill(
                    label: '✕ Clear',
                    color: _goals.isNotEmpty
                        ? AppColors.coral
                        : const Color(0x33FFFFFF),
                    background: _goals.isNotEmpty
                        ? AppColors.coral.withValues(alpha: 0.03)
                        : const Color(0x05FFFFFF),
                    borderColor: _goals.isNotEmpty
                        ? AppColors.coral.withValues(alpha: 0.16)
                        : const Color(0x0FFFFFFF),
                    onTap: _clearGoals,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var gi = 0; gi < _goalOptions.length; gi++) _goalChip(gi),
            ],
          ),
        ],
      ),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _completeness >= 4
                ? '🔥 Perfect — your deck will be fire!'
                : _completeness >= 2
                ? 'Almost there — ${_skill == null ? 'pick a skill level' : '${_goals.length} goal${_goals.length != 1 ? 's' : ''} selected'}'
                : 'Select your skill level to continue',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _completeness >= 4
                  ? const Color(0xFF4CAF50)
                  : _completeness >= 2
                  ? AppColors.amber
                  : AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          AuthPrimaryButton(
            label: _completeness >= 4
                ? "Let's Cook! 🔥"
                : _completeness >= 1
                ? "Let's Cook! 🍳"
                : 'Select skill level',
            enabled: _skill != null && !_saving,
            loading: _saving,
            gradient: _completeness >= 4
                ? const [Color(0xFF4CAF50), Color(0xFF66BB6A)]
                : _completeness >= 3
                ? const [AppColors.amber, Color(0xFFFFC107)]
                : _completeness >= 1
                ? const [AppColors.coral, AppColors.amber]
                : null,
            glow: _completeness >= 4,
            onTap: () async {
              if (_saving) return;
              if (await _persist() && mounted) {
                if (!OnboardingEditMode.exit(flow, saved: true)) {
                  flow.setScreen(AppScreen.gamificationTutorial);
                }
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Your deck is being personalized...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillCard(int i) {
    final s = _skillLevels[i];
    final sel = _skill == s.id;
    return SlideUp(
      duration: Duration(milliseconds: 350 + i * 120),
      child: GestureDetector(
        onTap: () {
          setState(() => _skill = s.id);
          _addPts('skill', 10);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sel ? s.color.withValues(alpha: 0.07) : AppColors.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: sel ? s.color : const Color(0x0FFFFFFF),
              width: 2,
            ),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: s.color.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(s.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      s.desc,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              if (sel)
                PopIn(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.check_circle, color: s.color, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalChip(int gi) {
    final g = _goalOptions[gi];
    final sel = _goals.contains(g);
    final gIdx = _goals.indexOf(g);
    final gTotal = _goals.length;
    final gColor = !sel
        ? null
        : gTotal >= 4
        ? const Color(0xFF4CAF50)
        : gIdx == 0
        ? AppColors.coral
        : gIdx == 1
        ? AppColors.amber
        : gIdx == 2
        ? const Color(0xFFFFD700)
        : const Color(0xFF4CAF50);
    return SlideUp(
      duration: Duration(milliseconds: 300 + gi * 60),
      child: GestureDetector(
        onTap: () => _toggleGoal(g),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? gColor : AppColors.glass,
            borderRadius: BorderRadius.circular(100),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: gColor!.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Text(
            g,
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

class _SkillLevel {
  const _SkillLevel({
    required this.id,
    required this.emoji,
    required this.label,
    required this.desc,
    required this.color,
  });

  final String id;
  final String emoji;
  final String label;
  final String desc;
  final Color color;
}

class _Level {
  const _Level({required this.emoji, required this.label, required this.color});

  final String emoji;
  final String label;
  final Color color;
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.levels,
    required this.value,
    required this.onTap,
  });

  final List<_Level> levels;
  final int value;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < levels.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: i <= value
                      ? levels[i].color.withValues(alpha: 0.13)
                      : const Color(0x08FFFFFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(i == 0 ? 12 : 0),
                    bottomLeft: Radius.circular(i == 0 ? 12 : 0),
                    topRight: Radius.circular(i == levels.length - 1 ? 12 : 0),
                    bottomRight: Radius.circular(
                      i == levels.length - 1 ? 12 : 0,
                    ),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: i <= value
                          ? levels[i].color
                          : const Color(0x0FFFFFFF),
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      levels[i].emoji,
                      style: TextStyle(
                        fontSize: 20,
                        color: i <= value
                            ? Colors.white
                            : const Color(0x4DFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      levels[i].label,
                      style: TextStyle(
                        color: i <= value ? levels[i].color : AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
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
