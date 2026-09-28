import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/social_proof_avatars.dart';
import '../../data/mock_profile_data.dart';

const _socialProofUrls = [
  'https://images.pexels.com/photos/34238049/pexels-photo-34238049.jpeg?auto=compress&cs=tinysrgb&w=80',
  'https://images.pexels.com/photos/1820559/pexels-photo-1820559.jpeg?auto=compress&cs=tinysrgb&w=80',
  'https://images.pexels.com/photos/38366748/pexels-photo-38366748.jpeg?auto=compress&cs=tinysrgb&w=80',
];

/// Competitions (Casual/Ranked/Elite tiers) and Cook-Offs — a bottom-sheet
/// styled screen. Ports `CompetitionScreen`. No `competitions` table exists,
/// so this renders faithfully against local mock data; entering/joining
/// mutates nothing server-side (toast only), matching the prototype.
class CompetitionScreen extends StatefulWidget {
  const CompetitionScreen({super.key});

  @override
  State<CompetitionScreen> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen> {
  String _tierId = 'casual';
  String _mainTab = 'competitions';
  String _cookoffFilter = 'active';

  CompetitionTier get _tier => CompetitionData.tiers.firstWhere((t) => t.id == _tierId);

  @override
  Widget build(BuildContext context) {
    final tier = _tier;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => context.read<FlowCubit>().goBack(),
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: FractionallySizedBox(
              heightFactor: 0.86,
              widthFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: tier.color.withValues(alpha: 0.13)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => context.read<FlowCubit>().goBack(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(4))),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14)),
                              child: Row(
                                children: [
                                  for (final t in [('competitions', '🏆 Competitions'), ('cookoffs', '🔥 Cook-Offs')])
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => _mainTab = t.$1),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 250),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: _mainTab == t.$1
                                                ? LinearGradient(colors: [t.$1 == 'cookoffs' ? AppColors.coral : AppColors.amber, t.$1 == 'cookoffs' ? AppColors.amber : AppColors.coral])
                                                : null,
                                            borderRadius: BorderRadius.circular(11),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(t.$2, style: TextStyle(color: _mainTab == t.$1 ? Colors.white : AppColors.muted, fontWeight: FontWeight.w700, fontSize: 13)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_mainTab == 'competitions') ..._competitionsTab(context, tier) else ..._cookoffsTab(context),
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
      ),
    );
  }

  List<Widget> _competitionsTab(BuildContext context, CompetitionTier tier) {
    return [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            for (final t in CompetitionData.tiers)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tierId = t.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: _tierId == t.id ? t.color : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: Text(t.label, style: TextStyle(color: _tierId == t.id ? Colors.white : AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tier.color.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tier.color.withValues(alpha: 0.09)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tier.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tier.desc, style: TextStyle(color: tier.color, fontSize: 12, fontWeight: FontWeight.w600)),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(tier.info, style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4)),
                  ),
                  if (tier.requirement != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(tier.requirement!, style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () => context.read<FlowCubit>().setScreen(AppScreen.eloVoting),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [tier.color.withValues(alpha: 0.13), tier.color.withValues(alpha: 0.03)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tier.color.withValues(alpha: 0.33), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tier.color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.emoji_events_rounded, size: 18, color: tier.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rate Submissions', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('Vote now · Earn 5 pts per rating', style: TextStyle(color: tier.color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: tier.color),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      for (var ci = 0; ci < tier.comps.length; ci++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ZoomIn(
            duration: Duration(milliseconds: 300 + ci * 80),
            child: _CompetitionCard(comp: tier.comps[ci], tier: tier),
          ),
        ),
      GestureDetector(
        onTap: () => context.showToast('🏆 Challenge link copied — send it to a friend!'),
        child: Container(
          height: 44,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_alt_rounded, size: 14, color: Colors.white),
              SizedBox(width: 8),
              Text('Challenge a Friend', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _cookoffsTab(BuildContext context) {
    return [
      Row(
        children: [
          for (final f in const [('active', '🔥 Active', 3), ('open', '🤝 Open', 5), ('mine', '📋 My Cook-Offs', 1)])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _cookoffFilter = f.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(color: _cookoffFilter == f.$1 ? AppColors.coral : Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(100)),
                    alignment: Alignment.center,
                    child: Text('${f.$2} (${f.$3})', textAlign: TextAlign.center, style: TextStyle(color: _cookoffFilter == f.$1 ? Colors.white : AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () => context.showToast('🔥 Pick a recipe from your cooked history to start a Cook-Off!'),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppColors.coral.withValues(alpha: 0.09), AppColors.amber.withValues(alpha: 0.03)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.coral.withValues(alpha: 0.27)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('⚔️', style: TextStyle(fontSize: 20)),
              SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start a Cook-Off', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('Challenge a friend or go open for anyone', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (_cookoffFilter == 'active')
        for (final co in CompetitionData.activeCookOffs)
          Padding(padding: const EdgeInsets.only(bottom: 10), child: _CookOffCard(co: co)),
      if (_cookoffFilter == 'open')
        for (final co in CompetitionData.openCookOffs)
          Padding(padding: const EdgeInsets.only(bottom: 8), child: _OpenCookOffCard(co: co)),
      if (_cookoffFilter == 'mine')
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Text('⚔️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('Your Cook-Off History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Start a cook-off or accept an open challenge to see your history here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5)),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0x0F4CAF50), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x264CAF50))),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Won: Gochujang Chicken vs @chefpriya', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 13, fontWeight: FontWeight.w700)),
                          Text('75 votes to 41 · 3 days ago · +50 XP earned', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('📸', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: AppColors.muted, fontSize: 10, height: 1.4),
                  children: const [
                    TextSpan(text: 'Verified Photos Only', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    TextSpan(text: ' — AI-generated or filtered photos are auto-detected. 1st offense: warning + disqualified. 2nd: permanent competition ban.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}

class _CompetitionCard extends StatelessWidget {
  const _CompetitionCard({required this.comp, required this.tier});

  final Competition comp;
  final CompetitionTier tier;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 20,
      borderColor: tier.color.withValues(alpha: 0.13),
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (comp.sponsor != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0x0D4CAF50)),
              alignment: Alignment.center,
              child: Text(comp.sponsor!, style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(comp.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 6),
                Text(comp.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                Text('⏱ ${comp.time} remaining', style: const TextStyle(color: AppColors.amber, fontSize: 13, fontFamily: 'monospace')),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(comp.theme, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      for (var i = 0; i < comp.prizes.length; i++)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            border: i < comp.prizes.length - 1 ? Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))) : null,
                          ),
                          child: Row(
                            children: [
                              SizedBox(width: 24, child: Text(comp.prizes[i].place.split(' ')[0], style: const TextStyle(fontSize: 14))),
                              Expanded(child: Text(comp.prizes[i].prize, style: const TextStyle(color: Colors.white, fontSize: 12))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialProofAvatars(count: 3, urls: _socialProofUrls),
                    const SizedBox(width: 6),
                    Text('${comp.entrants} chefs entered', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.showToast("🔥 You're in! Entry submitted for ${comp.title}. Good luck, chef!"),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [tier.color, tier.id == 'casual' ? const Color(0xFF66BB6A) : tier.id == 'ranked' ? const Color(0xFFFFD54F) : AppColors.amber]),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('Enter Challenge ${comp.emoji}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Entry: ${comp.entry}', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CookOffCard extends StatelessWidget {
  const _CookOffCard({required this.co});

  final ({String recipe, String emoji, String challenger, String challengerAvatar, String defender, String defenderAvatar, String timeLeft, int votesLeft, int votesRight, String status, bool verified}) co;

  @override
  Widget build(BuildContext context) {
    final voting = co.status == 'voting';
    final total = co.votesLeft + co.votesRight;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(co.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(co.recipe, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Text(voting ? '🗳 Voting' : '👨‍🍳 Cooking', style: TextStyle(color: voting ? AppColors.coral : AppColors.amber, fontSize: 10, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Text(co.timeLeft, style: TextStyle(color: AppColors.muted, fontSize: 10)),
                        if (co.verified) ...[
                          const SizedBox(width: 6),
                          const Text('📸 Verified', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 9)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _matchupSide(co.challengerAvatar, co.challenger, total > 0 ? co.votesLeft / total : null, co.votesLeft, AppColors.coral)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('VS', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 11))),
              Expanded(child: _matchupSide(co.defenderAvatar, co.defender, total > 0 ? co.votesRight / total : null, co.votesRight, AppColors.cyan)),
            ],
          ),
          if (voting)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GestureDetector(
                onTap: () => context.showToast('🗳 Opening vote view — swipe down the dish you like less!'),
                child: Container(
                  width: double.infinity,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.coral, AppColors.amber]), borderRadius: BorderRadius.circular(100)),
                  child: const Text('🗳 Vote Now — Swipe to Pick Winner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.amber.withValues(alpha: 0.13))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 12, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Text('Both cooking — photos due in ${co.timeLeft}', style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _matchupSide(String avatar, String name, double? pct, int votes, Color barColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Row(
        children: [
          Text(avatar, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                if (pct != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(value: pct, minHeight: 3, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation(barColor)),
                    ),
                  ),
              ],
            ),
          ),
          if (pct != null) Text('$votes', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _OpenCookOffCard extends StatelessWidget {
  const _OpenCookOffCard({required this.co});

  final ({String recipe, String emoji, String poster, String posterAvatar, String deadline, String difficulty, String note}) co;

  Color get _diffColor => switch (co.difficulty) {
        'Easy' => const Color(0xFF4CAF50),
        'Hard' => AppColors.coral,
        _ => AppColors.amber,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(co.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(co.recipe, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Text(co.posterAvatar, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(co.poster, style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        Text(' · ', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                        Text(co.deadline, style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w600)),
                        Text(' · ', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                        Text(co.difficulty, style: TextStyle(color: AppColors.muted, fontSize: 10)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('"${co.note}"', style: TextStyle(color: Colors.white.withValues(alpha: 0.42), fontSize: 10, fontStyle: FontStyle.italic)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: GestureDetector(
              onTap: () => context.showToast('⚔️ Accepted! Cook ${co.recipe} within ${co.deadline} and submit your photo.'),
              child: Container(
                width: double.infinity,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _diffColor.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _diffColor.withValues(alpha: 0.15)),
                ),
                child: Text('⚔️ Accept Challenge', style: TextStyle(color: _diffColor, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
