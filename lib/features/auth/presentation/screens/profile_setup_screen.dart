import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/xp_float_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/app_safe_area.dart';
import '../blocs/auth_cubit.dart';
import '../widgets/auth_widgets.dart';

/// Profile setup — name, username, DOB, bio, agreements. Ports `ProfileSetupScreen`.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  static const _avatars = [
    '🧑‍🍳',
    '👩‍🍳',
    '👨‍🍳',
    '🍗',
    '🌮',
    '🍣',
    '🍜',
    '🍰',
    '🥘',
    '🍕',
    '🥑',
    '🌶',
  ];

  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  String? _dob;
  String? _selectedAvatar;
  bool _showAvatarPicker = false;
  bool _agreedTerms = false;
  bool _agreedPrivacy = false;
  bool _shareIntro = false;
  bool _showSkipConfirm = false;
  final Set<String> _earnedKeys = {};

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthCubit>().state.profile;
    if (profile != null) {
      _name.text = profile.displayName;
      _username.text = profile.username;
      _bio.text = profile.bio;
      _dob = profile.dob?.toIso8601String().split('T').first;
      _selectedAvatar = profile.avatarEmoji.isEmpty
          ? null
          : profile.avatarEmoji;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _addPoints(String key, int pts, double y) {
    if (_earnedKeys.contains(key)) return;
    _earnedKeys.add(key);
    XpFloatService.instance.show(pts, x: 25 + (pts % 50).toDouble(), y: y);
  }

  bool get _isValid =>
      _name.text.length >= 2 &&
      _username.text.length >= 3 &&
      _agreedTerms &&
      _agreedPrivacy;

  int? get _age {
    final d = _dob;
    if (d == null) return null;
    final parsed = DateTime.tryParse(d);
    if (parsed == null) return null;
    return DateTime.now().year - parsed.year;
  }

  Future<void> _persist() async {
    if (!_isValid) return;
    await context.read<AuthCubit>().updateProfile({
      'display_name': _name.text.trim(),
      'username': _username.text.trim().replaceFirst('@', ''),
      'dob': _dob,
      'bio': _bio.text.trim(),
      'avatar_emoji': _selectedAvatar ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final age = _age;
    return AppSafeArea(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AuthBackButton(
                        onTap: () => flow.setScreen(AppScreen.auth),
                        label: 'Back to Sign In',
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showSkipConfirm = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x0AFFFFFF),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0x14FFFFFF)),
                          ),
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Color(0x59FFFFFF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'CREATE YOUR PROFILE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _XpBanner(),
                  const SizedBox(height: 20),
                  // Avatar
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(
                          () => _showAvatarPicker = !_showAvatarPicker,
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _selectedAvatar != null
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0x44FF6B6B),
                                          Color(0x44F5A623),
                                        ],
                                      )
                                    : null,
                                color: _selectedAvatar == null
                                    ? const Color(0x15FF6B6B)
                                    : null,
                                border: Border.all(
                                  color: _selectedAvatar != null
                                      ? const Color(0x66FF6B6B)
                                      : const Color(0x44FF6B6B),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                _selectedAvatar ?? '📸',
                                style: TextStyle(
                                  fontSize: _selectedAvatar != null ? 44 : 28,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedAvatar != null
                                      ? const Color(0xFF4CAF50)
                                      : AppColors.coral,
                                  border: Border.all(
                                    color: AppColors.bgDark,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _selectedAvatar != null
                                      ? Icons.check
                                      : Icons.add,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedAvatar != null
                            ? '✓ Looking great!'
                            : 'Tap to choose an avatar  +10 XP',
                        style: TextStyle(
                          color: _selectedAvatar != null
                              ? const Color(0xFF4CAF50)
                              : AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                  if (_showAvatarPicker) _avatarPicker(),
                  const SizedBox(height: 20),
                  // Form
                  AuthField(
                    controller: _name,
                    label: 'DISPLAY NAME',
                    hint: 'Your name',
                    onChanged: (v) {
                      setState(() {});
                      if (v.length == 2) _addPoints('name', 5, 38);
                    },
                    valid: _name.text.length >= 2,
                    suffix: const _XpTag('+5 XP'),
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    controller: _username,
                    label: 'USERNAME',
                    hint: 'username',
                    prefix: '@',
                    onChanged: (v) {
                      final clean = v.toLowerCase().replaceAll(
                        RegExp('[^a-z0-9_]'),
                        '',
                      );
                      if (clean != v) _username.text = clean;
                      setState(() {});
                      if (v.length == 3) _addPoints('username', 5, 44);
                    },
                    valid: _username.text.length >= 3,
                    suffix: const _XpTag('+5 XP'),
                  ),
                  if (_username.text.isNotEmpty && _username.text.length < 3)
                    const Padding(
                      padding: EdgeInsets.only(left: 4, top: 4),
                      child: Text(
                        'Min 3 characters',
                        style: TextStyle(color: AppColors.coral, fontSize: 11),
                      ),
                    ),
                  if (_username.text.length >= 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text(
                        '✓ @${_username.text} is available',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _DobField(
                    dob: _dob,
                    onChanged: (v) => setState(() => _dob = v),
                  ),
                  if (age != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text(
                        age >= 13
                            ? 'Age: $age${age >= 21
                                  ? ' · 🍸 Drinks unlocked'
                                  : age >= 18
                                  ? ' · 🍷 Age verified'
                                  : ''}'
                            : 'Must be 13+ to use b🌶te',
                        style: TextStyle(
                          color: age >= 13 ? AppColors.muted : AppColors.coral,
                          fontSize: 11,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Bio
                  Row(
                    children: [
                      const Text(
                        'BIO',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '(optional)',
                        style: TextStyle(color: AppColors.muted, fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      const _XpTag('+10 XP'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bio,
                    maxLines: 2,
                    maxLength: 150,
                    onChanged: (v) {
                      setState(() {});
                      if (v.length >= 10) _addPoints('bio', 10, 55);
                    },
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tell us what you love to cook...',
                      counterText: _bio.text.isEmpty
                          ? ''
                          : '${_bio.text.length}/150',
                      counterStyle: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AgreementTile(
                    title:
                        "I agree to the Terms of Service and understand that my data will be used in accordance with b🌶te's policies.",
                    checked: _agreedTerms,
                    onTap: () => setState(() => _agreedTerms = !_agreedTerms),
                  ),
                  const SizedBox(height: 10),
                  _AgreementTile(
                    title:
                        "I have read and agree to the Privacy Policy including data collection and third-party sharing disclosures.",
                    checked: _agreedPrivacy,
                    onTap: () =>
                        setState(() => _agreedPrivacy = !_agreedPrivacy),
                  ),
                  const SizedBox(height: 16),
                  // Intro toggle
                  GestureDetector(
                    onTap: () {
                      setState(() => _shareIntro = !_shareIntro);
                      if (!_shareIntro) _addPoints('intro', 25, 72);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _shareIntro
                            ? const Color(0x0F4CAF50)
                            : const Color(0x05FFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _shareIntro
                              ? const Color(0x334CAF50)
                              : const Color(0x0FFFFFFF),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('👋', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Introduce yourself to the community',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                Text(
                                  'Share your name, skill level & cuisines to local feed',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '+25 pts',
                            style: TextStyle(
                              color: AppColors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _SwitchPill(active: _shareIntro),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Continue
                  AuthPrimaryButton(
                    label: 'Continue',
                    enabled: _isValid,
                    onTap: () async {
                      await _persist();
                      if (mounted) flow.setScreen(AppScreen.onboardingCuisine);
                    },
                    glow: _isValid,
                    gradient: const [AppColors.coral, AppColors.amber],
                  ),
                  if (!_agreedTerms || !_agreedPrivacy)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Please accept both agreements to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0x40FFFFFF),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can always edit your profile later',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0x33FFFFFF), fontSize: 11),
                  ),
                ],
              ),
            ),
            if (_showSkipConfirm)
              _SkipConfirm(
                onSkipStep: () async {
                  await _persist();
                  if (mounted) {
                    setState(() => _showSkipConfirm = false);
                    flow.setScreen(AppScreen.onboardingCuisine);
                  }
                },
                onSkipAll: () async {
                  await _persist();
                  if (mounted) {
                    setState(() => _showSkipConfirm = false);
                    flow.skipToHome();
                  }
                },
                onClose: () => setState(() => _showSkipConfirm = false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPicker() {
    return SlideUp(
      duration: const Duration(milliseconds: 300),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final avatar in _avatars)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatar = avatar;
                  _showAvatarPicker = false;
                });
                _addPoints('avatar', 10, 22);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedAvatar == avatar
                      ? const Color(0x22FF6B6B)
                      : const Color(0x0AFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedAvatar == avatar
                        ? AppColors.coral
                        : const Color(0x14FFFFFF),
                    width: 2,
                  ),
                ),
                child: Text(avatar, style: const TextStyle(fontSize: 24)),
              ),
            ),
        ],
      ),
    );
  }
}

class _XpBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x12F5A623), Color(0x08FF6B6B)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33F5A623)),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.1),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Row(
        children: [
          Pulse(
            amount: 0.1,
            duration: Duration(milliseconds: 2000),
            child: Text('⭐', style: TextStyle(fontSize: 16)),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Earn bonus XP as you set up — fill out more, earn more!',
              style: TextStyle(
                color: AppColors.amber,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _XpTag extends StatelessWidget {
  const _XpTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF4CAF50),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
      ),
    );
  }
}

class _DobField extends StatelessWidget {
  const _DobField({required this.dob, required this.onChanged});

  final String? dob;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DATE OF BIRTH',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          keyboardType: TextInputType.datetime,
          style: const TextStyle(fontSize: 15),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: dob ?? '1995-07-04',
            hintStyle: TextStyle(
              color: dob != null ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ],
    );
  }
}

class _AgreementTile extends StatelessWidget {
  const _AgreementTile({
    required this.title,
    required this.checked,
    required this.onTap,
  });

  final String title;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: checked ? const Color(0x0F4CAF50) : const Color(0x05FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: checked ? const Color(0x334CAF50) : const Color(0x0FFFFFFF),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: checked
                    ? const Color(0xFF4CAF50)
                    : const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked
                      ? const Color(0xFF4CAF50)
                      : const Color(0x26FFFFFF),
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: checked ? const Color(0xB3FFFFFF) : AppColors.muted,
                  fontSize: 12,
                  height: 1.5,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchPill extends StatelessWidget {
  const _SwitchPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF4CAF50) : const Color(0x26FFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: active ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SkipConfirm extends StatelessWidget {
  const _SkipConfirm({
    required this.onSkipStep,
    required this.onSkipAll,
    required this.onClose,
  });

  final VoidCallback onSkipStep;
  final VoidCallback onSkipAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () {},
            child: PopIn(
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 40,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Skip this step?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You can always set up your profile later in Settings.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthPrimaryButton(
                      label: 'Skip This Step →',
                      enabled: true,
                      onTap: onSkipStep,
                      color: const Color(0x0FFFFFFF),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onSkipAll,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x15FF6B6B),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0x33FF6B6B)),
                        ),
                        child: const Text(
                          'Skip Entire Tutorial',
                          style: TextStyle(
                            color: AppColors.coral,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
