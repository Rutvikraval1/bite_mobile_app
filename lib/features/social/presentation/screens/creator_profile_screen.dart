import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../../core/widgets/glass.dart';
import '../../../content/data/image_urls.dart';
import '../../data/chat_selection.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../blocs/follow_cubit.dart';

/// Creator profile — ports `CreatorProfileScreen` from `screens-social.jsx`.
///
/// The prototype always renders the same demo creator (@chefpriya /
/// "Priya Kim") regardless of which post/avatar was tapped to get here, so
/// this port does the same — it's a fixed showcase profile, not driven by
/// which feed item launched it.
class CreatorProfileScreen extends StatefulWidget {
  const CreatorProfileScreen({super.key});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> {
  bool _showMenu = false;
  String? _menuToast;
  Timer? _toastTimer;

  static const _recipes = [
    ('Kimchi Jjigae', '🍲', '1.8K', AppColors.coral, '8934866'),
    ('Tteokbokki', '🌶', '1.5K', AppColors.amber, '958550'),
    ('Bulgogi Bowls', '🥩', '2.1K', AppColors.cyan, '24738513'),
    ('Japchae Noodles', '🍜', '980', AppColors.placesPurple, '8935153'),
    ('Korean Corn Dogs', '🌭', '3.2K', Color(0xFF4CAF50), '24738516'),
    ('Dakgangjeong', '🍗', '1.1K', AppColors.coral, '5773964'),
  ];

  static const _tips = [
    ('@foodielisa', '\$5', 'Gochujang Chicken', '2h ago', '🌶'),
    ('@marco.eats', '\$3', 'Kimchi Jjigae', '1d ago', '🍲'),
    ('@noodlequeen', '\$10', 'Tteokbokki', '3d ago', '🌶'),
  ];

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
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
    ChatSelection.instance.select(const ChatThreadRef(name: 'Priya Kim', avatarLabel: 'P'));
    context.read<FlowCubit>().setScreen(AppScreen.chatThread);
  }

  @override
  Widget build(BuildContext context) {
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
                          child: AvatarImg(emoji: '👩‍🍳', imageUrl: ImageUrls.avatar('34238049'), size: 82, borderWidth: 0),
                        ),
                        const SizedBox(height: 12),
                        const Text('Priya Kim', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        const Text('@chefpriya', style: TextStyle(color: AppColors.coral, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Korean Cuisine Creator · Seoul → NYC',
                            style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        const SizedBox(height: 8),
                        const Text(
                          'Bringing the heat from Seoul to your kitchen 🌶🔥 Traditional meets modern. '
                          '2x b🌶te Challenge winner.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0x80FFFFFF), fontSize: 12, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final b in const [
                              ('🏆', '2x Winner', Color(0xFFFFD700)),
                              ('🔥', 'Top Creator', AppColors.coral),
                              ('📸', '500+ Cooks', AppColors.cyan),
                              ('⭐', '4.9 Rating', AppColors.amber),
                            ])
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
                            const _FollowButton(),
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
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.read<FlowCubit>().setScreen(AppScreen.tipFlow),
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
                        for (final s in const [('47', 'Recipes'), ('12.4K', 'Followers'), ('1.8K', 'Following'), ('38.2K', 'Saves')])
                          Column(
                            children: [
                              Text(s.$1, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                              Text(s.$2, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                            ],
                          ),
                      ],
                    ),
                  ),
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
                            for (final s in const ['🇰🇷 Korean', '🌶 Spicy', '🍗 Fried Chicken', '🥘 Stews', '🥟 Dumplings', '🔥 Grilling'])
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Glass(
                      borderRadius: 20,
                      padding: EdgeInsets.zero,
                      onTap: () => context.read<FlowCubit>().setScreen(AppScreen.recipeDetail),
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
                                  AppNetworkImage(
                                    ImageUrls.large('5774006'),
                                    errorBuilder: (_) => const ColoredBox(color: AppColors.bgCard),
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
                                const Text('Gochujang Glazed Fried Chicken',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text('Her signature dish · 2.4K saves · 89 comments',
                                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                                ),
                                const Row(
                                  children: [
                                    Text('⏱ 25 min', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                                    SizedBox(width: 12),
                                    Text('🔥 Medium', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                                    SizedBox(width: 12),
                                    Text('🌶🌶', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                        for (var i = 0; i < _recipes.length; i++)
                          SizedBox(
                            width: (MediaQuery.sizeOf(context).width - 24 - 12) / 2,
                            child: ZoomIn(
                              duration: Duration(milliseconds: 200 + i * 40),
                              child: GestureDetector(
                                onTap: () => context.read<FlowCubit>().setScreen(AppScreen.recipeDetail),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    height: 120,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        AppNetworkImage(
                                          ImageUrls.small(_recipes[i].$5),
                                          errorBuilder: (_) => ColoredBox(color: _recipes[i].$4.withValues(alpha: 0.2)),
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
                                              Text(_recipes[i].$1,
                                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                              Text('❤️ ${_recipes[i].$3}',
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RECENT TIPS RECEIVED',
                            style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        for (final t in _tips)
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
                    child: GestureDetector(
                      onTap: () => ToastService.instance
                          .show('🍳 Virtual Kitchen coming soon! Customize your dream kitchen with rewards.'),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                              colors: [AppColors.cyan.withValues(alpha: 0.07), AppColors.amber.withValues(alpha: 0.07)]),
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.13)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Opacity(
                                    opacity: 0.3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        for (final (i, e) in const ['🍳', '🔪', '🧂', '🍶', '🥘'].indexed)
                                          Transform.rotate(
                                            angle: (i - 2) * 8 * 3.14159 / 180,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text(e, style: const TextStyle(fontSize: 36)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                          color: AppColors.amber.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(100)),
                                      child: const Text('COMING SOON',
                                          style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🏠 Virtual Kitchen',
                                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      'Earn rewards to customize your dream kitchen. Unlock appliances, decor & '
                                      'rare items through cooking challenges.',
                                      style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      for (final tag in const ['🏆 Earn Items', '🎨 Customize', '🏅 Show Off'])
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.04),
                                            borderRadius: BorderRadius.circular(100),
                                            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                          ),
                                          child: Text(tag, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                        ('📤 Share Profile', () {
                          setState(() => _showMenu = false);
                          context.read<FlowCubit>().setScreen(AppScreen.shareSheet);
                        }, false),
                        ('💬 Send Message', _openMessage, false),
                        ('🔇 Mute', () => _flashToast('Muted'), false),
                        ('🚫 Block User', () => _flashToast('Blocked'), false),
                        ('⚠️ Report Profile', () => _flashToast('Reported'), true),
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
  const _FollowButton();

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  /// This showcase screen always renders @chefpriya (see class docs above).
  static const _handle = '@chefpriya';

  @override
  Widget build(BuildContext context) {
    final following = context.select<FollowCubit, bool>((f) => f.isFollowing(_handle));
    return GestureDetector(
      onTap: () => context.read<FollowCubit>().toggle(_handle),
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
