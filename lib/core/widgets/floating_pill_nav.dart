import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../router/app_screen.dart';
import '../router/flow_cubit.dart';
import '../state/app_state.dart';
import '../state/app_state_cubit.dart';
import '../theme/app_colors.dart';
import 'animations/loops.dart';

/// Floating bottom pill nav — ports `FloatingPillNav` from `ui.jsx`.
class FloatingPillNav extends StatelessWidget {
  const FloatingPillNav({super.key});

  void _onTap(BuildContext context, AppTab tab, AppScreen screen) {
    context.read<AppStateCubit>().setActiveTab(tab);
    final flow = context.read<FlowCubit>();
    if (flow.state.screen != screen) flow.setScreen(screen);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppStateCubit, AppState>(
      // Only the active tab affects the nav; skip rebuilds for XP/coins/etc.
      buildWhen: (prev, next) => prev.activeTab != next.activeTab,
      builder: (context, state) {
        return Positioned(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.paddingOf(context).bottom,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgDark.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                  const BoxShadow(color: Color(0x0FFFFFFF), spreadRadius: 0.5),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    color: AppColors.coral,
                    active: state.activeTab == AppTab.home,
                    onTap: () =>
                        _onTap(context, AppTab.home, AppScreen.swipeDeck),
                  ),
                  _NavItem(
                    icon: Icons.people_alt_rounded,
                    label: 'Social',
                    color: AppColors.cyan,
                    active: state.activeTab == AppTab.social,
                    onTap: () =>
                        _onTap(context, AppTab.social, AppScreen.socialFeed),
                  ),
                  _GenieFab(
                    active: state.activeTab == AppTab.genie,
                    onTap: () => _onTap(context, AppTab.genie, AppScreen.genie),
                  ),
                  _NavItem(
                    icon: Icons.bookmark_rounded,
                    label: 'Saved',
                    color: AppColors.amber,
                    active: state.activeTab == AppTab.saved,
                    onTap: () => _onTap(context, AppTab.saved, AppScreen.saved),
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    color: Colors.white,
                    active: state.activeTab == AppTab.chat,
                    onTap: () =>
                        _onTap(context, AppTab.chat, AppScreen.chatList),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? color : AppColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: foreground, weight: active ? 700 : 300),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: foreground,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (active) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GenieFab extends StatelessWidget {
  const _GenieFab({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pulse(
            amount: 0.06,
            duration: const Duration(milliseconds: 2400),
            child: GestureDetector(
              onTap: onTap,
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.amber, AppColors.coral],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.amber.withValues(alpha: 0.45),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Genie',
            style: TextStyle(
              fontSize: 10,
              color: active ? AppColors.amber : AppColors.muted,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
