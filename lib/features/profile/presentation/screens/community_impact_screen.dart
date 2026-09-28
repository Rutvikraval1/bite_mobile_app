import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/mock_profile_data.dart';

/// "My Impact" — donation totals for the user's chosen charity plus the
/// community-wide leaderboard. Ports `CommunityImpactScreen`. No backend
/// table exists for donations yet, so figures are illustrative/local.
class CommunityImpactScreen extends StatefulWidget {
  const CommunityImpactScreen({super.key});

  @override
  State<CommunityImpactScreen> createState() => _CommunityImpactScreenState();
}

class _CommunityImpactScreenState extends State<CommunityImpactScreen> {
  String _activeTab = 'mine';

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                children: _activeTab == 'mine' ? _mineContent(context) : _communityContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _mineContent(BuildContext context) {
    final c = MockProfileData.myCharity;
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
                    Text(c.donated, style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('Donated', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
                Container(width: 1, height: 36, margin: const EdgeInsets.symmetric(horizontal: 24), color: Colors.white.withValues(alpha: 0.06)),
                Column(
                  children: [
                    Text('${c.meals}', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 24, fontWeight: FontWeight.w900)),
                    Text('Meals Served', style: TextStyle(color: AppColors.muted, fontSize: 11)),
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
            RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                children: [
                  TextSpan(text: "You've helped feed "),
                  TextSpan(text: '24 veterans', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
                  TextSpan(text: ' this month through your b🌶te PRO subscription. Thank you for making a difference!'),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
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
              Expanded(child: Text('Change my cause or upgrade plan', style: TextStyle(color: AppColors.muted, fontSize: 13))),
              Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.muted),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _communityContent() {
    return [
      Glass(
        borderRadius: 20,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('b🌶te Community Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(r'$174,230', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 32, fontWeight: FontWeight.w900)),
            ),
            Text('donated by 23,400 premium members', style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      for (final c in MockProfileData.communityStats)
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
                          Text(c.total, style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: c.pct / 100,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.06),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(c.impact, style: TextStyle(color: AppColors.muted, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}
