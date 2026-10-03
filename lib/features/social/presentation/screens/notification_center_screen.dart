import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../../notifications/domain/app_notification.dart';
import '../../../notifications/presentation/blocs/notifications_cubit.dart';

/// Notification inbox backed by `public.notifications` (live via Realtime).
/// Tap opens the linked recipe/screen and marks it read; swipe to dismiss.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  void _open(BuildContext context, AppNotification n) {
    final cubit = context.read<NotificationsCubit>();
    if (!n.isRead) cubit.markRead(n.id);

    final recipeId = n.recipeId;
    if (recipeId != null) {
      final card = context.read<ContentCubit>().state.findCard(recipeId);
      if (card == null) {
        context.showToast('This recipe is no longer available');
        return;
      }
      context.read<AppStateCubit>().viewRecipe(card);
      context.read<FlowCubit>().setScreen(AppScreen.recipeDetail);
      return;
    }
    final dest = AppScreen.values.where((s) => s.name == n.actionDest).firstOrNull;
    if (dest != null) context.read<FlowCubit>().setScreen(dest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            final cubit = context.read<NotificationsCubit>();
            return Column(
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
                        child: Text(
                          'Notifications',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (state.unreadCount > 0)
                        GestureDetector(
                          onTap: cubit.markAllRead,
                          child: const Text('Mark all read', style: TextStyle(color: AppColors.coral, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.coral,
                    backgroundColor: AppColors.bgCard,
                    onRefresh: cubit.refresh,
                    child: _body(context, state),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, NotificationsState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2));
    }
    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          const Center(child: Text('🔔', style: TextStyle(fontSize: 44))),
          const SizedBox(height: 12),
          const Center(
            child: Text("You're all caught up", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              state.error != null
                  ? "Couldn't load notifications. Pull to retry."
                  : 'When someone saves or cooks your recipes, it shows up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      itemCount: state.items.length,
      itemBuilder: (context, i) {
        final n = state.items[i];
        return Dismissible(
          key: ValueKey(n.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            color: AppColors.coralDark.withValues(alpha: 0.25),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (_) => context.read<NotificationsCubit>().dismiss(n.id),
          child: ZoomIn(
            duration: Duration(milliseconds: 220 + (i.clamp(0, 10)) * 30),
            child: _NotificationRow(notification: n, onTap: () => _open(context, n)),
          ),
        );
      },
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${d.inDays ~/ 7}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    const color = AppColors.coral;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: unread ? Colors.white.withValues(alpha: 0.03) : null,
          border: Border(
            bottom: const BorderSide(color: Color(0x0AFFFFFF)),
            left: BorderSide(color: unread ? color : Colors.transparent, width: 3),
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
                color: color.withValues(alpha: 0.08),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: Text(notification.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  if (notification.body.isNotEmpty)
                    Text(notification.body, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(_ago(notification.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8, top: 10),
              child: Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
