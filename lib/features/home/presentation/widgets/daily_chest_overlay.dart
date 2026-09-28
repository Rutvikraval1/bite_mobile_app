import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';

/// Daily chest overlay — ports `showDailyChest` + `showChestRewards` from
/// `SwipeDeckScreen`.
class DailyChestOverlay extends StatefulWidget {
  const DailyChestOverlay({
    super.key,
    required this.isPremium,
    required this.onClaim,
    required this.onClose,
    required this.onUpgradePremium,
  });

  final bool isPremium;
  final void Function(ChestRewards rewards) onClaim;
  final VoidCallback onClose;
  final VoidCallback onUpgradePremium;

  @override
  State<DailyChestOverlay> createState() => _DailyChestOverlayState();
}

class _DailyChestOverlayState extends State<DailyChestOverlay> {
  ChestRewards? _rewards;

  void _openFree() {
    final coins = 5 + math.Random().nextInt(20);
    final xp = 1 + math.Random().nextInt(5);
    final rewards = ChestRewards(
      coins: coins,
      xp: xp,
      shard: 'Common Frame Shard',
      type: 'free',
    );
    widget.onClaim(rewards);
    setState(() => _rewards = rewards);
  }

  void _openPremium() {
    final coins = 25 + math.Random().nextInt(75);
    final xp = 5 + math.Random().nextInt(15);
    final rewards = ChestRewards(
      coins: coins,
      xp: xp,
      shard: 'Rare Galaxy Swirl Shard ✨',
      type: 'premium',
    );
    widget.onClaim(rewards);
    setState(() => _rewards = rewards);
  }

  @override
  Widget build(BuildContext context) {
    if (_rewards != null) return _rewardsView(_rewards!);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DAILY REWARD EARNED',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FreeChest(onOpen: _openFree),
                      const SizedBox(width: 16),
                      _SpicyChest(
                        isPremium: widget.isPremium,
                        onOpen: _openPremium,
                        onUpgrade: () {
                          widget.onClose();
                          widget.onUpgradePremium();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rewardsView(ChestRewards r) {
    final premium = r.type == 'premium';
    final rewardColor = premium
        ? const Color(0xFFFFD700)
        : const Color(0xFFFF6B6B);
    final items = [
      (icon: '🪙', label: '+${r.coins} Bite Coins', color: AppColors.amber),
      (icon: '⭐', label: '+${r.xp} Bonus XP', color: const Color(0xFF4CAF50)),
      (icon: '🔮', label: r.shard ?? '', color: AppColors.cyan),
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
                            Text(
                              items[i].label,
                              style: TextStyle(
                                color: items[i].color,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!premium && !widget.isPremium) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFD700),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x26FFD700)),
                    ),
                    child: Text(
                      '👀 Your Spicy Chest had ${r.coins} coins${r.shard != null ? ' + ${r.shard}' : ''} today',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 11,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    widget.onClaim(ChestRewards(coins: r.coins, xp: r.xp));
                    widget.onClose();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.coral, AppColors.amber],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'Collect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        width: 130,
        padding: const EdgeInsets.all(16),
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
  });

  final bool isPremium;
  final VoidCallback onOpen;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPremium ? onOpen : onUpgrade,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(16),
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
            colors: [Color(0xFF1A1A2E), Color(0xFF1A1A2E)],
          ),
        ),
        child: Column(
          children: [
            const Text('👑', style: TextStyle(fontSize: 48)),
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
