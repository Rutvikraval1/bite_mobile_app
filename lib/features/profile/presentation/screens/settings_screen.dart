import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/legal_links.dart';
import '../../../../core/widgets/glass.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';

/// App settings — display density, preferences, family mode, notifications,
/// help, privacy, invite, and account actions. Ports `SettingsScreen`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _familyMode = false;
  bool _mealReminders = true;
  bool _pushNotifs = true;
  bool _showRestartConfirm = false;
  bool _showSignOutConfirm = false;
  String _density = 'auto';

  void _setDensity(String mode) {
    setState(() => _density = mode);
    final label = mode == 'auto' ? 'Auto (screen size)' : mode == 'compact' ? 'Compact' : 'Comfortable';
    context.showToast('🖥 Display: $label');
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      _sectionLabel('DISPLAY'),
                      Glass(
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🖥 Layout density', style: TextStyle(color: Colors.white, fontSize: 14)),
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 10),
                              child: Text('Override screen-size detection for this session', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                            ),
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                              ),
                              child: Row(
                                children: [
                                  for (final opt in const [('auto', 'Auto', 'Detect'), ('compact', 'Compact', 'Phone'), ('comfortable', 'Comfortable', 'Tablet')])
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _setDensity(opt.$1),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          decoration: BoxDecoration(
                                            color: _density == opt.$1 ? AppColors.coral : Colors.transparent,
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(opt.$2, style: TextStyle(color: _density == opt.$1 ? Colors.white : AppColors.muted, fontSize: 12, fontWeight: _density == opt.$1 ? FontWeight.w700 : FontWeight.w500)),
                                              Text(opt.$3, style: TextStyle(color: (_density == opt.$1 ? Colors.white : AppColors.muted).withValues(alpha: 0.75), fontSize: 9)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_density != 'auto')
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 11, color: AppColors.amber),
                                    const SizedBox(width: 4),
                                    Text('Preview mode — overrides device detection', style: TextStyle(color: AppColors.amber, fontSize: 10)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _sectionLabel('PREFERENCES'),
                      for (final item in const ['🍽 Dietary Preferences', '👨‍🍳 Skill Level', '🌙 Appearance']) _menuRow(item, () => context.showToast('Coming soon')),
                      _sectionLabel('FAMILY'),
                      Glass(
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('👨‍👩‍👧 Family Mode', style: TextStyle(color: Colors.white, fontSize: 14)),
                                  Text('Let kids suggest meal ideas', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                                ],
                              ),
                            ),
                            _Switch(value: _familyMode, onChanged: (v) => setState(() => _familyMode = v)),
                          ],
                        ),
                      ),
                      if (_familyMode) _familyPanel(context),
                      _sectionLabel('NOTIFICATIONS'),
                      Glass(
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Expanded(child: Text('🔔 Push Notifications', style: TextStyle(color: Colors.white, fontSize: 14))),
                            _Switch(value: _pushNotifs, onChanged: (v) => setState(() => _pushNotifs = v)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Glass(
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🍳 Meal Reminders', style: TextStyle(color: Colors.white, fontSize: 14)),
                                  Text('7:30 AM · 11:30 AM · 5:30 PM', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                                ],
                              ),
                            ),
                            _Switch(value: _mealReminders, onChanged: (v) => setState(() => _mealReminders = v)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () => context.read<FlowCubit>().setScreen(AppScreen.mealReminder),
                          child: Text(
                            '🕐 Preview Meal Reminder popup →',
                            style: TextStyle(color: AppColors.cyan, fontSize: 12, decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                      _sectionLabel('HELP'),
                      _menuRow('🎓 Replay Tutorial', () {
                        context.read<FlowCubit>().setScreen(AppScreen.gamificationTutorial);
                        context.showToast('🎓 Tutorial replaying...');
                      }),
                      _menuRow('💬 Contact Support', () => context.showToast('📧 Support email copied!')),
                      _sectionLabel('PRIVACY'),
                      for (final item in const ['🔒 Privacy Settings', '📊 Data & Storage', '🛡 Blocked Users']) _menuRow(item, () => context.showToast('Coming soon')),
                      _sectionLabel('ABOUT'),
                      _menuRow('📋 Terms of Service', LegalLinks.openTerms),
                      _menuRow('🔐 Privacy Policy', LegalLinks.openPrivacyPolicy),
                      for (final item in const ['ℹ️ About b🌶te', '💬 Send Feedback']) _menuRow(item, () => context.showToast('Coming soon')),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => context.showToast('📋 Invite link copied!'),
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
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Earn 50 XP for every friend who joins!', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Container(
                          padding: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _showRestartConfirm = true),
                                child: Container(
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                  child: Text('🔄 Restart Demo', style: TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Resets all progress to onboarding', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Container(
                          padding: const EdgeInsets.only(top: 20),
                          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
                          child: BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, auth) {
                              return GestureDetector(
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
                                    style: const TextStyle(color: AppColors.coral, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text('b🌶te v1.0.0', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showRestartConfirm)
              _ConfirmDialog(
                emoji: '🔄',
                title: 'Restart Demo?',
                message: 'This clears all progress and returns to the beginning.',
                confirmLabel: 'Restart',
                onCancel: () => setState(() => _showRestartConfirm = false),
                onConfirm: () {
                  setState(() => _showRestartConfirm = false);
                  context.read<AppStateCubit>().resetToGuest();
                  context.read<FlowCubit>().resetTo(AppScreen.swipeDeck);
                },
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

  Widget _menuRow(String label, VoidCallback onTap) {
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
              Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _familyPanel(BuildContext context) {
    const suggestions = [
      (kid: 'Liam', idea: 'Mac & Cheese Pizza 🍕', note: 'Can we make this?', time: '2h ago', avatar: '👦', color: AppColors.coral),
      (kid: 'Emma', idea: 'Rainbow Smoothie Bowl 🌈', note: 'I saw it on YouTube!', time: 'Yesterday', avatar: '👧', color: AppColors.cyan),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Glass(
        borderRadius: 12,
        borderColor: AppColors.amber.withValues(alpha: 0.13),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🧒 Kids Corner Active', style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text("Linked kids can submit meal ideas. You'll get notifications to approve them.", style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ),
            for (final s in suggestions)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                        border: Border.all(color: s.color.withValues(alpha: 0.2)),
                      ),
                      child: Text(s.avatar, style: const TextStyle(fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              children: [
                                TextSpan(text: '${s.kid} suggested: '),
                                TextSpan(text: s.idea, style: const TextStyle(color: AppColors.amber)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 6),
                            child: Text('"${s.note}"', style: TextStyle(color: AppColors.muted, fontSize: 11, fontStyle: FontStyle.italic)),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.showToast('✅ Saved to list!'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(100)),
                                  child: const Text('✓ Save to List', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => context.showToast('🍳 Opening cook mode...'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(100)),
                                  child: const Text('🍳 Cook It!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(s.time, style: TextStyle(color: AppColors.muted, fontSize: 10)),
                  ],
                ),
              ),
            GestureDetector(
              onTap: () => context.showToast("👶 Child linking coming in Phase 2"),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.amber.withValues(alpha: 0.27))),
                alignment: Alignment.center,
                child: Text("+ Link a Child's Account", style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
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
