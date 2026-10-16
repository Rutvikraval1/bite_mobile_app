import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/impact_repository.dart';

/// "My Impact" — donation totals for the user's chosen charity plus the
/// community-wide leaderboard. Ports `CommunityImpactScreen`. Figures come
/// from the `community_impact` RPC (`donations` + `charities`).
class CommunityImpactScreen extends StatefulWidget {
  const CommunityImpactScreen({super.key});

  @override
  State<CommunityImpactScreen> createState() => _CommunityImpactScreenState();
}

class _CommunityImpactScreenState extends State<CommunityImpactScreen> {
  final _repo = ImpactRepository();
  String _activeTab = 'mine';
  CommunityImpact? _impact;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final impact = await _repo.fetchImpact();
      if (!mounted) return;
      setState(() {
        _impact = impact;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.read<FlowCubit>().goBack(),
                    child: const Icon(Icons.arrow_back, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text('💚 Community Impact', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    for (final t in ['mine', 'community'])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _activeTab = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _activeTab == t ? const Color(0xFF4CAF50) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              t == 'mine' ? 'My Impact' : 'Community',
                              style: TextStyle(color: _activeTab == t ? Colors.white : AppColors.muted, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _body(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final impact = _impact;
    if (_loading && impact == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50), strokeWidth: 2));
    }
    if (_failed || impact == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load impact data", style: TextStyle(color: AppColors.muted, fontSize: 13)),
            TextButton(onPressed: _load, child: const Text('Retry', style: TextStyle(color: Color(0xFF4CAF50)))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF4CAF50),
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        children: _activeTab == 'mine' ? _mineContent(context, impact.mine) : _communityContent(impact),
      ),
    );
  }

  Widget _changeCauseRow(BuildContext context, String label) {
    return GestureDetector(
      onTap: () => context.read<FlowCubit>().setScreen(AppScreen.premium),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.settings_outlined, size: 16, color: AppColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: TextStyle(color: AppColors.muted, fontSize: 13))),
            Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  List<Widget> _mineContent(BuildContext context, MyImpact? mine) {
    if (mine == null) {
      return [
        Glass(
          borderRadius: 20,
          borderColor: const Color(0x334CAF50),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text('💚', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text('No cause chosen yet', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Pick a charity when you go Premium and part of your subscription goes to it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _changeCauseRow(context, 'Choose a cause'),
      ];
    }
    final c = mine.charity;
    final units = c.unitsFor(mine.donatedCents);
    final monthUnits = c.unitsFor(mine.monthCents);
    return [
      Glass(
        borderRadius: 20,
        borderColor: const Color(0x334CAF50),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(c.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(c.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Your chosen cause', style: TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(formatCents(mine.donatedCents), style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('Donated', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
                Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 24), color: Colors.white.withValues(alpha: 0.06)),
                Column(
                  children: [
                    Text(formatCount(units), style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 24, fontWeight: FontWeight.w900)),
                    Text(_capitalize(c.impactLabel), style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Glass(
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🎉 Your Impact This Month', style: TextStyle(color: AppColors.amber, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (mine.monthCents == 0)
              Text(
                'No donations recorded this month yet. They appear here once your Premium payments go through.',
                style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.6),
              )
            else
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                  children: [
                    TextSpan(text: "You've given ${formatCents(mine.monthCents)} to ${c.name} this month — "),
                    TextSpan(text: '${formatCount(monthUnits)} ${c.impactLabel}', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
                    const TextSpan(text: '. Thank you for making a difference!'),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _changeCauseRow(context, 'Change my cause or upgrade plan'),
    ];
  }

  List<Widget> _communityContent(CommunityImpact impact) {
    final maxCents = impact.charities.fold<int>(0, (m, c) => c.totalCents > m ? c.totalCents : m);
    return [
      Glass(
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('b🌶te Community Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(formatCents(impact.totalCents), style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 32, fontWeight: FontWeight.w900)),
            ),
            Text('donated by ${formatCount(impact.donors)} premium member${impact.donors == 1 ? '' : 's'}', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      for (final c in impact.charities)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Glass(
            borderRadius: 14,
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                          Text(formatCents(c.totalCents), style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: impact.totalCents == 0 ? 0 : c.totalCents / (maxCents == 0 ? 1 : maxCents),
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${formatCount(c.unitsFor(c.totalCents))} ${c.impactLabel}', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
}
