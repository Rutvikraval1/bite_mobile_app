import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/tier_definitions.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../../core/widgets/glass.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../../content/domain/entities/bite_card.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../../gamification/domain/tip_selection.dart';
import '../../data/chat_selection.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/social_models.dart';
import '../blocs/follow_cubit.dart';
import '../blocs/social_feed_cubit.dart';
import '../social_navigation.dart';

const List<Color> _recipeTints = [
  AppColors.coral,
  AppColors.amber,
  AppColors.cyan,
  AppColors.placesPurple,
  Color(0xFF4CAF50),
];

/// Creator profile — ports `CreatorProfileScreen` from `screens-social.jsx`.
/// Shows the creator picked via [CreatorSelection] (feed avatar, creator
/// card, notification…), loaded from `public.creators` + their recipes.
class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool _showMenu = false;
  String? _menuToast;
  Timer? _toastTimer;

  final String? _handle = CreatorSelection.instance.handle;
  Creator? _creator;
  bool _loading = true;

  /// Whether the user followed this creator when [_creator] was loaded —
  /// lets the Followers stat move as they tap Follow.
  bool _followedAtLoad = false;

  @override
  void initState() {
    super.initState();
    final handle = _handle;
    if (handle != null) {
      _creator = context.read<SocialFeedCubit>().state.creators.where((c) => c.handle == handle).firstOrNull;
      _followedAtLoad = context.read<FollowCubit>().isFollowing(handle);
    }
    _load();
  }

  Future<void> _load() async {
    final handle = _handle;
    if (handle == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final creator = await context.read<SocialFeedCubit>().repository.fetchCreator(handle);
      if (!mounted) return;
      setState(() {
        _creator = creator ?? _creator;
        _followedAtLoad = context.read<FollowCubit>().isFollowing(handle);
        _loading = false;
      });
    } catch (e) {
      debugPrint('[social] creator load failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  bool get _isMe {
    final me = context.read<AuthCubit>().state.user?.id;
    return me != null && _creator?.profileId == me;
  }

  Future<void> _mute(String kind) async {
    setState(() => _showMenu = false);
    final c = _creator;
    if (c == null) return;
    if (_isMe) {
      ToastService.instance.show("That's you! 😄");
      return;
    }
    final ok = await context.read<SocialFeedCubit>().mute(c.handle, kind: kind);
    if (!mounted) return;
    if (!ok) {
      ToastService.instance.show("⚠️ Couldn't update. Try again.");
      return;
    }
    if (kind == 'block') {
      final follows = context.read<FollowCubit>();
      if (follows.isFollowing(c.handle)) follows.toggle(c.handle);
    }
    _flashToast(kind == 'block' ? 'Blocked' : 'Muted');
  }

  Future<void> _report() async {
    setState(() => _showMenu = false);
    final c = _creator;
    if (c == null) return;
    final ok = await context.read<SocialFeedCubit>().report('creator', c.handle);
    if (!mounted) return;
    if (ok) {
      _flashToast('Reported');
    } else {
      ToastService.instance.show("⚠️ Couldn't send report. Try again.");
    }
  }

  void _flashToast(String toast) {
    setState(() {
      _showMenu = false;
      _menuToast = toast;
    });
    _toastTimer?.cancel();
    _toastTimer = Timer(Duration(seconds: toast == 'Blocked' ? 3 : 2), () {
      if (mounted) setState(() => _menuToast = null);
    });
  }

  void _openMessage() {
    setState(() => _showMenu = false);
    final c = _creator;
    if (c == null) return;
    if (_isMe) {
      ToastService.instance.show("That's you! 😄");
      return;
    }
    if (!c.canMessage) return;
    messageCreator(context, c.handle, name: c.name);
  }

  void _openTip() {
    final c = _creator;
    if (c == null) return;
    if (_isMe) {
      ToastService.instance.show("That's you! 😄");
      return;
    }
    TipSelection.instance.select(handle: c.handle, emoji: c.avatarEmoji, tagline: c.tagline);
    context.read<FlowCubit>().setScreen(AppScreen.tipFlow);
  }

  void _shareProfile() {
    setState(() => _showMenu = false);
    final c = _creator;
    if (c == null) return;
    ShareSelection.instance.select(ShareTarget(
      kind: ShareKind.creator,
      title: c.name,
      subtitle: '${c.handle} · ${c.recipes} recipes',
      emoji: c.avatarEmoji,
      imageUrl: c.avatarUrl,
      stat: '👥 ${Formatters.compact(c.followers)}',
      handle: c.handle,
    ));
    context.read<FlowCubit>().setScreen(AppScreen.shareSheet);
  }

  @override
  Widget build(BuildContext context) {
    final c = _creator;
    if (c == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: GestureDetector(
                  onTap: () => context.read<FlowCubit>().goBack(),
                  child: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
                        ),
                      )
                    : const EmptyState(emoji: '🧑‍🍳', title: 'Creator not found', message: 'This profile may have been removed.'),
              ),
            ],
          ),
        ),
      );
    }

    final recipes = _recipesOf(c, context.watch<ContentCubit>().state);
    final featured = recipes.where((r) => r.id == c.featuredRecipeId).firstOrNull ??
        (recipes.isEmpty
            ? null
            : recipes.reduce((a, b) => Formatters.numOf(a.hearts) >= Formatters.numOf(b.hearts) ? a : b));
    final following = context.select<FollowCubit, bool>((f) => f.isFollowing(c.handle));
    final followers = c.followers + (following ? 1 : 0) - (_followedAtLoad ? 1 : 0);
    final saves = recipes.fold<double>(0, (sum, r) => sum + Formatters.numOf(r.saved)).round();
    final tier = TierDefinitions.tierFor(c.xp);
    final highlights = c.highlights.isNotEmpty
        ? c.highlights
        : [CreatorHighlight(emoji: tier.emoji, label: tier.name, color: tier.color)];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.read<FlowCubit>().goBack(),
                          child: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showMenu = !_showMenu),
                          child: const Icon(Icons.more_horiz_rounded, size: 22, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.coral, width: 3),
                            boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.2), blurRadius: 24)],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: AvatarImg(emoji: c.avatarEmoji, imageUrl: c.avatarUrl, size: 82, borderWidth: 0),
                        ),
                        const SizedBox(height: 12),
                        Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(c.handle, style: const TextStyle(color: AppColors.coral, fontSize: 13, fontWeight: FontWeight.w600)),
                        if (c.tagline.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(c.tagline, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                        if (c.bio.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            c.bio,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12, height: 1.5),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final b in [for (final h in highlights) (h.emoji, h.label, h.color)])
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: b.$3.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: b.$3.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(b.$1, style: const TextStyle(fontSize: 10)),
                                    const SizedBox(width: 4),
                                    Text(b.$2, style: TextStyle(color: b.$3, fontSize: 10, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _FollowButton(handle: c.handle),
                            if (c.canMessage) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _openMessage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.glass,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: const Text('💬 Message',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                            ),
                            ],
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _openTip,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.glass,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                child: const Text('🌶 Tip',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0x0FFFFFFF)),
                        bottom: BorderSide(color: Color(0x0FFFFFFF)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        for (final s in [
                          ('${c.recipes}', 'Recipes'),
                          (Formatters.compact(followers), 'Followers'),
                          (Formatters.compact(c.following), 'Following'),
                          (Formatters.compact(saves), 'Saves'),
                        ])
                          Column(
                            children: [
                              Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                              Text(s.$2, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (c.specialties.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SPECIALTIES',
                            style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final s in c.specialties)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                ),
                                child: Text(s, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (c.specialties.isEmpty) const SizedBox(height: 14),
                  if (featured != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Glass(
                      borderRadius: 20,
                      padding: EdgeInsets.zero,
                      onTap: () => openRecipe(context, featured.id),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                            child: SizedBox(
                              height: 140,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (featured.image != null)
                                    AppNetworkImage(
                                      featured.image!,
                                      errorBuilder: (_) => const ColoredBox(color: AppColors.bgCard),
                                    )
                                  else
                                    ColoredBox(
                                      color: AppColors.bgCard,
                                      child: Center(child: Text(featured.emoji, style: const TextStyle(fontSize: 44))),
                                    ),
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0x0D000000), Color(0x4D000000)],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: AppColors.coral.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(100)),
                                      child: const Text('⭐ FEATURED',
                                          style: TextStyle(color: AppColors.coral, fontSize: 10, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(featured.title,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text('Signature dish · ${featured.saved} saves · ${featured.comments} comments',
                                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                ),
                                Row(
                                  children: [
                                    Text('⏱ ${featured.time}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                    const SizedBox(width: 12),
                                    Text('🔥 ${featured.diff}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                    if (featured.heat > 0) ...[
                                      const SizedBox(width: 12),
                                      Text('🌶' * featured.heat, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recipes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('ALL RECIPES',
                        style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < recipes.length; i++)
                          SizedBox(
                            width: (MediaQuery.sizeOf(context).width - 24 - 12) / 2,
                            child: ZoomIn(
                              duration: Duration(milliseconds: 200 + i * 40),
                              child: GestureDetector(
                                onTap: () => openRecipe(context, recipes[i].id),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 120,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (recipes[i].image != null)
                                          AppNetworkImage(
                                            recipes[i].image!,
                                            errorBuilder: (_) => ColoredBox(
                                                color: _recipeTints[i % _recipeTints.length].withValues(alpha: 0.2)),
                                          )
                                        else
                                          ColoredBox(
                                            color: _recipeTints[i % _recipeTints.length].withValues(alpha: 0.2),
                                            child: Center(child: Text(recipes[i].emoji, style: const TextStyle(fontSize: 32))),
                                          ),
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 12,
                                          right: 12,
                                          bottom: 12,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(recipes[i].title,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                              Text('❤️ ${recipes[i].hearts}',
                                                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (c.recentTips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RECENT TIPS RECEIVED',
                            style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        for (final t in [
                          for (final tip in c.recentTips)
                            (
                              tip.user,
                              tip.amount,
                              tip.dish,
                              tip.hoursAgo < 24 ? '${tip.hoursAgo}h ago' : '${tip.hoursAgo ~/ 24}d ago',
                              tip.emoji,
                            ),
                        ])
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                            ),
                            child: Row(
                              children: [
                                Text(t.$5, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 12),
                                      children: [
                                        TextSpan(text: t.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                        const TextSpan(text: ' tipped ', style: TextStyle(color: AppColors.muted)),
                                        TextSpan(text: t.$2, style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700)),
                                        TextSpan(text: ' on ${t.$3}', style: const TextStyle(color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                ),
                                Text(t.$4, style: const TextStyle(color: Color(0x33FFFFFF), fontSize: 10)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (recipes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                      child: _KitchenCard(creator: c, recipes: recipes),
                    ),
                ],
              ),
            ),
            if (_showMenu)
              Positioned(
                top: 52,
                right: 16,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 180),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 32)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in [
                        ('📤 Share Profile', _shareProfile, false),
                        if (c.canMessage) ('💬 Send Message', _openMessage, false),
                        ('🔇 Mute', () => _mute('mute'), false),
                        ('🚫 Block User', () => _mute('block'), false),
                        ('⚠️ Report Profile', _report, true),
                      ])
                        GestureDetector(
                          onTap: item.$2,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                            child: Text(item.$1,
                                style: TextStyle(
                                    color: item.$3 ? AppColors.coral : Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (_menuToast != null)
              Positioned(
                top: 56,
                left: 20,
                right: 20,
                child: PopIn(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _menuToast == 'Blocked' ? AppColors.coral.withValues(alpha: 0.09) : const Color(0x1F4CAF50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _menuToast == 'Blocked' ? AppColors.coral.withValues(alpha: 0.2) : const Color(0x404CAF50)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      switch (_menuToast) {
                        'Muted' => '🔇 Creator muted',
                        'Blocked' => '🚫 User blocked',
                        _ => '⚠️ Report submitted',
                      },
                      style: TextStyle(
                          color: _menuToast == 'Blocked' ? AppColors.coral : const Color(0xFF4CAF50),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Follow toggle kept in its own State so tapping it doesn't rebuild the whole
/// profile screen.
class _FollowButton extends StatefulWidget {
  const _FollowButton({required this.handle});

  final String handle;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  @override
  Widget build(BuildContext context) {
    final following = context.select<FollowCubit, bool>((f) => f.isFollowing(widget.handle));
    return GestureDetector(
      onTap: () => context.read<FollowCubit>().toggle(widget.handle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: following ? Colors.transparent : AppColors.coral,
          borderRadius: BorderRadius.circular(100),
          border: following ? Border.all(color: AppColors.coral) : null,
        ),
        child: Text(following ? '✓ Following' : 'Follow',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}

/// The creator's published recipes from the loaded catalog.
List<BiteCard> _recipesOf(Creator c, ContentState content) {
  final seen = <int>{};
  return [
    for (final r in [...content.myRecipes, ...content.recipes])
      if (!r.isDraft &&
          (r.creator.toLowerCase() == c.handle || (c.profileId != null && r.authorId == c.profileId)) &&
          seen.add(r.id))
        r,
  ];
}

/// The creator's kitchen at a glance — tier, cuisines, heat and quickest dish,
/// all computed from their published recipes.
class _KitchenCard extends StatelessWidget {
  const _KitchenCard({required this.creator, required this.recipes});

  final Creator creator;
  final List<BiteCard> recipes;

  static final RegExp _digits = RegExp(r'\d+');

  static int? _minutes(BiteCard r) {
    if (r.prepMin != null || r.cookMin != null) return (r.prepMin ?? 0) + (r.cookMin ?? 0);
    final m = _digits.firstMatch(r.time);
    if (m == null) return null;
    final n = int.parse(m.group(0)!);
    return r.time.toLowerCase().contains('h') && !r.time.toLowerCase().contains('min') ? n * 60 : n;
  }

  @override
  Widget build(BuildContext context) {
    final tier = TierDefinitions.tierFor(creator.xp);
    final progress = TierDefinitions.progressInTier(creator.xp);
    final cuisineCounts = <String, int>{};
    for (final r in recipes) {
      final cuisine = r.cuisine.trim();
      if (cuisine.isNotEmpty) cuisineCounts[cuisine] = (cuisineCounts[cuisine] ?? 0) + 1;
    }
    final topCuisines = (cuisineCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(4).toList();
    final avgHeat = recipes.fold<int>(0, (s, r) => s + r.heat) / recipes.length;
    final hearts = recipes.fold<double>(0, (s, r) => s + Formatters.numOf(r.hearts)).round();
    BiteCard? quickest;
    int? quickestMin;
    for (final r in recipes) {
      final m = _minutes(r);
      if (m != null && m > 0 && (quickestMin == null || m < quickestMin)) {
        quickest = r;
        quickestMin = m;
      }
    }
    final firstName = creator.name.split(' ').first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [AppColors.cyan.withValues(alpha: 0.07), AppColors.amber.withValues(alpha: 0.07)]),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("🏠 $firstName's Kitchen",
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: tier.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(100)),
                child: Text('${tier.emoji} ${tier.name}',
                    style: TextStyle(color: tier.color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(tier.color),
            ),
          ),
          const SizedBox(height: 4),
          Text('${Formatters.compact(creator.xp)} XP', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final s in [
                ('${recipes.length}', 'Dishes'),
                ('${cuisineCounts.length}', 'Cuisines'),
                (avgHeat == 0 ? '—' : '🌶 ${avgHeat.toStringAsFixed(1)}', 'Avg heat'),
                ('❤️ ${Formatters.compact(hearts)}', 'Hearts'),
              ])
                Expanded(
                  child: Column(
                    children: [
                      Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text(s.$2, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                    ],
                  ),
                ),
            ],
          ),
          if (topCuisines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in topCuisines)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text('${e.key} · ${e.value}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                  ),
              ],
            ),
          ],
          if (quickest != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => openRecipe(context, quickest!.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Text(quickest.emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚡ QUICKEST DISH',
                              style: TextStyle(color: AppColors.amber, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                          Text('${quickest.title} · $quickestMin min',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
