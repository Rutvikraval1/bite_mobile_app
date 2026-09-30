import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/premium_gate_service.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../data/mock_profile_data.dart';

class _Tier {
  const _Tier({
    required this.id,
    required this.name,
    required this.priceAnnual,
    required this.priceMonthly,
    required this.badge,
    required this.color,
    required this.desc,
    required this.features,
    required this.locked,
    this.popular = false,
    this.annualNoteAnnual,
  });

  final String id;
  final String name;
  final String priceAnnual;
  final String priceMonthly;
  final String badge;
  final Color color;
  final String desc;
  final List<String> features;
  final List<String> locked;
  final bool popular;
  final String? annualNoteAnnual;
}

const _tiers = [
  _Tier(
    id: 'plus',
    name: 'Premium',
    priceAnnual: r'$7.99',
    priceMonthly: r'$9.99',
    badge: '🌶',
    color: AppColors.coral,
    desc: 'Unlock your full kitchen',
    annualNoteAnnual: r'Billed $95.88/yr (save $24)',
    features: [
      'Undo passed cards',
      'All filters + precision sliders',
      'Unlimited Smart Camera scans',
      "Add a Side (Creator's Picks)",
      'Unlimited Genie AI requests',
      'Custom collections',
      'Ad-free experience',
    ],
    locked: ['Full Meal Plan Builder', 'Cook Steps Timeline'],
  ),
  _Tier(
    id: 'pro',
    name: 'Premium Pro',
    priceAnnual: r'$13.99',
    priceMonthly: r'$17.99',
    badge: '🔥',
    color: AppColors.amber,
    desc: 'The complete meal experience',
    popular: true,
    annualNoteAnnual: r'Billed $167.88/yr (save $48)',
    features: [
      'Everything in Premium',
      'Full Meal Plan Builder',
      'Cook Steps Timeline (all meals)',
      'Add items from swipe deck to plans',
      'Smart ingredient consolidation',
      'Prep timeline optimization',
      'Priority support',
      'Donate to a cause 💚',
    ],
    locked: [],
  ),
];

/// The upgrade / manage-plan screen — ports `PremiumScreen`.
/// Unlike other gated features, this screen resolves the upsell itself:
/// subscribing here actually persists `is_premium` / `user_tier` to the
/// profile and re-hydrates the shared app state.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String? _selectedTier;
  bool _annual = true;
  int? _selectedCharity;
  bool _showCharity = false;
  bool _subscribing = false;

  String _tierName(String? id) {
    for (final t in _tiers) {
      if (t.id == id) return t.name;
    }
    return 'Premium';
  }

  Future<void> _confirmSubscribe() async {
    final tierId = _selectedTier;
    if (tierId == null) return;
    setState(() => _subscribing = true);

    final authCubit = context.read<AuthCubit>();
    final appState = context.read<AppStateCubit>();
    final flow = context.read<FlowCubit>();
    final userId = authCubit.state.user?.id;
    if (userId != null) {
      try {
        await authCubit.updateProfile({'is_premium': true, 'user_tier': tierId});
      } catch (_) {
        // A failed write is treated like a failure result: local state below
        // still applies, and the spinner must not get stuck on.
      }
    }
    PremiumGateService.instance.setPremiumState(premium: true, tier: tierId);

    appState.resetHydration();
    final profile = authCubit.state.profile;
    if (profile != null) appState.hydrateFromProfile(profile);

    if (!mounted) return;
    setState(() {
      _subscribing = false;
      _showCharity = false;
    });
    final tierName = _tierName(tierId);
    context.showToast("🎉 You're now a $tierName member!");
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) flow.goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = context.watch<AppStateCubit>().state.userTier;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.read<FlowCubit>().goBack(),
                        child: const Icon(Icons.arrow_back, size: 22, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          currentTier != 'free' ? 'Manage Plan' : 'Upgrade to Premium',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 22),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    children: [
                      Column(
                        children: [
                          const Text('🌶', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          const Text(
                            'Cook Smarter, Not Harder',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text('Unlock the full b🌶te experience', style: TextStyle(color: AppColors.muted, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Expanded(child: _BillingToggle(label: 'Annual', sub: 'Save 30%', active: _annual, onTap: () => setState(() => _annual = true))),
                            Expanded(child: _BillingToggle(label: 'Monthly', active: !_annual, onTap: () => setState(() => _annual = false))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final tier in _tiers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TierCard(
                            tier: tier,
                            annual: _annual,
                            selected: _selectedTier == tier.id,
                            isCurrent: currentTier == tier.id,
                            onTap: () => setState(() => _selectedTier = tier.id),
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          if (_selectedTier == null) {
                            context.showToast('Select a plan above');
                            return;
                          }
                          if (currentTier == _selectedTier) {
                            final name = _tierName(_selectedTier);
                            context.showToast("You're already on $name!");
                            return;
                          }
                          setState(() => _showCharity = true);
                        },
                        child: Container(
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            color: _selectedTier == null ? Colors.white.withValues(alpha: 0.06) : null,
                            gradient: _selectedTier != null && currentTier != _selectedTier
                                ? const LinearGradient(colors: [AppColors.coral, AppColors.amber])
                                : null,
                            boxShadow: _selectedTier != null && currentTier != _selectedTier
                                ? [BoxShadow(color: AppColors.coral.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 4))]
                                : null,
                          ),
                          child: Text(
                            _selectedTier == null
                                ? 'Select a plan'
                                : currentTier == _selectedTier
                                    ? 'Currently on ${_tierName(_selectedTier)} ✓'
                                    : 'Subscribe to ${_tierName(_selectedTier)}',
                            style: TextStyle(
                              color: _selectedTier == null
                                  ? AppColors.muted
                                  : currentTier == _selectedTier
                                      ? AppColors.cyan
                                      : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('🆓 Free Tier Includes:', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Text(
                              'Unlimited swipes · 5 favorites · 3 Genie requests/day · Basic filters · Social features · 5-day save expiry',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Cancel anytime · Restore purchase · Terms apply',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.15), fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showCharity)
              _CharitySheet(
                selectedCharity: _selectedCharity,
                subscribing: _subscribing,
                onSelect: (id) => setState(() => _selectedCharity = id),
                onConfirm: _confirmSubscribe,
                onSkip: _confirmSubscribe,
              ),
          ],
        ),
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.label, this.sub, required this.active, required this.onTap});

  final String label;
  final String? sub;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: active ? AppColors.coral : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        alignment: Alignment.center,
        child: RichText(
          text: TextSpan(
            style: TextStyle(color: active ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13),
            children: [
              TextSpan(text: label),
              if (sub != null) TextSpan(text: ' $sub', style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.annual,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  final _Tier tier;
  final bool annual;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? tier.color : Colors.white.withValues(alpha: 0.06), width: 2),
          boxShadow: selected ? [BoxShadow(color: tier.color.withValues(alpha: 0.13), blurRadius: 24)] : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18, (tier.popular && !isCurrent) || isCurrent ? 34 : 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tier.badge, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tier.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text(tier.desc, style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            annual ? tier.priceAnnual : tier.priceMonthly,
                            style: TextStyle(color: tier.color, fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          Text('/mo', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final f in tier.features)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 12, color: tier.color),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12))),
                        ],
                      ),
                    ),
                  for (final f in tier.locked)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.close, size: 12, color: Colors.white.withValues(alpha: 0.2)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(f, style: TextStyle(color: Colors.white.withValues(alpha: 0.42), fontSize: 12))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (tier.popular && !isCurrent)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(100)),
                  child: const Text('MOST POPULAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ),
            if (isCurrent)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.cyan, borderRadius: BorderRadius.circular(100)),
                  child: const Text('YOUR PLAN ✓', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CharitySheet extends StatelessWidget {
  const _CharitySheet({
    required this.selectedCharity,
    required this.subscribing,
    required this.onSelect,
    required this.onConfirm,
    required this.onSkip,
  });

  final int? selectedCharity;
  final bool subscribing;
  final ValueChanged<int> onSelect;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PopIn(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💚', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    const Text('Choose a Cause', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      'A portion of your premium goes to a charity you choose',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    for (final c in MockProfileData.charities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () => onSelect(c.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedCharity == c.id
                                  ? (c.id == 0 ? Colors.white.withValues(alpha: 0.04) : const Color(0x144CAF50))
                                  : Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selectedCharity == c.id
                                    ? (c.id == 0 ? AppColors.muted : const Color(0xFF4CAF50))
                                    : Colors.white.withValues(alpha: 0.05),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(c.emoji, style: const TextStyle(fontSize: 22)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(c.desc, style: TextStyle(color: AppColors.muted, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                if (selectedCharity == c.id)
                                  Icon(Icons.check, size: 16, color: c.id == 0 ? AppColors.muted : const Color(0xFF4CAF50)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: subscribing ? null : onConfirm,
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          gradient: const LinearGradient(colors: [AppColors.coral, AppColors.amber]),
                        ),
                        child: subscribing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Confirm & Subscribe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                    GestureDetector(
                      onTap: subscribing ? null : onSkip,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Skip & Subscribe', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
