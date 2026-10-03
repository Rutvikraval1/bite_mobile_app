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
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../../core/widgets/glass.dart';
import '../../../auth/domain/entities/auth_state.dart';
import '../../../auth/domain/entities/profile.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../../content/domain/entities/bite_card.dart';
import '../../../content/domain/entities/cook_entry.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../../social/presentation/blocs/follow_cubit.dart';

/// The user's profile hub — live stats from `profiles`, their created
/// recipes, drafts and cooking history, badges/level, and account menu.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _activeTab = 'created';
  bool _gamOpen = false;

  @override
  void initState() {
    super.initState();
    // Always show the latest data when the screen opens (e.g. coming back
    // from Edit Profile or after cooking/publishing elsewhere).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() async {
    final content = context.read<ContentCubit>();
    await Future.wait([
      context.read<AuthCubit>().refreshProfile(),
      content.reloadProfileContent(),
      content.reloadSaved(),
    ]);
  }

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
                  buildWhen: (p, c) =>
                      p.savedItems.length != c.savedItems.length ||
                      p.myRecipes != c.myRecipes ||
                      p.cookHistory != c.cookHistory ||
                      p.profileLoading != c.profileLoading,
                  builder: (context, content) {
                    return RefreshIndicator(
                      color: AppColors.coral,
                      backgroundColor: AppColors.bgCard,
                      onRefresh: _refresh,
                      child: _buildBody(context, auth.profile, appState, content),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Profile? profile, AppState appState, ContentState content) {
    final flow = context.read<FlowCubit>();
    final xp = appState.xp;
    final tier = TierDefinitions.tierFor(xp);
    final avatarEmoji = (profile?.avatarEmoji.isNotEmpty ?? false) ? profile!.avatarEmoji : tier.emoji;
    final displayName = profile?.displayName.trim() ?? '';
    final username = profile?.username.trim() ?? '';
    final bio = profile?.bio.trim() ?? '';
    final followingCount = context.select<FollowCubit, int>((f) => f.state.length);
    // The trigger-maintained counter; fall back to the loaded list length.
    final cookedCount = [profile?.cookedCount ?? 0, content.cookHistory.length]
        .reduce((a, b) => a > b ? a : b);

    final completionFields = [
      displayName.isNotEmpty,
      username.isNotEmpty,
      bio.isNotEmpty,
      profile?.avatarUrl != null || (profile?.avatarEmoji.isNotEmpty ?? false),
      profile?.dob != null || (profile?.ageVerified ?? false),
      profile?.cuisines.isNotEmpty ?? false,
      profile?.dietary.isNotEmpty ?? false,
      profile?.cookingSkill != null,
    ];
    final completionPct = ((completionFields.where((f) => f).length / completionFields.length) * 100).round();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        GestureDetector(
          onTap: flow.goBack,
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
            GestureDetector(
              onTap: () => flow.setScreen(AppScreen.editProfile),
              child: SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: 78,
                      height: 78,
                      child: CustomPaint(painter: _CompletionRingPainter(completionPct / 100)),
                    ),
                    AvatarImg(
                      emoji: avatarEmoji,
                      imageUrl: profile?.avatarUrl,
                      size: 70,
                      borderWidth: 0,
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
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          username.isEmpty ? 'Set a username' : '@$username',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: username.isEmpty ? AppColors.muted : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => flow.setScreen(AppScreen.cookingLevel),
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
                    child: Text(
                      [if (displayName.isNotEmpty) displayName, tier.name, '$xp XP'].join(' · '),
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => flow.setScreen(AppScreen.editProfile),
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
          child: bio.isNotEmpty
              ? Text(bio, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.5))
              : GestureDetector(
                  onTap: () => flow.setScreen(AppScreen.editProfile),
                  child: const Text('+ Add a bio', style: TextStyle(color: AppColors.coral, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
        ),
        if (completionPct < 100)
          GestureDetector(
            onTap: () => flow.setScreen(AppScreen.editProfile),
            child: Glass(
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
                          '$completionPct% complete — finish your profile',
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
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final s in [
              ('$cookedCount', 'Cooked', () => setState(() => _activeTab = 'cooked')),
              ('${content.savedItems.length}', 'Saved', () {
                context.read<AppStateCubit>().setActiveTab(AppTab.saved);
                flow.setScreen(AppScreen.saved);
              }),
              ('${appState.streakCount}🔥', 'Streak', () => flow.setScreen(AppScreen.cookingLevel)),
              ('$followingCount', 'Following', () {
                context.read<AppStateCubit>().setActiveTab(AppTab.social);
                flow.setScreen(AppScreen.socialFeed);
              }),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: s.$3,
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
              for (final t in [
                ('created', 'Created · ${content.publishedRecipes.length}'),
                ('cooked', 'Cooked · ${content.cookHistory.length}'),
                ('drafts', 'Drafts · ${content.draftRecipes.length}'),
              ])
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: _activeTab == t.$1 ? AppColors.coral : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                      alignment: Alignment.center,
                      child: Text(
                        t.$2,
                        style: TextStyle(color: _activeTab == t.$1 ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (content.profileLoading && content.myRecipes.isEmpty && content.cookHistory.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2)),
          )
        else
          _buildTabContent(context, content),
        const SizedBox(height: 16),
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
                    if (item.$4 > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(100)),
                        child: Text('${item.$4}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<(String, String, VoidCallback, int)> _menuItems(BuildContext context) {
    final flow = context.read<FlowCubit>();
    final unread = context.select<AppStateCubit, int>((c) => c.state.notificationCount);
    return [
      ('🏆', 'Cooking Level', () => flow.setScreen(AppScreen.cookingLevel), 0),
      ('🌶', 'Premium', () => flow.setScreen(AppScreen.premium), 0),
      ('🔔', 'Notifications', () => flow.setScreen(AppScreen.notifications), unread),
      ('✏️', 'Edit Profile', () => flow.setScreen(AppScreen.editProfile), 0),
      ('⚙️', 'Settings', () => flow.setScreen(AppScreen.settings), 0),
      ('👋', 'Sign Out', _confirmSignOut, 0),
    ];
  }

  Future<void> _confirmSignOut() async {
    final ok = await _confirm(
      title: 'Sign out?',
      message: "You'll need to sign in again to see your recipes and progress.",
      confirmLabel: 'Sign Out',
    );
    if (ok && mounted) await context.read<AuthCubit>().signOut();
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        content: Text(message, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel, style: const TextStyle(color: AppColors.coral, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openRecipe(BiteCard card) {
    context.read<AppStateCubit>().viewRecipe(card);
    context.read<FlowCubit>().setScreen(AppScreen.recipeDetail);
  }

  void _openCooked(CookEntry entry) {
    final id = entry.recipeId;
    final card = id == null ? null : context.read<ContentCubit>().state.findCard(id);
    if (card == null) {
      context.showToast('${entry.emoji} ${entry.title} is no longer available');
      return;
    }
    _openRecipe(card);
  }

  Future<void> _deleteRecipe(BiteCard card) async {
    final ok = await _confirm(
      title: 'Delete "${card.title}"?',
      message: 'This removes the recipe for everyone. This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!ok || !mounted) return;
    final result = await context.read<ContentCubit>().deleteRecipe(card.id);
    if (!mounted) return;
    context.showToast(result.isSuccess ? '🗑 Recipe deleted' : "⚠️ Couldn't delete: ${result.error}");
  }

  Widget _buildTabContent(BuildContext context, ContentState content) {
    final flow = context.read<FlowCubit>();
    switch (_activeTab) {
      case 'cooked':
        final items = content.cookHistory;
        if (items.isEmpty) {
          return _emptyTab('🍳', 'Nothing cooked yet', 'Finish a recipe in Cook Mode and it shows up here.');
        }
        return _grid([
          for (final e in items)
            _RecipeTile(
              title: e.title,
              subtitle: 'Cooked ${_ago(e.cookedAt)}',
              emoji: e.emoji,
              imageUrl: e.imageUrl,
              onTap: () => _openCooked(e),
            ),
        ]);
      case 'drafts':
        final drafts = content.draftRecipes;
        return Column(
          children: [
            _newRecipeTile(flow, height: 64, horizontal: true),
            const SizedBox(height: 10),
            if (drafts.isEmpty)
              _emptyTab('📝', 'No drafts', 'Use "Save Draft" when creating a recipe to finish it later.')
            else
              for (final r in drafts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () => _openRecipe(r),
                    onLongPress: () => _deleteRecipe(r),
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
                                Text(
                                  '📝 Draft${r.createdAt != null ? ' · ${_ago(r.createdAt!)}' : ''}',
                                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteRecipe(r),
                            icon: Icon(Icons.delete_outline, size: 18, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        );
      default:
        final mine = content.publishedRecipes;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _grid([
              _newRecipeTile(flow),
              for (final r in mine)
                _RecipeTile(
                  title: r.title,
                  subtitle: '${r.cuisine} · ${r.time}',
                  emoji: r.emoji,
                  imageUrl: r.image,
                  onTap: () => _openRecipe(r),
                  onLongPress: () => _deleteRecipe(r),
                ),
            ]),
            if (mine.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Share your first recipe with the community 🌶',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Long-press a recipe to delete it',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 11),
                ),
              ),
          ],
        );
    }
  }

  Widget _grid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: children,
    );
  }

  Widget _newRecipeTile(FlowCubit flow, {double? height, bool horizontal = false}) {
    final label = [
      const Icon(Icons.add, size: 22, color: AppColors.coral),
      SizedBox(width: horizontal ? 8 : 0, height: horizontal ? 0 : 6),
      const Text('New Recipe', style: TextStyle(color: AppColors.coral, fontSize: 13, fontWeight: FontWeight.w600)),
    ];
    return GestureDetector(
      onTap: () => flow.setScreen(AppScreen.creatorCreate),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.coral.withValues(alpha: 0.35), width: 2),
        ),
        alignment: Alignment.center,
        child: horizontal
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: label)
            : Column(mainAxisSize: MainAxisSize.min, children: label),
      ),
    );
  }

  Widget _emptyTab(String emoji, String title, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes}m ago';
    if (d.inDays < 1) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    if (d.inDays < 30) return '${d.inDays ~/ 7}w ago';
    return '${d.inDays ~/ 30}mo ago';
  }
}

/// Grid tile for a created or cooked recipe — photo if present, else emoji.
class _RecipeTile extends StatelessWidget {
  const _RecipeTile({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
    this.imageUrl,
    this.onLongPress,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.coral.withValues(alpha: 0.13), AppColors.bgCard]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null && url.isNotEmpty)
              AppNetworkImage(url)
            else
              Align(
                alignment: const Alignment(0, -0.35),
                child: Text(emoji, style: const TextStyle(fontSize: 34)),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC000000)],
                  stops: [0.4, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
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
    final owned = userBadges.toSet();
    final tier = TierDefinitions.tierFor(xp);
    if (!open) {
      return PopIn(
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('✨', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text('Badges & Level', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Text('·', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${owned.length}/${catalog.BadgeCatalog.all.length} badges · Lv ${tier.level}',
                    style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.cyan),
              ],
            ),
          ),
        ),
      );
    }

    // Owned badges first.
    final sorted = [...catalog.BadgeCatalog.all]
      ..sort((a, b) => (owned.contains(b.id) ? 1 : 0) - (owned.contains(a.id) ? 1 : 0));
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
            GestureDetector(
              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.cookingLevel),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 14),
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
            Text(
              '🏅 BADGES · ${owned.length} OF ${catalog.BadgeCatalog.all.length}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: catalog.BadgeCatalog.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final b = sorted[i];
                  final isOwned = owned.contains(b.id);
                  return GestureDetector(
                    onTap: () => context.showToast(isOwned ? '${b.emoji} ${b.name} — ${b.rarity}' : '🔒 ${b.name} — ${b.description}'),
                    child: Opacity(
                      opacity: isOwned ? 1 : 0.45,
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
                            Text(isOwned ? b.emoji : '🔒', style: const TextStyle(fontSize: 28)),
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
