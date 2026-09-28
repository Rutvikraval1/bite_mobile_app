import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_safe_area.dart';
import '../../../../core/widgets/glass.dart';
import '../blocs/auth_cubit.dart';

/// One-time drinks verification gate. Ports `DrinksAgeGateScreen`.
class DrinksAgeGateScreen extends StatefulWidget {
  const DrinksAgeGateScreen({super.key});

  @override
  State<DrinksAgeGateScreen> createState() => _DrinksAgeGateScreenState();
}

class _DrinksAgeGateScreenState extends State<DrinksAgeGateScreen> {
  final _mm = TextEditingController(text: '07');
  final _dd = TextEditingController(text: '04');
  final _yyyy = TextEditingController(text: '1995');

  @override
  void initState() {
    super.initState();
    final dob = context.read<AuthCubit>().state.profile?.dob;
    if (dob != null) {
      final parts = dob.toIso8601String().split('T').first.split('-');
      if (parts.length == 3) {
        _mm.text = parts[1];
        _dd.text = parts[2];
        _yyyy.text = parts[0];
      }
    }
  }

  @override
  void dispose() {
    _mm.dispose();
    _dd.dispose();
    _yyyy.dispose();
    super.dispose();
  }

  bool get _valid {
    final year = int.tryParse(_yyyy.text);
    return _mm.text.isNotEmpty &&
        _dd.text.isNotEmpty &&
        _yyyy.text.length == 4 &&
        year != null &&
        year <= 2005;
  }

  Future<void> _unlock() async {
    if (!_valid) return;
    await context.read<AuthCubit>().updateProfile({
      'age_verified': true,
      'dob': '${_yyyy.text}-${_mm.text}-${_dd.text}',
    });
    if (mounted) context.read<FlowCubit>().setScreen(AppScreen.swipeDeck);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AppSafeArea(
        color: Colors.black.withValues(alpha: 0.7),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Center(
              child: PopIn(
                duration: const Duration(milliseconds: 350),
                child: Glass(
                  padding: const EdgeInsets.all(28),
                  borderRadius: 20,
                  color: AppColors.bgCard,
                  borderColor: const Color(0x44FF6B6B),
                  borderWidth: 1.5,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🍸', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        const Text(
                          'Unlock Drinks 🍸',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cocktails, mocktails, craft beverages & more',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'To access drink recipes including alcoholic beverages, please verify your date of birth. This only happens once.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _DobInput(
                              controller: _mm,
                              width: 60,
                              hint: 'MM',
                              maxLength: 2,
                              onChanged: (_) => setState(() {}),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '/',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                            _DobInput(
                              controller: _dd,
                              width: 60,
                              hint: 'DD',
                              maxLength: 2,
                              onChanged: (_) => setState(() {}),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '/',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ),
                            _DobInput(
                              controller: _yyyy,
                              width: 80,
                              hint: 'YYYY',
                              maxLength: 4,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_valid)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Text(
                              "✓ You're good!",
                              style: TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onTap: _valid ? _unlock : null,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _valid ? 1 : 0.5,
                            child: Container(
                              width: double.infinity,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: _valid
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF4A90D9),
                                          Color(0xFF3A78C4),
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0x1AFFFFFF),
                                          Color(0x1AFFFFFF),
                                        ],
                                      ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'Unlock Drinks 🍸',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => context.read<FlowCubit>().setScreen(
                            AppScreen.swipeDeck,
                          ),
                          child: Text(
                            'Maybe Later',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'By verifying, you confirm you are of legal drinking age in your region. b🌶te does not sell or distribute alcohol. Drink recipes are for informational purposes only. Parents/guardians are responsible for supervising minors\' access. Age data is stored securely and never shared.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0x33FFFFFF),
                            fontSize: 10,
                            height: 1.4,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DobInput extends StatelessWidget {
  const _DobInput({
    required this.controller,
    required this.width,
    required this.hint,
    required this.maxLength,
    required this.onChanged,
  });

  final TextEditingController controller;
  final double width;
  final String hint;
  final int maxLength;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: maxLength,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: const TextStyle(color: AppColors.muted),
          filled: true,
          fillColor: AppColors.glass,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.glassBorder),
          ),
        ),
      ),
    );
  }
}
