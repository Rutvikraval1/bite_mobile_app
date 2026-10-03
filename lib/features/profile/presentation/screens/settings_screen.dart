import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/app_env.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/push_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/legal_links.dart';
import '../../../../core/widgets/glass.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../../auth/presentation/onboarding_edit_mode.dart';

/// App settings — food preferences, notification preferences (saved to
/// `profiles`), help/support, legal, invite and sign-out.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showSignOutConfirm = false;

  /// Opens a preference screen from onboarding as an editor.
  void _editPreference(AppScreen screen) {
    OnboardingEditMode.active = true;
    context.read<FlowCubit>().setScreen(screen);
  }

  Future<void> _toggle(String column, bool value) async {
    final result = await context.read<AuthCubit>().updateProfile({column: value});
    if (!mounted) return;
    if (!result.isSuccess) context.showToast("⚠️ Couldn't save setting");
  }

  Future<void> _email({required String subject}) async {
    final address = AppEnv.supportEmail;
    if (address.isEmpty) {
      context.showToast('Support email not configured');
      return;
    }
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: {'subject': subject},
    );
    final opened = await launchUrl(uri);
    if (opened || !mounted) return;
    await Clipboard.setData(ClipboardData(text: address));
    if (mounted) context.showToast('📧 $address copied');
  }

  Future<void> _invite() async {
    final link = AppEnv.inviteUrl;
    if (link.isEmpty) {
      context.showToast('Invite link not configured');
      return;
    }
    await Clipboard.setData(
      ClipboardData(text: 'Join me on ${AppConfig.appName} 🌶 $link'),
    );
    if (mounted) context.showToast('📋 Invite link copied!');
  }

  void _about() {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: AppConfig.versionLabel,
      applicationLegalese: AppConfig.tagline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.read<FlowCubit>().goBack(),
                        child: const Icon(Icons.arrow_back, size: 22, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<AuthCubit, AuthState>(
                    buildWhen: (p, c) => p.profile != c.profile || p.user != c.user,
                    builder: (context, auth) {
                      final profile = auth.profile;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                        children: [
                          _sectionLabel('PREFERENCES'),
                          _menuRow('🍜 Favourite Cuisines', () => _editPreference(AppScreen.onboardingCuisine),
                              detail: profile == null || profile.cuisines.isEmpty ? null : '${profile.cuisines.length} selected'),
                          _menuRow('🍽 Dietary Preferences', () => _editPreference(AppScreen.onboardingDietary),
                              detail: profile == null || profile.dietary.isEmpty ? 'None' : '${profile.dietary.length} set'),
                          _menuRow('👨‍🍳 Skill Level', () => _editPreference(AppScreen.onboardingSkill),
                              detail: profile?.cookingSkill),
                          _sectionLabel('NOTIFICATIONS'),
                          _switchRow(
                            title: '🔔 Push Notifications',
                            subtitle: PushService.instance.isReady
                                ? 'Saves, cooks and activity on your recipes'
                                : 'Not available on this build',
                            value: profile?.pushEnabled ?? true,
                            onChanged: (v) => _toggle('push_enabled', v),
                          ),
                          const SizedBox(height: 8),
                          _switchRow(
                            title: '🍳 Meal Reminders',
                            subtitle: 'Breakfast, lunch & dinner ideas',
                            value: profile?.mealRemindersEnabled ?? true,
                            onChanged: (v) => _toggle('meal_reminders_enabled', v),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GestureDetector(
                              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.notifications),
                              child: const Text(
                                '📬 Open notification inbox →',
                                style: TextStyle(color: AppColors.cyan, fontSize: 12),
                              ),
                            ),
                          ),
                          _sectionLabel('HELP'),
                          _menuRow('🎓 Replay Tutorial', () {
                            context.read<FlowCubit>().setScreen(AppScreen.gamificationTutorial);
                          }),
                          _menuRow('💬 Contact Support', () => _email(subject: '${AppConfig.appName} support')),
                          _menuRow('💡 Send Feedback', () => _email(subject: '${AppConfig.appName} feedback')),
                          _sectionLabel('ABOUT'),
                          _menuRow('📋 Terms of Service', LegalLinks.openTerms),
                          _menuRow('🔐 Privacy Policy', LegalLinks.openPrivacyPolicy),
                          _menuRow('ℹ️ About ${AppConfig.appName}', _about),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.only(top: 20),
                              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
                              child: GestureDetector(
                                onTap: _invite,
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [AppColors.coral.withValues(alpha: 0.08), AppColors.amber.withValues(alpha: 0.08)]),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.25)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_alt_rounded, size: 18, color: AppColors.coral),
                                      SizedBox(width: 8),
                                      Text('Invite Friends to b🌶te', style: TextStyle(color: AppColors.coral, fontSize: 15, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Container(
                              padding: const EdgeInsets.only(top: 20),
                              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
                              child: GestureDetector(
                                onTap: () => setState(() => _showSignOutConfirm = true),
                                child: Container(
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: AppColors.coral.withValues(alpha: 0.05),
                                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.27)),
                                  ),
                                  child: Text(
                                    'Log out${auth.user?.email != null ? ' · ${auth.user!.email}' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: AppColors.coral, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              '${AppConfig.appName} ${AppConfig.versionLabel}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 11),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_showSignOutConfirm)
              _ConfirmDialog(
                emoji: '👋',
                title: 'Log out?',
                message: "You'll need to sign in again to access your profile.",
                confirmLabel: 'Log out',
                onCancel: () => setState(() => _showSignOutConfirm = false),
                onConfirm: () {
                  setState(() => _showSignOutConfirm = false);
                  context.read<AuthCubit>().signOut();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(label, style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
    );
  }

  Widget _menuRow(String label, VoidCallback onTap, {String? detail}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Glass(
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
              if (detail != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(detail, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Glass(
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          _Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: value ? AppColors.coral : Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(width: 20, height: 20, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
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
  final VoidCallback onConfirm;

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
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onCancel,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                          child: Text('Cancel', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: onConfirm,
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(100)),
                          child: Text(confirmLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
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
