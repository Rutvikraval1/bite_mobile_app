import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../data/daily_chest_service.dart';

/// Daily chest overlay. Opening a chest calls the `claim_daily_chest` RPC,
/// which rolls and grants the rewards on the server (once per local day);
/// [onClaimed] then mirrors them into local state. If today's chest is
/// already open it shows a countdown to the next one.
class DailyChestOverlay extends StatefulWidget {
  const DailyChestOverlay({
    super.key,
    required this.isPremium,
    required this.signedIn,
    required this.onClaimed,
    required this.onClose,
    required this.onUpgradePremium,
    required this.onSignIn,
  });

  final bool isPremium;
  final bool signedIn;
  final void Function(DailyChestClaim claim) onClaimed;
  final VoidCallback onClose;
  final VoidCallback onUpgradePremium;
  final VoidCallback onSignIn;

  @override
  State<DailyChestOverlay> createState() => _DailyChestOverlayState();
}

class _DailyChestOverlayState extends State<DailyChestOverlay> {
  final _chest = DailyChestService.instance;
  DailyChestClaim? _rewards;
  bool _opening = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.signedIn) _chest.refresh();
    // Keeps the "next chest in" countdown live.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final s = _chest.status.value;
      if (s != null && s.claimedToday && DateTime.now().isAfter(s.nextAt)) {
        _chest.refresh();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _open({required bool premium}) async {
    if (_opening) return;
    if (!widget.signedIn) {
      widget.onClose();
      widget.onSignIn();
      return;
    }
    setState(() => _opening = true);
    try {
      final result = await _chest.claim(premium: premium);
      if (!mounted) return;
      if (result.alreadyClaimed) {
        setState(() => _opening = false);
        ToastService.instance.show("📦 You've already opened today's chest");
        return;
      }
      widget.onClaimed(result);
      setState(() {
        _opening = false;
        _rewards = result;
      });
    } catch (e) {
      debugPrint('[chest] claim failed: $e');
      if (!mounted) return;
      setState(() => _opening = false);
      final premiumRequired =
          e is PostgrestException && e.message.contains('premium_required');
      ToastService.instance.show(
        premiumRequired
            ? '👑 The Spicy Chest needs an active Premium plan.'
            : DailyChestService.isNotSetUp(e)
            ? '⚠️ Daily chest is not set up on the server yet.'
            : "⚠️ Couldn't open the chest. Check your connection and try again.",
      );
    }
  }

  static String _countdown(DateTime at) {
    final d = at.difference(DateTime.now());
    if (d.isNegative) return 'now';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final rewards = _rewards;
    if (rewards != null) return _rewardsView(rewards);
    return ValueListenableBuilder<DailyChestStatus?>(
      valueListenable: _chest.status,
      builder: (context, status, _) {
        final claimed = status?.claimedToday ?? false;
        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.55),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: PopIn(
                  child: claimed && status != null
                      ? _cooldownView(status)
                      : _chooseView(status),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _chooseView(DailyChestStatus? status) {
    final streak = status?.chestStreak ?? 0;
    // Claiming today continues the streak (or starts it at 1).
    final nextStreak = streak + 1;
    final bonusPct = ((nextStreak - 1).clamp(0, 6)) * 10;
    final premium = widget.isPremium;

    return Container(
      width: MediaQuery.sizeOf(context).width - 40,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            (premium ? const Color(0xFFFFD700) : AppColors.coral)
                .withValues(alpha: 0.12),
            AppColors.bgDark.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: (premium ? const Color(0xFFFFD700) : AppColors.coral)
              .withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: (premium ? const Color(0xFFFFD700) : AppColors.coral)
                .withValues(alpha: 0.18),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──
          const Text('🎁', style: TextStyle(fontSize: 34)),
          const SizedBox(height: 6),
          const Text(
            'Daily Reward Earned',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            premium
                ? 'Your Premium Spicy Chest is ready'
                : 'Pick a chest — one per day',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // ── Chest streak: 7 days, bonus grows +10% a day ──
          _StreakStrip(day: nextStreak, bonusPct: bonusPct),
          const SizedBox(height: 16),

          // ── Chests ──
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _opening ? 0.35 : 1,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Premium members get the Spicy Chest only — no
                      // upgrade prompt once they've upgraded.
                      if (!premium) ...[
                        Expanded(
                          child: _FreeChest(
                            onOpen: () => _open(premium: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: _SpicyChest(
                          isPremium: premium,
                          wide: premium,
                          onOpen: () => _open(premium: true),
                          onUpgrade:
                              _opening ? () {} : widget.onUpgradePremium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_opening)
                const CircularProgressIndicator(
                  color: AppColors.amber,
                  strokeWidth: 2,
                ),
            ],
          ),

          // ── Footer ──
          const SizedBox(height: 14),
          Text(
            !widget.signedIn
                ? '🔐 Sign in to open your daily chest'
                : premium
                ? '👑 Premium member · rare shard included'
                : '⏰ Resets at midnight · come back tomorrow',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: premium ? const Color(0xFFFFD700) : AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cooldownView(DailyChestStatus status) {
    return Container(
      width: MediaQuery.sizeOf(context).width - 48,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📦', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 10),
          const Text(
            "Today's chest is open",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Next chest in ${_countdown(status.nextAt)}',
            style: const TextStyle(
              color: AppColors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (status.chestStreak > 0) ...[
            const SizedBox(height: 8),
            Text(
              '🔥 ${status.chestStreak}-day chest streak — come back tomorrow to keep it',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
            ),
          ],
          const SizedBox(height: 18),
          _collectButton('Got it', widget.onClose),
        ],
      ),
    );
  }

  Widget _collectButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.coral, AppColors.amber],
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _rewardsView(DailyChestClaim r) {
    final premium = r.premium;
    final rewardColor = premium
        ? const Color(0xFFFFD700)
        : const Color(0xFFFF6B6B);
    final items = [
      (
        icon: '🪙',
        label: r.streakBonus > 0
            ? '+${r.coins} Bite Coins (incl. +${r.streakBonus} streak bonus)'
            : '+${r.coins} Bite Coins',
        color: AppColors.amber,
      ),
      (icon: '⭐', label: '+${r.xp} Bonus XP', color: const Color(0xFF4CAF50)),
      if (r.shard != null && r.shard!.isNotEmpty)
        (icon: '🔮', label: r.shard!, color: AppColors.cyan),
    ];

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: PopIn(
          child: Container(
            width: MediaQuery.sizeOf(context).width - 48,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.bgDark.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: premium
                    ? const Color(0x33FFD700)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(premium ? '👑' : '📦',
                    style: const TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(
                  premium ? 'Spicy Chest!' : 'Daily Chest!',
                  style: TextStyle(
                    color: rewardColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (r.chestStreak > 1) ...[
                  const SizedBox(height: 4),
                  Text(
                    '🔥 ${r.chestStreak}-day chest streak',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: ZoomIn(
                      duration: Duration(milliseconds: 300 + i * 150),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: items[i].color.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: items[i].color.withValues(alpha: 0.13)),
                        ),
                        child: Row(
                          children: [
                            Text(items[i].icon,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                items[i].label,
                                style: TextStyle(
                                  color: items[i].color,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!premium && !widget.isPremium) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: widget.onUpgradePremium,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x0FFFD700),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x26FFD700)),
                      ),
                      child: const Text(
                        '👑 Upgrade → Spicy Chest every day: 25–100 coins + a rare shard',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Next chest in ${_countdown(r.nextAt)}',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                const SizedBox(height: 10),
                // Rewards are already granted; Collect just closes.
                _collectButton('Collect', widget.onClose),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 7-day chest streak strip: filled dots up to today, bonus % on the right.
class _StreakStrip extends StatelessWidget {
  const _StreakStrip({required this.day, required this.bonusPct});

  /// Streak day today's claim would make (1 = fresh start).
  final int day;
  final int bonusPct;

  @override
  Widget build(BuildContext context) {
    final lit = day.clamp(1, 7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Text(
            'Day $day',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                for (var i = 1; i <= 7; i++) ...[
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: i <= lit
                            ? const LinearGradient(
                                colors: [AppColors.coral, AppColors.amber],
                              )
                            : null,
                        color: i <= lit
                            ? null
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  if (i < 7) const SizedBox(width: 3),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Flexible so narrow phones shrink the label, not overflow.
          Flexible(
            child: Text(
              bonusPct > 0 ? '+$bonusPct% 🪙' : '+10%/day',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.amber,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FreeChest extends StatelessWidget {
  const _FreeChest({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            const Pulse(
              amount: 0.05,
              duration: Duration(seconds: 2),
              child: Text('📦', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Daily Chest',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '5–25 coins + XP',
              style: TextStyle(color: AppColors.muted, fontSize: 10),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.coral, AppColors.amber],
                ),
                borderRadius: BorderRadius.all(Radius.circular(100)),
              ),
              child: const Text(
                'Open',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpicyChest extends StatelessWidget {
  const _SpicyChest({
    required this.isPremium,
    required this.onOpen,
    required this.onUpgrade,
    this.wide = false,
  });

  final bool isPremium;

  /// Shown alone (premium members) — larger chest emoji.
  final bool wide;
  final VoidCallback onOpen;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPremium ? onOpen : onUpgrade,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFD700),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26FFD700),
              blurRadius: 24,
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A2440), Color(0xFF1A1A2E)],
          ),
        ),
        child: Column(
          children: [
            Pulse(
              amount: isPremium ? 0.05 : 0.0,
              duration: const Duration(seconds: 2),
              child: Text('👑', style: TextStyle(fontSize: wide ? 56 : 48)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Spicy Chest',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '25–100 coins + rare',
              style: TextStyle(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 10),
            if (isPremium)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'Open',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x14FFD700),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: const Color(0x66FFD700)),
                ),
                child: const Text(
                  'Upgrade →',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
