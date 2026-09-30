import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/services/xp_float_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../blocs/auth_cubit.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/onboarding_scaffold.dart';

/// Onboarding step 1 — cuisine preferences. Ports `OnboardingCuisineScreen`.
class OnboardingCuisineScreen extends StatefulWidget {
  const OnboardingCuisineScreen({super.key});

  @override
  State<OnboardingCuisineScreen> createState() =>
      _OnboardingCuisineScreenState();
}

class _OnboardingCuisineScreenState extends State<OnboardingCuisineScreen> {
  static const _cuisines = [
    'Korean', 'Italian', 'Mexican', 'Japanese', 'Thai', 'Indian',
    'American', 'Chinese', 'Mediterranean', 'French', 'Vietnamese',
    'Middle Eastern',
  ];
  static const _emojis = [
    '🇰🇷', '🍝', '🌮', '🍱', '🥘', '🍛',
    '🍔', '🥡', '🫒', '🥖', '🍜', '🧆',
  ];

  late List<String> _selected;
  bool _ptsCapped = false;
  bool _showSkipAlert = false;

  @override
  void initState() {
    super.initState();
    final cuisines = context.read<AuthCubit>().state.profile?.cuisines;
    _selected = cuisines == null ? [] : List.of(cuisines);
  }

  void _handleSelect(String c) {
    setState(() {
      final isAdding = !_selected.contains(c);
      if (isAdding) {
        _selected.add(c);
        if (_selected.length <= 3) {
          XpFloatService.instance
              .show(5, x: 15 + (c.hashCode.abs() % 70).toDouble(), y: 35);
          if (_selected.length == 3) _ptsCapped = true;
        }
      } else {
        final withinEarningRange = _selected.length <= 3;
        _selected.remove(c);
        if (withinEarningRange) {
          XpFloatService.instance
              .show(-5, x: 15 + (c.hashCode.abs() % 70).toDouble(), y: 35);
          _ptsCapped = false;
        }
      }
      if (_selected.length == 4 && !_ptsCapped) _ptsCapped = true;
    });
  }

  void _selectAll() {
    setState(() {
      final awarded = _selected.length >= 3 ? 0 : 3 - _selected.length;
      _selected = List.of(_cuisines);
      _ptsCapped = true;
      for (var i = 0; i < awarded; i++) {
        Future<void>.delayed(Duration(milliseconds: i * 150), () {
          XpFloatService.instance.show(5, x: 30 + (i * 17) % 60, y: 34);
        });
      }
    });
  }

  void _clearAll() {
    final earnedCount = _selected.length.clamp(0, 3);
    setState(() {
      _selected = [];
      _ptsCapped = false;
    });
    for (var i = 0; i < earnedCount; i++) {
      Future<void>.delayed(Duration(milliseconds: i * 150), () {
        XpFloatService.instance
            .show(-5, x: 20 + (i * 25) % 60, y: 30 + (i % 3) * 12);
      });
    }
  }

  String get _msg {
    final n = _selected.length;
    final msgs = [
      'What cuisines do you love?',
      'Nice start! 1 down...',
      '$n picks — keep exploring! 🌍',
      '✨ $n selected — unlocking your deck!',
      '🔥 $n cuisines — your feed is shaping up!',
      '💪 $n picks — now we\'re talking!',
      '🌶 $n — serious foodie energy!',
      '🤩 $n cuisines — your deck will be STACKED!',
      '🏆 $n selections — world-class taste!',
      '👑 $n — okay chef, we see you!',
      '🚀 $n — your deck is going to be legendary!',
      '🌟 $n — max flavor unlocked!',
      '🎉 ALL $n — the ultimate foodie!',
    ];
    if (n == 0) return msgs[0];
    return msgs[n.clamp(1, msgs.length - 1)];
  }

  Color get _ctaColor {
    final n = _selected.length;
    if (n >= 6) return const Color(0xFF4CAF50);
    if (n >= 4) return const Color(0xFF8BC34A);
    if (n >= 3) return AppColors.amber;
    if (n >= 1) return AppColors.coral;
    return AppColors.muted;
  }

  List<Color>? get _ctaGradient {
    final n = _selected.length;
    if (n >= 6) return const [Color(0xFF4CAF50), Color(0xFF66BB6A)];
    if (n >= 5) return const [Color(0xFF66BB6A), Color(0xFF81C784)];
    if (n >= 4) return const [Color(0xFF8BC34A), Color(0xFFAED581)];
    if (n >= 3) return const [AppColors.amber, Color(0xFFFFC107)];
    if (n >= 2) return [AppColors.coral.withValues(alpha: 0.5), AppColors.coral.withValues(alpha: 0.25)];
    if (n >= 1) return [AppColors.coral.withValues(alpha: 0.33), AppColors.coral.withValues(alpha: 0.13)];
    return null;
  }

  String get _ctaText {
    final n = _selected.length;
    if (n >= 6) return 'Continue — perfect! ✓';
    if (n >= 3) return 'Continue ($n selected) →';
    if (n >= 1) return 'Pick ${3 - n} more to continue';
    return 'Select cuisines to continue';
  }

  bool _saving = false;

  /// Saves this step to the `profiles` table (insert or update).
  /// Returns false and shows a toast if the write failed.
  Future<bool> _persist() async {
    setState(() => _saving = true);
    final result = await context.read<AuthCubit>().updateProfile({'cuisines': _selected});
    if (!mounted) return false;
    setState(() => _saving = false);
    if (!result.isSuccess) {
      ToastService.instance.show("⚠️ Couldn't save. Try again.");
      return false;
    }
    return true;
  }

  Color _selColor(int selIdx, int total) {
    if (total >= 4) return const Color(0xFF4CAF50);
    if (selIdx == 0) return AppColors.coral;
    if (selIdx == 1) return AppColors.amber;
    if (selIdx == 2) return const Color(0xFFFFD700);
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final n = _selected.length;
    return OnboardingScaffold(
      step: 1,
      title: 'What do you love to eat?',
      subtitle: "Pick 3 or more. We'll customize your deck.",
      onSkip: () => setState(() => _showSkipAlert = true),
      onBack: () => flow.setScreen(AppScreen.profileSetup),
      overlay: _showSkipAlert
          ? OnboardingSkipDialog(
              title: 'Skip cuisine preferences?',
              warning: "⚠️ You'll miss up to 15 onboarding bonus points",
              onSkipStep: () {
                setState(() => _showSkipAlert = false);
                flow.setScreen(AppScreen.onboardingDietary);
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cuisines.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, i) {
              final c = _cuisines[i];
              final sel = _selected.contains(c);
              final selIdx = _selected.indexOf(c);
              final selColor = sel ? _selColor(selIdx, n) : null;
              return SlideUp(
                duration: Duration(milliseconds: 400 + i * 60),
                child: GestureDetector(
                  onTap: () => _handleSelect(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: sel
                          ? selColor!.withValues(alpha: 0.13)
                          : AppColors.glass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? selColor! : const Color(0x0FFFFFFF),
                        width: 2,
                      ),
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: selColor!.withValues(alpha: 0.13),
                                blurRadius: 16,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _emojis[i],
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              c,
                              style: TextStyle(
                                color: sel ? Colors.white : AppColors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (sel)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: PopIn(
                              duration: const Duration(milliseconds: 250),
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selColor,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ThumbPill(
                  label: '✓  Select All',
                  color: const Color(0xFF66BB6A),
                  background: _selected.length == _cuisines.length
                      ? const Color(0x1F4CAF50)
                      : const Color(0x0F4CAF50),
                  borderColor: _selected.length == _cuisines.length
                      ? const Color(0x664CAF50)
                      : const Color(0x334CAF50),
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
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: _ctaColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            child: Text(_msg, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          if (n >= 3)
            Pulse(
              amount: 0.02,
              duration: const Duration(milliseconds: 1800),
              child: AuthPrimaryButton(
                label: _ctaText,
                enabled: !_saving,
                loading: _saving,
                gradient: _ctaGradient,
                glow: true,
                onTap: () async {
                  if (_saving) return;
                  if (await _persist() && mounted) {
                    flow.setScreen(AppScreen.onboardingDietary);
                  }
                },
              ),
            )
          else
            AuthPrimaryButton(
              label: _ctaText,
              enabled: false,
              gradient: _ctaGradient,
              glow: false,
              onTap: () {},
            ),
          if (_ptsCapped)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '✨ Max cuisine bonus reached (+15 pts)',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.amber, fontSize: 11),
              ),
            ),
        ],
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
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
