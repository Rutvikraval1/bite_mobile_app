import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';

/// Step 1 of the "create a recipe/drink" flow — photo, title, story, type,
/// quick details, difficulty, spice level. Ports `CreatorCreateScreen`.
/// No `posts` table exists yet, so publishing is local-only (toast + close).
class CreatorCreateScreen extends StatefulWidget {
  const CreatorCreateScreen({super.key});

  @override
  State<CreatorCreateScreen> createState() => _CreatorCreateScreenState();
}

class _CreatorCreateScreenState extends State<CreatorCreateScreen> {
  String _contentType = 'recipe';
  String _difficulty = 'medium';
  int _spiceLevel = 2;
  bool _photoAdded = false;
  final _title = TextEditingController();
  final _story = TextEditingController();
  final _prep = TextEditingController();
  final _cook = TextEditingController();
  final _serves = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _story.dispose();
    _prep.dispose();
    _cook.dispose();
    _serves.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.read<FlowCubit>().goBack(),
                    child: const Icon(
                      Icons.close,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            width: i == 0 ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: i == 0
                                  ? AppColors.coral
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      Text(
                        'Step 1 of 3',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.showToast('✨ Moving to Step 2...'),
                    child: const Text(
                      'Next →',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _photoAdded = !_photoAdded),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 180,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _photoAdded
                            ? const Color(0x144CAF50)
                            : AppColors.coral.withValues(alpha: 0.03),
                        border: Border.all(
                          color: _photoAdded
                              ? const Color(0xFF4CAF50)
                              : AppColors.coral.withValues(alpha: 0.27),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _photoAdded
                                ? Icons.check
                                : Icons.camera_alt_outlined,
                            size: 36,
                            color: _photoAdded
                                ? const Color(0xFF4CAF50)
                                : AppColors.coral,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _photoAdded ? 'Photo Added! ✓' : 'Add Cover Photo',
                            style: TextStyle(
                              color: _photoAdded
                                  ? const Color(0xFF4CAF50)
                                  : AppColors.coral,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!_photoAdded)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _pill('📸 Camera'),
                                  const SizedBox(width: 8),
                                  _pill('🖼 Gallery'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextField(
                    controller: _title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'What did you make?',
                      hintStyle: TextStyle(
                        color: AppColors.muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: AppColors.glass,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                      constraints: const BoxConstraints(
                        minHeight: 52,
                        maxHeight: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _story,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tell the story behind this dish... (optional)',
                      hintStyle: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: AppColors.glass,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TYPE',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _typeChip('recipe', '🍽 Recipe'),
                        const SizedBox(width: 8),
                        _typeChip('drink', '🍸 Drink'),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => context.showToast(
                            '📍 Place Reviews coming in Phase 2!',
                          ),
                          child: Opacity(
                            opacity: 0.5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.glass,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '📍 Place Review',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Phase 2',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _quickDetail('⏱ Prep', '15 min', _prep)),
                      const SizedBox(width: 10),
                      Expanded(child: _quickDetail('🔥 Cook', '25 min', _cook)),
                      const SizedBox(width: 10),
                      Expanded(child: _quickDetail('🍽 Serves', '4', _serves)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'DIFFICULTY',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final d in const [
                        ('easy', 'Easy'),
                        ('medium', 'Medium'),
                        ('advanced', 'Advanced'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _difficulty = d.$1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _difficulty == d.$1
                                    ? AppColors.coral
                                    : AppColors.glass,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                d.$2,
                                style: TextStyle(
                                  color: _difficulty == d.$1
                                      ? Colors.white
                                      : AppColors.muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SPICE LEVEL',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final l in [1, 2, 3])
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _spiceLevel = l),
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: _spiceLevel == l ? 1.05 : 1.0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _spiceLevel == l
                                      ? AppColors.coral.withValues(alpha: 0.13)
                                      : AppColors.glass,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: _spiceLevel == l
                                        ? AppColors.coral
                                        : Colors.white.withValues(alpha: 0.06),
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '🌶' * l,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      context.showToast('✨ Recipe published! 🎉');
                      final flow = context.read<FlowCubit>();
                      Future<void>.delayed(
                        const Duration(milliseconds: 1500),
                        flow.goBack,
                      );
                    },
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'Next →',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  Widget _typeChip(String id, String label) {
    final active = _contentType == id;
    return GestureDetector(
      onTap: () => setState(() => _contentType = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.coral : AppColors.glass,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _quickDetail(
    String label,
    String placeholder,
    TextEditingController controller,
  ) {
    return Glass(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            onTap: () {
              if (controller.text.isEmpty) controller.text = placeholder;
            },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
