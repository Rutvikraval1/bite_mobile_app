import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/badge_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/glass.dart';
import '../../domain/cook_session.dart';

/// Post-cook celebration / rate & share flow — ports `PostCookScreen` from
/// `screens-cooking.jsx`. Reads the dish + pace info that `CookModeScreen`
/// captured in [CookSession] rather than any navigation arguments.
class PostCookScreen extends StatefulWidget {
  const PostCookScreen({super.key});

  @override
  State<PostCookScreen> createState() => _PostCookScreenState();
}

class _PostCookScreenState extends State<PostCookScreen> {
  int? _pepperRating;
  int _tipAmount = 5;
  bool _showTipOnPost = true;
  bool _photoUploaded = false;
  final TextEditingController _commentController = TextEditingController();
  bool _showAchievement = false;
  bool _hadReview = false;
  Timer? _achievementShowTimer;
  Timer? _achievementHideTimer;
  late String _finishedOnTime;

  static const Map<int, int> _tipPoints = {3: 30, 5: 50, 10: 100};

  @override
  void initState() {
    super.initState();
    final pace = CookSession.instance.paceRatio;
    _finishedOnTime = pace < 0.9 ? 'early' : (pace < 1.15 ? 'ontime' : 'over');

    BadgeService.instance.award(const ['first_cook']);
    if (!CookSession.instance.isDrink && CookSession.instance.heat >= 3) {
      BadgeService.instance.award(const ['spice_seeker']);
    }
    context.read<AppStateCubit>().addXp(25);

    _achievementShowTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showAchievement = true);
    });
    _achievementHideTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) setState(() => _showAchievement = false);
    });
  }

  @override
  void dispose() {
    _achievementShowTimer?.cancel();
    _achievementHideTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  int get _completedCount =>
      1 + [_photoUploaded, _pepperRating != null, _commentController.text.trim().isNotEmpty].where((b) => b).length;

  @override
  Widget build(BuildContext context) {
    final dishTitle = CookSession.instance.dishTitle;
    final creator = CookSession.instance.creator;

    return Material(
      color: AppColors.bgDark,
      child: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: GestureDetector(
                      onTap: () => context.read<FlowCubit>().setScreen(AppScreen.swipeDeck),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.muted),
                          SizedBox(width: 6),
                          Text('Back', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              const Text('🎉', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 8),
                              const Text('You crushed it!',
                                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text('$dishTitle — complete', style: const TextStyle(color: AppColors.muted, fontSize: 14)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        _paceCard(),
                        const SizedBox(height: 20),
                        _photoUpload(),
                        const SizedBox(height: 20),
                        _pepperCard(),
                        const SizedBox(height: 20),
                        _tipCard(creator),
                        const SizedBox(height: 20),
                        _rewardsPath(),
                        const SizedBox(height: 8),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('+25 pts cooking · +15 pts rating · +10 pts review · +15 pts photo',
                                style: TextStyle(color: AppColors.muted, fontSize: 13), textAlign: TextAlign.center),
                          ),
                        ),
                        _shareButton(dishTitle),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _outlineButton(
                                icon: '📤',
                                label: 'Share with Friend',
                                onTap: () => context.read<FlowCubit>().setScreen(AppScreen.shareSheet),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _outlineButton(
                                icon: '🏆',
                                label: 'Challenge a Friend',
                                color: AppColors.amber,
                                onTap: () => ToastService.instance.show('🏆 Challenge sent to your friends!'),
                              ),
                            ),
                          ],
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () => context.read<FlowCubit>().setScreen(AppScreen.swipeDeck),
                            child: const Text('Done — Back to Deck', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_showAchievement) _achievementBanner(),
          ],
        ),
      ),
    );
  }

  Widget _achievementBanner() {
    return Positioned(
      top: 8,
      left: 16,
      right: 16,
      child: PopIn(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xF2141420),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x40FFD700)),
            boxShadow: const [BoxShadow(color: Color(0x1AFFD700), blurRadius: 24)],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [Color(0x22FFD700), Color(0x22FF6900)]),
                  border: Border.all(color: const Color(0x55FFD700), width: 2),
                ),
                child: const Text('🏅', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('First Cook Complete!', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w800)),
                    Text('+25 XP · Badge unlocked: "Kitchen Debut" 🍳', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showAchievement = false),
                child: const Icon(Icons.close_rounded, size: 14, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paceCard() {
    const options = [
      ('early', 'Early! 🏃', '+50 bonus', Color(0xFF4CAF50)),
      ('ontime', 'On time ✓', '+25 bonus', AppColors.amber),
      ('over', 'Ran over ⏰', 'No bonus', AppColors.muted),
    ];
    return Glass(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⏱ Did you finish on time?', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const Text('Auto-detected from your cook timer — tap to change', style: TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final o in options)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setState(() => _finishedOnTime = o.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _finishedOnTime == o.$1 ? o.$4.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
                          border: Border.all(color: _finishedOnTime == o.$1 ? o.$4 : Colors.white.withValues(alpha: 0.06), width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(o.$2, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(o.$3, style: TextStyle(color: o.$4, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoUpload() {
    return GestureDetector(
      onTap: () => setState(() => _photoUploaded = !_photoUploaded),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _photoUploaded ? AppColors.coral.withValues(alpha: 0.08) : AppColors.glass,
          border: Border.all(
            color: _photoUploaded ? AppColors.coral : Colors.white.withValues(alpha: 0.15),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 28, color: _photoUploaded ? AppColors.coral : AppColors.muted),
            const SizedBox(height: 8),
            Text(_photoUploaded ? 'Photo added! ✓' : 'Add a photo of your dish',
                style: TextStyle(color: _photoUploaded ? AppColors.coral : AppColors.muted, fontSize: 14, fontWeight: FontWeight.w500)),
            const Text('+5 pts', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _pepperCard() {
    const peppers = [
      (1, 'Good', Color(0xFF4CAF50), '🫑'),
      (2, 'Great', Color(0xFFFF9800), '🍊'),
      (3, 'Fire', Color(0xFFD32F2F), '🌶'),
    ];
    return Glass(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How was this recipe?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final p in peppers)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _pepperRating = p.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _pepperRating == p.$1 ? p.$3.withValues(alpha: 0.13) : Colors.white.withValues(alpha: 0.03),
                          border: Border.all(color: _pepperRating == p.$1 ? p.$3 : Colors.white.withValues(alpha: 0.08), width: 2),
                        ),
                        child: Column(
                          children: [
                            Opacity(
                              opacity: _pepperRating == p.$1 ? 1 : 0.5,
                              child: Text(p.$4, style: const TextStyle(fontSize: 32)),
                            ),
                            const SizedBox(height: 8),
                            Text(p.$2, style: TextStyle(color: _pepperRating == p.$1 ? p.$3 : AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: Text('+5 pts', style: TextStyle(color: AppColors.muted, fontSize: 12))),
          ),
          if (_pepperRating != null) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Leave a review (posts to feed)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _commentController,
                  builder: (context, value, _) => Text(
                    value.text.isNotEmpty ? '+3 pts ✓' : '+3 pts',
                    style: TextStyle(color: value.text.isNotEmpty ? AppColors.coral : AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.glass,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: TextField(
                controller: _commentController,
                maxLength: 150,
                maxLines: null,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'What did you love about this recipe? Any tips for others?',
                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  counterText: '',
                ),
                // Only the progress checklist depends on the text, and only
                // on whether it's empty — skip full-screen rebuilds on every
                // keystroke otherwise.
                onChanged: (text) {
                  final hasReview = text.trim().isNotEmpty;
                  if (hasReview != _hadReview) {
                    setState(() => _hadReview = hasReview);
                  }
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Visible on the Social feed', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _commentController,
                  builder: (context, value, _) =>
                      Text('${value.text.length}/150', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tipCard(String creator) {
    return Glass(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.coral,
                child: Text('👩‍🍳', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thank $creator!', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    const Text('Your tip supports creators', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final amt in [3, 5, 10])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _tipAmount = amt),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _tipAmount == amt ? AppColors.coral.withValues(alpha: 0.13) : Colors.white.withValues(alpha: 0.03),
                          border: Border.all(color: _tipAmount == amt ? AppColors.coral : Colors.white.withValues(alpha: 0.08), width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(amt == 3 ? '☕' : amt == 5 ? '🌶' : '🔥', style: const TextStyle(fontSize: 16)),
                            Text('\$$amt', style: TextStyle(color: _tipAmount == amt ? AppColors.coral : Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            Text('+${_tipPoints[amt]} pts', style: TextStyle(color: _tipAmount == amt ? AppColors.coral : AppColors.muted, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => ToastService.instance.show('💰 Custom tip amount...'),
                child: const Text('custom amount', style: TextStyle(color: AppColors.coral, fontSize: 13)),
              ),
              const Text('10× tip = bonus pts (cap 200)', style: TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Show tip on post', style: TextStyle(color: Colors.white, fontSize: 13)),
                      Text('Others see "tipped $creator \$$_tipAmount 🌶"', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ],
                  ),
                ),
                Switch(
                  value: _showTipOnPost,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.coral,
                  onChanged: (v) => setState(() => _showTipOnPost = v),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.read<FlowCubit>().setScreen(AppScreen.swipeDeck),
            child: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Skip', style: TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardsPath() {
    final steps = [
      ('Cook', true),
      ('Photo', _photoUploaded),
      ('Rate', _pepperRating != null),
      ('Review', _commentController.text.trim().isNotEmpty),
      ('Share', false),
    ];
    return Glass(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rewards Path', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('$_completedCount/5 Complete', style: const TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: steps[i].$2 ? AppColors.coral : Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: steps[i].$2 ? AppColors.coral : Colors.white.withValues(alpha: 0.15), width: 2),
                      ),
                      child: steps[i].$2
                          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                          : Text('${i + 1}', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                    ),
                    const SizedBox(height: 4),
                    Text(steps[i].$1, style: TextStyle(color: steps[i].$2 ? Colors.white : AppColors.muted, fontSize: 10)),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      color: steps[i].$2 ? AppColors.coral : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _shareButton(String dishTitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          final comment = _commentController.text.trim();
          final message = comment.isNotEmpty ? '📸 "$comment" — shared to feed!' : '📸 Shared to your feed!';
          var points = 25;
          if (_pepperRating != null) points += 15;
          if (comment.isNotEmpty) points += 10;
          if (_photoUploaded) points += 15;
          final appState = context.read<AppStateCubit>();
          appState.addXp(points);
          appState.setSharedPost(SharedPost(
            comment: comment.isNotEmpty ? comment : 'Just cooked this! 🔥',
            rating: _pepperRating ?? 0,
            photo: _photoUploaded ? 'uploaded' : null,
            name: dishTitle,
          ));
          appState.setTrendingMode(false);
          if (comment.isNotEmpty) BadgeService.instance.award(const ['first_share']);
          ToastService.instance.show(message);
          context.read<FlowCubit>().setScreen(AppScreen.socialFeed);
        },
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: const LinearGradient(colors: [AppColors.coral, AppColors.coralDark]),
            boxShadow: const [BoxShadow(color: Color(0x4DFF6B6B), blurRadius: 20)],
          ),
          alignment: Alignment.center,
          child: const Text('Share to Feed 🌶', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _outlineButton({required String icon, required String label, required VoidCallback onTap, Color? color}) {
    final c = color ?? Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: color == null ? Colors.white.withValues(alpha: 0.04) : color.withValues(alpha: 0.05),
          border: Border.all(color: color == null ? Colors.white.withValues(alpha: 0.12) : color.withValues(alpha: 0.13)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
