import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/badge_catalog.dart' as catalog;
import '../../../../core/constants/tier_definitions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/glass.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../data/mock_profile_data.dart';

/// The user's profile hub — stats, gamification teaser panel, created/cooked
/// recipes and the settings menu. Ports `ProfileScreen`.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeTab = 'created';
  bool _gamOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        // buildWhen: only rebuild this long screen for the fields it reads.
        child: BlocBuilder<AuthCubit, AuthState>(
          buildWhen: (p, c) => p.profile != c.profile,
          builder: (context, auth) {
            return BlocBuilder<AppStateCubit, AppState>(
              buildWhen: (p, c) =>
                  p.xp != c.xp || p.userBadges != c.userBadges || p.streakCount != c.streakCount,
              builder: (context, appState) {
                return BlocBuilder<ContentCubit, ContentState>(
                  buildWhen: (p, c) => p.savedItems.length != c.savedItems.length,
                  builder: (context, content) {
                    return _buildBody(context, auth.profile, appState, content.savedItems.length);
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Profile? profile, AppState appState, int savedCount) {
    final xp = appState.xp;
    final tier = TierDefinitions.tierFor(xp);
    final avatarEmoji = (profile?.avatarEmoji.isNotEmpty ?? false) ? profile!.avatarEmoji : tier.emoji;
    final displayName = (profile?.displayName.isNotEmpty ?? false) ? profile!.displayName : 'Chef Fuego';
    final username = (profile?.username.isNotEmpty ?? false) ? profile!.username : 'homecook';
    final bio = (profile?.bio.isNotEmpty ?? false) ? profile!.bio : 'Love experimenting with Korean & Thai flavors 🌶🍜';
    final badgeCount = appState.userBadges.length;

    final completionFields = [
      profile?.displayName.isNotEmpty ?? false,
      profile?.username.isNotEmpty ?? false,
      profile?.bio.isNotEmpty ?? false,
      profile?.avatarEmoji.isNotEmpty ?? false,
      profile?.dob != null || (profile?.ageVerified ?? false),
      profile?.cuisines.isNotEmpty ?? false,
      profile?.dietary.isNotEmpty ?? false,
      profile?.cookingSkill != null,
    ];
    final completionPct = ((completionFields.where((f) => f).length / completionFields.length) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        GestureDetector(
          onTap: () => context.read<FlowCubit>().goBack(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 20, color: AppColors.muted),
              const SizedBox(width: 6),
              Text('Back', style: TextStyle(color: AppColors.muted, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 78,
              height: 78,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: CustomPaint(painter: _CompletionRingPainter(completionPct / 100)),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.coral.withValues(alpha: 0.27), AppColors.amber.withValues(alpha: 0.27)],
                      ),
                    ),
                    child: Text(avatarEmoji, style: const TextStyle(fontSize: 32)),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgDark,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.coral, width: 1.5),
                      ),
                      child: Text('$completionPct%', style: const TextStyle(color: AppColors.coral, fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('@$username', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.read<FlowCubit>().setScreen(AppScreen.cookingLevel),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                          ),
                          child: Text('${tier.emoji} Lvl ${tier.level}', style: const TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('$displayName · ${tier.name} · $xp XP', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.editProfile),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.glass, border: Border.all(color: AppColors.glassBorder)),
                child: Icon(Icons.edit_outlined, size: 16, color: AppColors.muted),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 88, top: 8, bottom: 12),
          child: Text(bio, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.5)),
        ),
        Glass(
          borderRadius: 14,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.amber.withValues(alpha: 0.08)),
                child: const Icon(Icons.track_changes_rounded, size: 16, color: AppColors.amber),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completionPct% complete — ${completionPct >= 100 ? 'profile looks great!' : 'finish your profile for +50 pts'}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: completionPct / 100,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(AppColors.coral),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.muted),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final s in [
              ('0', 'Cooked'),
              ('$savedCount', 'Saved'),
              ('${appState.streakCount}🔥', 'Streak'),
              ('$badgeCount', 'Badges'),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ZoomIn(
                    child: Glass(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(s.$2, style: TextStyle(color: AppColors.muted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _GamificationPanel(
          open: _gamOpen,
          onToggle: () => setState(() => _gamOpen = !_gamOpen),
          xp: xp,
          userBadges: appState.userBadges,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              for (final t in ['created', 'cooked', 'my recipes'])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: _activeTab == t ? AppColors.coral : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(
                        t == 'my recipes' ? '📸 Mine' : t[0].toUpperCase() + t.substring(1),
                        style: TextStyle(color: _activeTab == t ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTabContent(context),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.showToast('🏠 My Kitchen — coming soon!'),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.amber.withValues(alpha: 0.07), AppColors.coral.withValues(alpha: 0.03)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.amber.withValues(alpha: 0.2), AppColors.coral.withValues(alpha: 0.13)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('🏠', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('My Kitchen', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.13),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: AppColors.amber.withValues(alpha: 0.27)),
                            ),
                            child: const Text('COMING SOON', style: TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      Text(
                        'Design your virtual kitchen — walls, floors, appliances. Earn items by cooking!',
                        style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
              ],
            ),
          ),
        ),
        for (final item in _menuItems(context))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: item.$3,
              child: Glass(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Text(item.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(item.$2, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500))),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<(String, String, VoidCallback)> _menuItems(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final authCubit = context.read<AuthCubit>();
    return [
      ('🏆', 'Cooking Level', () => flow.setScreen(AppScreen.cookingLevel)),
      ('🌶', 'Premium', () => flow.setScreen(AppScreen.premium)),
      ('💚', 'My Impact', () => flow.setScreen(AppScreen.communityImpact)),
      ('🔔', 'Notification Settings', () => flow.setScreen(AppScreen.notifications)),
      ('✏️', 'Edit Profile', () => flow.setScreen(AppScreen.editProfile)),
      ('⚙️', 'Settings', () => flow.setScreen(AppScreen.settings)),
      ('👋', 'Sign Out', () => authCubit.signOut()),
    ];
  }

  Widget _buildTabContent(BuildContext context) {
    if (_activeTab == 'created') {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.creatorCreate),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                ),
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 24, color: AppColors.coral),
                    SizedBox(height: 6),
                    Text('New Recipe', style: TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.recipeDetail),
              child: Container(
                height: 100,
                padding: const EdgeInsets.all(12),
                alignment: Alignment.bottomLeft,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.coral.withValues(alpha: 0.13), AppColors.bgCard]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Gochujang Chicken', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    Text('❤️ 1.2K', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_activeTab == 'cooked') {
      const items = ['Birria Tacos', 'Pad Thai', 'Miso Ramen'];
      const colors = [AppColors.amber, AppColors.cyan, AppColors.coral];
      const ago = ['2d', '1w', '2w'];
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => context.read<FlowCubit>().setScreen(AppScreen.recipeDetail),
          child: Container(
            padding: const EdgeInsets.all(12),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [colors[i].withValues(alpha: 0.13), AppColors.bgCard]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(items[i], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Cooked ${ago[i]} ago', style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
        ),
      );
    }
    // my recipes
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.read<FlowCubit>().setScreen(AppScreen.genieScan),
          child: Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.4), width: 2),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined, size: 20, color: AppColors.coral),
                SizedBox(width: 10),
                Text('Scan / Upload Recipe', style: TextStyle(color: AppColors.coral, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        for (final r in MockProfileData.myRecipes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.recipeDetail),
              child: Glass(
                borderRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(10)),
                      child: Text(r.emoji, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('📸 Scanned · ${r.date}', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
        Text('Personal recipes never expire', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11)),
      ],
    );
  }
}

class _CompletionRingPainter extends CustomPainter {
  const _CompletionRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final base = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, base);
    final fg = Paint()
      ..color = AppColors.coral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 6.28319 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant _CompletionRingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _GamificationPanel extends StatelessWidget {
  const _GamificationPanel({required this.open, required this.onToggle, required this.xp, required this.userBadges});

  final bool open;
  final VoidCallback onToggle;
  final int xp;
  final List<String> userBadges;

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return PopIn(
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            height: 48,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  const Text('Gamification', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Text('·', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text('Badges · Pets · Frames', style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w500)),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.cyan),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final owned = userBadges.toSet();
    const challengeProgress = 3;
    const challengeTotal = 5;
    final tier = TierDefinitions.tierFor(xp);

    return ZoomIn(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.13)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ACTIVE CHALLENGE', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            Glass(
              borderRadius: 14,
              padding: const EdgeInsets.all(14),
              borderColor: AppColors.amber.withValues(alpha: 0.13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Pulse(
                        duration: const Duration(milliseconds: 3000),
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.amber.withValues(alpha: 0.07),
                            border: Border.all(color: AppColors.amber.withValues(alpha: 0.27), width: 2),
                          ),
                          child: const Text('🐕', style: TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🌮 Taco Trail', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                            Text('Visit 5 Mexican restaurants this week', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: challengeProgress / challengeTotal,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$challengeProgress / $challengeTotal', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                      const Text('🐾 Nacho + 150 XP', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.cookingLevel),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Text('See all challenges', style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right_rounded, size: 12, color: AppColors.cyan),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('🏅 RECENT BADGES', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: catalog.BadgeCatalog.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final b = catalog.BadgeCatalog.all[i];
                  final isOwned = owned.contains(b.id);
                  return GestureDetector(
                    onTap: () => context.showToast(isOwned ? '${b.emoji} ${b.name} — ${b.rarity}' : '🔒 ${b.name} — ${b.description}'),
                    child: Opacity(
                      opacity: isOwned ? 1 : 0.55,
                      child: Container(
                        width: 72,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: b.color.withValues(alpha: isOwned ? 0.4 : 0.15)),
                        ),
                        child: Column(
                          children: [
                            Text(b.emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(height: 4),
                            Text(
                              b.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 9, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text('🐾 COMPANIONS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockProfileData.pets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final p = MockProfileData.pets[i];
                  return Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: p.active
                              ? const SweepGradient(colors: [AppColors.coral, AppColors.amber, AppColors.cyan, AppColors.coral])
                              : null,
                          color: p.active ? null : Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bgCard),
                          child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(p.name, style: TextStyle(color: p.active ? AppColors.amber : AppColors.muted, fontSize: 9, fontWeight: FontWeight.w600)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            const Text('🖼 FRAMES', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockProfileData.frames.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = MockProfileData.frames[i];
                  return Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: f.colors.isNotEmpty ? SweepGradient(colors: f.colors) : null,
                          color: f.colors.isEmpty ? Colors.white.withValues(alpha: 0.06) : null,
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.bgCard),
                          child: const Text('🧑‍🍳', style: TextStyle(fontSize: 20)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(f.name, style: TextStyle(color: f.name == 'Default' ? AppColors.muted : AppColors.amber, fontSize: 9, fontWeight: FontWeight.w600)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.cookingLevel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Text(tier.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 10),
                    Text('Lv ${tier.level} · ${tier.name}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: TierDefinitions.progressInTier(xp),
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$xp/${tier.max}', style: TextStyle(color: AppColors.muted, fontSize: 10, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text('Hide', style: TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
