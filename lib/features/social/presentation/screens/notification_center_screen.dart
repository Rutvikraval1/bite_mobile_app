import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/flow_cubit.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../data/mock_social_data.dart';
import '../widgets/quick_rate_sheet.dart';

/// Notification inbox — ports `NotificationCenterScreen` from
/// `screens-social.jsx`. "Smart" notifications surface a quick-rate CTA
/// backed by [QuickRateSheet]; regular ones deep-link via a chevron.
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final Set<int> _dismissed = {};
  RateTarget? _rating;

  void _markAllRead() {
    setState(() {
      for (var i = 0; i < mockNotifications.length; i++) {
        _dismissed.add(i);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.read<FlowCubit>().goBack(),
                          child: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Notifications',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        ),
                        GestureDetector(
                          onTap: _markAllRead,
                          child: const Text('Mark all read',
                              style: TextStyle(color: AppColors.coral, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < mockNotifications.length; i++)
                    if (!_dismissed.contains(i))
                      ZoomIn(
                        duration: Duration(milliseconds: 220 + i * 30),
                        child: _NotificationRow(
                          notification: mockNotifications[i],
                          highlighted: i < 3,
                          onAction: () {
                            final n = mockNotifications[i];
                            if (n.rateTarget != null) {
                              setState(() => _rating = n.rateTarget);
                            } else if (n.actionDest != null) {
                              context.read<FlowCubit>().setScreen(n.actionDest!);
                            }
                          },
                          onDismiss: () => setState(() => _dismissed.add(i)),
                          onChevron: () {
                            final dest = mockNotifications[i].actionDest;
                            if (dest != null) context.read<FlowCubit>().setScreen(dest);
                          },
                        ),
                      ),
                ],
              ),
            ),
            if (_rating != null)
              QuickRateSheet(
                target: _rating!,
                onClose: () => setState(() => _rating = null),
                onShared: (result) {
                  context.read<AppStateCubit>().setSharedPost(SharedPost(
                        rating: result.rating,
                        comment: result.comment.isEmpty ? 'Just rated!' : result.comment,
                        photo: result.photo ? 'added' : null,
                        name: _rating!.name,
                        emoji: _rating!.emoji,
                      ));
                  setState(() => _rating = null);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.highlighted,
    required this.onAction,
    required this.onDismiss,
    required this.onChevron,
  });

  final AppNotification notification;
  final bool highlighted;
  final VoidCallback onAction;
  final VoidCallback onDismiss;
  final VoidCallback onChevron;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted ? Colors.white.withValues(alpha: 0.03) : null,
        border: Border(
          bottom: const BorderSide(color: Color(0x0AFFFFFF)),
          left: BorderSide(color: highlighted ? notification.color : Colors.transparent, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: notification.color.withValues(alpha: 0.08),
              border: Border.all(color: notification.color.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.center,
            child: Text(notification.icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('${notification.time} ago', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
                if (notification.isSmart)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onAction,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(color: notification.color, borderRadius: BorderRadius.circular(100)),
                            child: Text(notification.actionLabel ?? 'View',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onDismiss,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Text('Dismiss',
                                style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (!notification.isSmart)
            GestureDetector(
              onTap: onChevron,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
