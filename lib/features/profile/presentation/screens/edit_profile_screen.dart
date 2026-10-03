import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/photo_source_sheet.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';

/// Edit display name, username, bio and avatar — persists to the real
/// `profiles` table via `AuthCubit.updateProfile`. Ports `EditProfileScreen`.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
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
  String _selectedAvatar = '🧑‍🍳';

  /// Saved photo URL from the profile; null means no saved photo.
  String? _avatarUrl;

  /// Photo picked but not uploaded yet — previewed locally and only
  /// uploaded + written to the database when the user taps Save.
  XFile? _pickedFile;
  Uint8List? _pickedBytes;

  bool get _hasPhoto => _pickedBytes != null || _avatarUrl != null;
  bool _saving = false;
  bool _initialized = false;
  bool _showChangePassword = false;
  bool _showChangeEmail = false;
  bool _showDeleteConfirm = false;
  bool _deleting = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _hydrate(BuildContext context) {
    if (_initialized) return;
    _initialized = true;
    final profile = context.read<AuthCubit>().state.profile;
    if (profile != null) {
      _name.text = profile.displayName;
      _username.text = profile.username;
      _bio.text = profile.bio;
      if (profile.avatarEmoji.isNotEmpty) _selectedAvatar = profile.avatarEmoji;
      _avatarUrl = profile.avatarUrl;
    }
    _initial = _snapshot();
  }

  /// Form values when the screen opened — used to detect unsaved edits.
  late String _initial;

  String _snapshot() => [
    _name.text.trim(),
    _username.text.trim(),
    _bio.text.trim(),
    _selectedAvatar,
    _avatarUrl ?? '',
  ].join('\u0000');

  bool get _isDirty => _pickedFile != null || _snapshot() != _initial;

  /// Back arrow / system back: confirm before discarding unsaved edits.
  Future<void> _handleBack() async {
    if (_saving) return;
    final flow = context.read<FlowCubit>();
    if (!_isDirty) {
      flow.goBack();
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text(
          'Unsaved changes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Save your changes before leaving?',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: Text('Discard', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.coral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'save') {
      await _save();
    } else if (choice == 'discard') {
      flow.goBack();
    }
  }

  /// Camera/gallery → local preview only. Nothing is uploaded until Save.
  Future<void> _changePhoto() async {
    final action = await showPhotoSourceSheet(context, allowRemove: _hasPhoto);
    if (action == null || !mounted) return;
    if (action == PhotoAction.remove) {
      setState(_clearPhoto);
      return;
    }
    final file = await ImageUploadService.instance.pick(
      action == PhotoAction.camera ? ImageSource.camera : ImageSource.gallery,
      maxSize: 800,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedFile = file;
      _pickedBytes = bytes;
    });
  }

  void _clearPhoto() {
    _avatarUrl = null;
    _pickedFile = null;
    _pickedBytes = null;
  }

  Future<void> _save() async {
    final username = _username.text.trim().replaceFirst(RegExp('^@'), '');
    if (_name.text.trim().length < 2 || username.length < 3) {
      context.showToast('⚠️ Name and username are required');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(username)) {
      context.showToast('⚠️ Username can only use letters, numbers, _ and .');
      return;
    }
    final auth = context.read<AuthCubit>();
    final previousUrl = auth.state.profile?.avatarUrl;
    final userId = auth.state.user?.id;
    final flow = context.read<FlowCubit>();
    setState(() => _saving = true);

    // 1) Upload the newly picked photo (if any) to the `avatars` bucket.
    var avatarUrl = _avatarUrl;
    String? uploadedUrl;
    final picked = _pickedFile;
    if (picked != null && userId != null) {
      try {
        uploadedUrl = await ImageUploadService.instance.upload(
          bucket: ImageBuckets.avatars,
          userId: userId,
          file: picked,
        );
        avatarUrl = uploadedUrl;
      } catch (e) {
        debugPrint('[bite] photo upload failed: $e');
        if (!mounted) return;
        setState(() => _saving = false);
        context.showToast(
          "⚠️ Couldn't upload photo: ${ImageUploadService.describeError(e)}",
        );
        return;
      }
    }
    if (!mounted) return;

    // 2) Save the profile row with the new photo URL.
    final result = await auth.updateProfile({
      'display_name': _name.text.trim(),
      'username': username,
      'bio': _bio.text.trim(),
      'avatar_emoji': _selectedAvatar,
      'avatar_url': avatarUrl,
    });
    if (!result.isSuccess && uploadedUrl != null) {
      // DB write failed — don't leave the just-uploaded file orphaned.
      ImageUploadService.instance.deleteByUrl(
        ImageBuckets.avatars,
        uploadedUrl,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.isSuccess) {
      setState(() {
        _avatarUrl = avatarUrl;
        _pickedFile = null;
        _pickedBytes = null;
      });
      // Clean up the replaced photo so storage doesn't fill with orphans.
      if (previousUrl != null && previousUrl != avatarUrl) {
        ImageUploadService.instance.deleteByUrl(
          ImageBuckets.avatars,
          previousUrl,
        );
      }
      context.showToast('✅ Profile saved!');
      flow.goBack();
    } else {
      context.showToast('⚠️ ${result.error ?? 'Could not save profile'}');
    }
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _showDeleteConfirm = false;
      _deleting = true;
    });
    final result = await context.read<AuthCubit>().deleteAccount();
    if (!mounted) return;
    setState(() => _deleting = false);
    if (!result.isSuccess) {
      context.showToast('⚠️ ${result.error ?? 'Could not delete account'}');
    }
    // On success the auth stream emits a signed-out state and the app
    // routes back to the auth screen automatically.
  }

  @override
  Widget build(BuildContext context) {
    _hydrate(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _handleBack,
                          child: const Icon(
                            Icons.arrow_back,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Edit Profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _saving ? null : _save,
                          child: Text(
                            _saving ? 'Saving…' : 'Save',
                            style: const TextStyle(
                              color: AppColors.coral,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
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
                        Column(
                          children: [
                            GestureDetector(
                              onTap: _saving ? null : _changePhoto,
                              child: Container(
                                width: 88,
                                height: 88,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [AppColors.coral, AppColors.amber],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    if (_pickedBytes != null)
                                      ClipOval(
                                        child: Image.memory(
                                          _pickedBytes!,
                                          width: 82,
                                          height: 82,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      AvatarImg(
                                        emoji: _selectedAvatar,
                                        imageUrl: _avatarUrl,
                                        size: 82,
                                        borderWidth: 0,
                                      ),
                                    if (_saving && _pickedFile != null)
                                      const Positioned.fill(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0x99000000),
                                          ),
                                          child: Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.coral,
                                          border: Border.all(
                                            color: AppColors.bgDark,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.photo_camera,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _saving ? null : _changePhoto,
                              child: Text(
                                _pickedFile != null
                                    ? 'New photo — tap Save to apply'
                                    : _hasPhoto
                                    ? 'Change photo'
                                    : 'Upload a photo or pick an emoji',
                                style: const TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final a in _avatars)
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedAvatar = a;
                                        _clearPhoto();
                                      }),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              !_hasPhoto && _selectedAvatar == a
                                              ? AppColors.coral.withValues(
                                                  alpha: 0.13,
                                                )
                                              : Colors.white.withValues(
                                                  alpha: 0.04,
                                                ),
                                          border: Border.all(
                                            color:
                                                !_hasPhoto &&
                                                    _selectedAvatar == a
                                                ? AppColors.coral
                                                : Colors.white.withValues(
                                                    alpha: 0.12,
                                                  ),
                                            width:
                                                !_hasPhoto &&
                                                    _selectedAvatar == a
                                                ? 2
                                                : 1,
                                          ),
                                        ),
                                        child: Text(
                                          a,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        _Field(label: 'Display Name', controller: _name),
                        const SizedBox(height: 16),
                        _Field(label: 'Username', controller: _username),
                        const SizedBox(height: 16),
                        _Field(
                          label: 'Bio',
                          controller: _bio,
                          maxLines: 3,
                          hint: 'Tell us about your cooking journey...',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'ACCOUNT',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        for (final item in const [
                          '📧 Change Email',
                          '🔒 Change Password',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (item == '🔒 Change Password') {
                                  _showChangePassword = true;
                                } else {
                                  _showChangeEmail = true;
                                }
                              }),
                              child: Glass(
                                borderRadius: 12,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 16,
                                      color: AppColors.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: GestureDetector(
                            onTap: _deleting
                                ? null
                                : () =>
                                      setState(() => _showDeleteConfirm = true),
                            child: Text(
                              _deleting ? 'Deleting…' : 'Delete Account',
                              style: const TextStyle(
                                color: AppColors.coralDark,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'This action is permanent and cannot be undone.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_showChangePassword)
                _ChangePasswordDialog(
                  onClose: () => setState(() => _showChangePassword = false),
                ),
              if (_showChangeEmail)
                _ChangeEmailDialog(
                  onClose: () => setState(() => _showChangeEmail = false),
                ),
              if (_showDeleteConfirm)
                _ConfirmDialog(
                  emoji: '⚠️',
                  title: 'Delete Account?',
                  message:
                      'This permanently deletes your profile, saved recipes, and meal plans. This cannot be undone.',
                  confirmLabel: 'Delete',
                  onCancel: () => setState(() => _showDeleteConfirm = false),
                  onConfirm: _deleteAccount,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal for setting a new account password via `AuthCubit.updatePassword`.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPassword = _newPassword.text;
    if (newPassword.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    if (newPassword != _confirmPassword.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await context.read<AuthCubit>().updatePassword(newPassword);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.isSuccess) {
      context.showToast('✅ Password updated!');
      widget.onClose();
    } else {
      setState(() => _error = result.error ?? 'Could not update password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                const Text(
                  'Change Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _Field(
                  label: 'New Password',
                  controller: _newPassword,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Confirm Password',
                  controller: _confirmPassword,
                  obscureText: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.coralDark,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _submitting ? null : widget.onClose,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _submitting ? null : _submit,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _submitting ? 'Updating…' : 'Update',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal for changing the account email via `AuthCubit.updateEmail`.
/// Supabase sends a confirmation link; the change applies once clicked.
class _ChangeEmailDialog extends StatefulWidget {
  const _ChangeEmailDialog({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  final _email = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await context.read<AuthCubit>().updateEmail(email);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.isSuccess) {
      context.showToast('📧 Check $email to confirm the change');
      widget.onClose();
    } else {
      setState(() => _error = result.error ?? 'Could not update email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📧', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                const Text(
                  'Change Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _Field(
                  label: 'New Email',
                  controller: _email,
                  hint: 'you@example.com',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.coralDark,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _submitting ? null : widget.onClose,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _submitting ? null : _submit,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _submitting ? 'Sending…' : 'Update',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Blocking confirmation modal for destructive account actions.
class _ConfirmDialog extends StatefulWidget {
  const _ConfirmDialog({
    required this.emoji,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  final String emoji;
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback onCancel;
  final Future<void> Function() onConfirm;

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  bool _busy = false;

  Future<void> _handleConfirm() async {
    setState(() => _busy = true);
    await widget.onConfirm();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _busy ? null : widget.onCancel,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _busy ? null : _handleConfirm,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _busy ? '…' : widget.confirmLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.hint,
    this.obscureText = false,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String? hint;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
            filled: true,
            fillColor: AppColors.bgCard,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 14 : 0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.coral),
            ),
            constraints: maxLines == 1
                ? const BoxConstraints(minHeight: 48, maxHeight: 48)
                : null,
          ),
        ),
      ],
    );
  }
}
