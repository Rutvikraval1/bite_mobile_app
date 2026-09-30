import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/badge_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';

/// Share destination pill definition.
class _ShareDest {
  const _ShareDest(this.icon, this.label, this.color);

  final String icon;
  final String label;
  final Color color;
}

const List<_ShareDest> _destinations = [
  _ShareDest('💬', 'b🌶te Chat', AppColors.coral),
  _ShareDest('👨‍👩‍👧‍👦', 'Send to Kitchen', AppColors.cyan),
  _ShareDest('📸', 'Post to Feed', AppColors.amber),
  _ShareDest('📱', 'Message', Colors.white),
  _ShareDest('🔗', 'Copy Link', AppColors.cyan),
  _ShareDest('📷', 'Instagram', Color(0xFFE1306C)),
  _ShareDest('💬', 'WhatsApp', Color(0xFF25D366)),
  _ShareDest('•••', 'More', Colors.white),
];

const List<(String, Color)> _quickSendPeople = [
  ('Marcus', AppColors.cyan),
  ('Foodie Crew', AppColors.amber),
  ('Sarah', AppColors.coral),
  ('Mom', AppColors.placesPurple),
  ('Jake', AppColors.drinksBlue),
];

/// Share bottom sheet — ports `ShareActionSheet` from `screens-social.jsx`.
/// Reached from many places (feed posts, recipe detail, profile menu) via
/// `AppScreen.shareSheet`; always shows the same demo recipe preview, just
/// like the prototype.
class ShareActionSheet extends StatefulWidget {
  const ShareActionSheet({super.key});

  @override
  State<ShareActionSheet> createState() => _ShareActionSheetState();
}

class _ShareActionSheetState extends State<ShareActionSheet> {
  String? _sent;
  bool _sharing = false;
  Timer? _closeTimer;

  static const Map<String, String> _messages = {
    'b🌶te Chat': '📨 Shared to b🌶te Chat!',
    'Post to Feed': '📸 Posted to your feed!',
    'Send to Kitchen': '👨‍👩‍👧‍👦 Sent to Kitchen!',
    'Message': '📱 Opening Messages...',
    'Copy Link': '🔗 Link copied!',
    'Instagram': '📷 Opening Instagram Stories...',
    'WhatsApp': '💬 Opening WhatsApp...',
  };

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _goBack() {
    if (mounted) context.read<FlowCubit>().goBack();
  }

  void _handleShare(String dest) {
    if (_sharing) return;
    setState(() {
      _sharing = true;
      _sent = dest;
    });
    if (dest == 'more') {
      ToastService.instance.show('📋 Link copied to clipboard!');
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _sharing = false);
      });
      return;
    }
    ToastService.instance.show(_messages[dest] ?? '📤 Shared!');
    BadgeService.instance.award(const ['first_share']);
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 1500), _goBack);
  }

  void _quickSend(String name) {
    ToastService.instance.show('📨 Sent to $name!');
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 1500), _goBack);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      body: GestureDetector(
        onTap: _goBack,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: SlideUp(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                decoration: const BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 20),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF)))),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(colors: [AppColors.coral.withValues(alpha: 0.27), AppColors.bgCard]),
                              ),
                              alignment: Alignment.center,
                              child: const Text('🍗', style: TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Gochujang Glazed Fried Chicken',
                                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                  Text('by @chefpriya · 25 min', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Text('❤️ 2.4K', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('SHARE TO',
                              style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 12,
                        children: [
                          for (final d in _destinations)
                            _DestButton(
                              dest: d,
                              sent: _sent == d.label,
                              onTap: () => _handleShare(d.label == 'More' ? 'more' : d.label),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x0FFFFFFF)))),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  ToastService.instance.show('📋 Invite link copied! Share it with your friends.'),
                              child: Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.coral.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_alt_rounded, size: 18, color: AppColors.coral),
                                    SizedBox(width: 8),
                                    Text('Invite a Friend to b🌶te',
                                        style: TextStyle(color: AppColors.coral, fontSize: 14, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text('Earn 50 XP for every friend who joins!',
                                  style: TextStyle(color: Color(0x40FFFFFF), fontSize: 10)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x0FFFFFFF)))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('QUICK SEND',
                                style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final p in _quickSendPeople)
                                  GestureDetector(
                                    onTap: () => _quickSend(p.$1),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(colors: [p.$2.withValues(alpha: 0.27), AppColors.bgCard]),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(p.$1[0],
                                              style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(p.$1, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _goBack,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text('Cancel', style: TextStyle(color: AppColors.muted, fontSize: 15)),
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
    );
  }
}

class _DestButton extends StatelessWidget {
  const _DestButton({required this.dest, required this.sent, required this.onTap});

  final _ShareDest dest;
  final bool sent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sent ? const Color(0x264CAF50) : AppColors.glass,
                border: Border.all(color: sent ? const Color(0xFF4CAF50) : dest.color.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: Text(sent ? '✓' : dest.icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 6),
            Text(dest.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(color: sent ? const Color(0xFF4CAF50) : AppColors.muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
