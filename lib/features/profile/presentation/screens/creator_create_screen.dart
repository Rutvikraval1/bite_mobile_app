import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/photo_source_sheet.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../../content/domain/entities/recipe_draft.dart';
import '../../../content/presentation/blocs/content_cubit.dart';

/// Create a recipe in 3 steps — basics, ingredients, method — then publish
/// (or save as a private draft) to the `recipes` table. The cover photo is
/// uploaded to the `recipe-images` storage bucket.
class CreatorCreateScreen extends StatefulWidget {
  const CreatorCreateScreen({super.key});

  @override
  State<CreatorCreateScreen> createState() => _CreatorCreateScreenState();
}

class _CreatorCreateScreenState extends State<CreatorCreateScreen> {
  static const _cuisines = [
    'Italian', 'Mexican', 'Indian', 'Chinese', 'Japanese', 'Korean', 'Thai',
    'American', 'Mediterranean', 'French', 'Middle Eastern', 'Various',
  ];
  static const _emojis = ['🍽', '🍝', '🍜', '🌮', '🍛', '🍣', '🥗', '🍔', '🍕', '🥘', '🍰', '🥞'];

  int _step = 0;
  String _difficulty = 'Medium';
  int _spiceLevel = 1;
  String _cuisine = 'Various';
  String _emoji = '🍽';
  /// Cover photo picked but not uploaded yet — previewed locally and only
  /// uploaded to storage when the user taps Publish / Save Draft.
  XFile? _pickedFile;
  Uint8List? _pickedBytes;
  bool _submitting = false;

  final _title = TextEditingController();
  final _story = TextEditingController();
  final _prep = TextEditingController();
  final _cook = TextEditingController();
  final _serves = TextEditingController(text: '2');
  final List<TextEditingController> _ingredients = [TextEditingController()];
  final List<TextEditingController> _steps = [TextEditingController()];

  @override
  void dispose() {
    for (final c in [_title, _story, _prep, _cook, _serves, ..._ingredients, ..._steps]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _lines(List<TextEditingController> cs) =>
      cs.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  int get _totalMinutes =>
      (int.tryParse(_prep.text.trim()) ?? 0) + (int.tryParse(_cook.text.trim()) ?? 0);

  /// Returns an error message for the current step, or null if valid.
  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (_title.text.trim().length < 3) return 'Give your recipe a title (3+ characters)';
        final serves = int.tryParse(_serves.text.trim());
        if (serves == null || serves < 1 || serves > 50) return 'Serves must be between 1 and 50';
        if (_totalMinutes <= 0) return 'Add prep or cook time in minutes';
        return null;
      case 1:
        if (_lines(_ingredients).isEmpty) return 'Add at least one ingredient';
        return null;
      default:
        if (_lines(_steps).isEmpty) return 'Add at least one step';
        return null;
    }
  }

  void _next() {
    final error = _validateStep(_step);
    if (error != null) {
      context.showToast('⚠️ $error');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      context.read<FlowCubit>().goBack();
    } else {
      setState(() => _step--);
    }
  }

  /// Camera/gallery → local preview only. Nothing is uploaded until submit.
  Future<void> _pickPhoto() async {
    final action = await showPhotoSourceSheet(context, allowRemove: _pickedBytes != null);
    if (action == null || !mounted) return;
    if (action == PhotoAction.remove) {
      setState(() {
        _pickedFile = null;
        _pickedBytes = null;
      });
      return;
    }
    final file = await ImageUploadService.instance.pick(
      action == PhotoAction.camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedFile = file;
      _pickedBytes = bytes;
    });
  }

  Future<void> _submit({required bool publish}) async {
    for (var s = 0; s < 3; s++) {
      final error = _validateStep(s);
      if (error != null) {
        setState(() => _step = s);
        context.showToast('⚠️ $error');
        return;
      }
    }
    final auth = context.read<AuthCubit>().state;
    final content = context.read<ContentCubit>();
    final profile = auth.profile;
    final handle = profile == null || profile.username.isEmpty
        ? '@me'
        : '@${profile.username}';
    setState(() => _submitting = true);

    // 1) Upload the cover photo (if any) to the `recipe-images` bucket.
    String? imageUrl;
    final picked = _pickedFile;
    final userId = auth.user?.id;
    if (picked != null && userId != null) {
      try {
        imageUrl = await ImageUploadService.instance.upload(
          bucket: ImageBuckets.recipeImages,
          userId: userId,
          file: picked,
        );
      } catch (e) {
        debugPrint('[bite] photo upload failed: $e');
        if (!mounted) return;
        setState(() => _submitting = false);
        context.showToast("⚠️ Couldn't upload photo: ${ImageUploadService.describeError(e)}");
        return;
      }
    }

    // 2) Save the recipe row with the photo URL.
    final result = await content.createRecipe(
          RecipeDraft(
            title: _title.text,
            description: _story.text,
            imageUrl: imageUrl,
            emoji: _emoji,
            cuisine: _cuisine,
            timeMin: '$_totalMinutes min',
            difficulty: _difficulty,
            serves: int.parse(_serves.text.trim()),
            heatLevel: _spiceLevel,
            tags: [_cuisine.toLowerCase(), _difficulty.toLowerCase()],
            ingredients: _lines(_ingredients),
            steps: _lines(_steps),
            publish: publish,
          ),
          creator: handle,
        );
    if (!result.isSuccess && imageUrl != null) {
      // DB write failed — don't leave the just-uploaded photo orphaned.
      ImageUploadService.instance.deleteByUrl(ImageBuckets.recipeImages, imageUrl);
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.isSuccess) {
      context.showToast(publish ? '✨ Recipe published! 🎉' : '📝 Draft saved');
      context.read<FlowCubit>().goBack();
    } else {
      context.showToast("⚠️ Couldn't save recipe: ${result.error}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: switch (_step) {
                  0 => _basicsStep(),
                  1 => _listStep(
                      title: 'Ingredients',
                      hint: 'e.g. 2 cups basmati rice',
                      controllers: _ingredients,
                      numbered: false,
                    ),
                  _ => _listStep(
                      title: 'Method',
                      hint: 'Describe this step…',
                      controllers: _steps,
                      numbered: true,
                    ),
                },
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _submitting ? null : _back,
            child: Icon(_step == 0 ? Icons.close : Icons.arrow_back, size: 22, color: Colors.white),
          ),
          const Spacer(),
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: i == _step ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i < _step
                      ? const Color(0xFF4CAF50)
                      : i == _step
                          ? AppColors.coral
                          : Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
          Text('Step ${_step + 1} of 3', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          const Spacer(),
          const SizedBox(width: 22),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final last = _step == 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          if (last) ...[
            Expanded(
              child: _button(
                label: 'Save Draft',
                filled: false,
                onTap: _submitting ? null : () => _submit(publish: false),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: _button(
              label: _submitting ? 'Saving…' : last ? 'Publish Recipe' : 'Next →',
              filled: true,
              onTap: _submitting ? null : last ? () => _submit(publish: true) : _next,
            ),
          ),
        ],
      ),
    );
  }

  Widget _button({required String label, required bool filled, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.coral : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: filled ? null : Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 1: basics ──

  List<Widget> _basicsStep() {
    return [
      GestureDetector(
        onTap: _submitting ? null : _pickPhoto,
        child: Container(
          height: 190,
          margin: const EdgeInsets.only(bottom: 20),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.coral.withValues(alpha: 0.03),
            border: Border.all(
              color: _pickedBytes != null ? const Color(0xFF4CAF50) : AppColors.coral.withValues(alpha: 0.27),
              width: 2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_pickedBytes != null) Image.memory(_pickedBytes!, fit: BoxFit.cover),
              if (_pickedBytes == null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 36, color: AppColors.coral),
                    const SizedBox(height: 8),
                    const Text(
                      'Add Cover Photo',
                      style: TextStyle(color: AppColors.coral, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Camera or gallery', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              if (_pickedBytes != null)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xAA000000), borderRadius: BorderRadius.circular(100)),
                    child: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              if (_submitting && _pickedFile != null)
                const ColoredBox(
                  color: Color(0x99000000),
                  child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                ),
            ],
          ),
        ),
      ),
      _input(_title, 'What did you make?', big: true),
      const SizedBox(height: 12),
      _input(_story, 'Tell the story behind this dish… (optional)', maxLines: 3),
      const SizedBox(height: 16),
      _label('ICON'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final e in _emojis)
            _chip(label: e, active: _emoji == e, onTap: () => setState(() => _emoji = e), fontSize: 18),
        ],
      ),
      const SizedBox(height: 16),
      _label('CUISINE'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in _cuisines)
            _chip(label: c, active: _cuisine == c, onTap: () => setState(() => _cuisine = c)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _quickDetail('⏱ Prep (min)', '15', _prep)),
          const SizedBox(width: 10),
          Expanded(child: _quickDetail('🔥 Cook (min)', '25', _cook)),
          const SizedBox(width: 10),
          Expanded(child: _quickDetail('🍽 Serves', '4', _serves)),
        ],
      ),
      const SizedBox(height: 16),
      _label('DIFFICULTY'),
      Row(
        children: [
          for (final d in const ['Easy', 'Medium', 'Hard'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(label: d, active: _difficulty == d, onTap: () => setState(() => _difficulty = d)),
            ),
        ],
      ),
      const SizedBox(height: 16),
      _label('SPICE LEVEL'),
      Row(
        children: [
          for (final l in [0, 1, 2, 3])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(
                label: l == 0 ? 'None' : '🌶' * l,
                active: _spiceLevel == l,
                onTap: () => setState(() => _spiceLevel = l),
              ),
            ),
        ],
      ),
    ];
  }

  // ── Steps 2 & 3: ingredient / method lists ──

  List<Widget> _listStep({
    required String title,
    required String hint,
    required List<TextEditingController> controllers,
    required bool numbered,
  }) {
    return [
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(
        numbered ? 'One step per line, in order.' : 'Start each line with the amount, e.g. "200 g paneer".',
        style: TextStyle(color: AppColors.muted, fontSize: 13),
      ),
      const SizedBox(height: 16),
      for (var i = 0; i < controllers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(top: 10, right: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.coral.withValues(alpha: 0.15),
                ),
                child: Text(
                  numbered ? '${i + 1}' : '•',
                  style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Expanded(child: _input(controllers[i], hint, maxLines: numbered ? 3 : 1)),
              IconButton(
                onPressed: controllers.length == 1
                    ? null
                    : () {
                        final removed = controllers.removeAt(i);
                        setState(() {});
                        // Dispose after the TextField using it has unmounted.
                        WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
                      },
                icon: Icon(Icons.close, size: 18, color: AppColors.muted),
              ),
            ],
          ),
        ),
      GestureDetector(
        onTap: () => setState(() => controllers.add(TextEditingController())),
        child: Glass(
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 18, color: AppColors.coral),
              const SizedBox(width: 6),
              Text(
                numbered ? 'Add step' : 'Add ingredient',
                style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Small building blocks ──

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
        ),
      );

  Widget _chip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    double fontSize = 13,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.coral : AppColors.glass,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w600,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String hint, {int maxLines = 1, bool big = false}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      minLines: 1,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: Colors.white,
        fontSize: big ? 18 : 14,
        fontWeight: big ? FontWeight.w700 : FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.muted, fontSize: big ? 16 : 13),
        filled: true,
        fillColor: AppColors.glass,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: AppColors.coral),
        ),
      ),
    );
  }

  Widget _quickDetail(String label, String placeholder, TextEditingController controller) {
    return Glass(
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: AppColors.muted, fontSize: 14, fontWeight: FontWeight.w600),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
            ),
          ),
        ],
      ),
    );
  }
}
