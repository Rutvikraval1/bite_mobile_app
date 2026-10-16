import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/social_proof_avatars.dart';
import '../../data/competition_repository.dart';

/// Competitions (Casual/Ranked/Elite tiers) and Cook-Offs — a bottom-sheet
/// styled screen. Ports `CompetitionScreen`. Tiers, competitions, entries
/// and cook-offs come from Supabase (`competition_board` /
/// `cook_off_board` RPCs); entering, accepting and voting are server-side.
class CompetitionScreen extends StatefulWidget {
  const CompetitionScreen({super.key});

  @override
  State<CompetitionScreen> createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen> {
  final _repo = CompetitionRepository();

  String? _tierId;
  String _mainTab = 'competitions';
  String _cookoffFilter = 'active';

  CompetitionBoard? _board;
  CookOffBoard? _cookOffs;
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_repo.fetchBoard(), _repo.fetchCookOffs()]);
      if (!mounted) return;
      setState(() {
        _board = results[0] as CompetitionBoard;
        _cookOffs = results[1] as CookOffBoard;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = CompetitionRepository.messageFor(e);
      });
    }
  }

  CompetitionTier? get _tier {
    final tiers = _board?.tiers ?? const <CompetitionTier>[];
    if (tiers.isEmpty) return null;
    return tiers.firstWhere((t) => t.id == _tierId, orElse: () => tiers.first);
  }

  Future<void> _run(String key, Future<void> Function() action) async {
    if (_busy.contains(key)) return;
    setState(() => _busy.add(key));
    try {
      await action();
    } catch (e) {
      if (mounted) context.showToast(CompetitionRepository.messageFor(e));
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  Future<void> _enter(Competition comp, CompetitionTier tier) async {
    if (comp.entered) {
      context.showToast("You're already in ${comp.title} — good luck, chef!");
      return;
    }
    final dish = await _pickDish(title: 'Enter ${comp.title}', subtitle: 'Pick the dish you cooked for this challenge');
    if (dish == null || !mounted) return;
    await _run('enter:${comp.id}', () async {
      final res = await _repo.enter(comp.id, dish.id);
      if (!mounted) return;
      if (res.newCoins != null) context.read<AppStateCubit>().setBiteCoins(res.newCoins!);
      context.showToast(res.alreadyEntered
          ? "You're already in ${comp.title}."
          : res.coinsPaid > 0
              ? "🔥 You're in! ${res.coinsPaid} Coins paid. Good luck, chef!"
              : "🔥 You're in! Entry submitted for ${comp.title}. Good luck, chef!");
      await _load();
    });
  }

  void _rateSubmissions(CompetitionTier tier) {
    if (tier.comps.isEmpty) {
      context.showToast('No live competitions in this tier right now.');
      return;
    }
    final comp = tier.comps.firstWhere((c) => c.entrants >= 2, orElse: () => tier.comps.first);
    CompetitionSelection.instance.current = (id: comp.id, title: comp.title, emoji: comp.emoji);
    context.read<FlowCubit>().setScreen(AppScreen.eloVoting);
  }

  Future<void> _startCookOff() async {
    final picked = await showModalBottomSheet<({CookedDish dish, String difficulty, String note})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DishPickerSheet(
        repo: _repo,
        title: '⚔️ Start a Cook-Off',
        subtitle: 'Post a dish you cooked — anyone can accept the challenge',
        withChallengeOptions: true,
      ),
    );
    if (picked == null || !mounted) return;
    await _run('start', () async {
      await _repo.startCookOff(dishId: picked.dish.id, difficulty: picked.difficulty, note: picked.note);
      if (!mounted) return;
      context.showToast('⚔️ Cook-Off posted! It shows under Open until someone accepts.');
      setState(() => _cookoffFilter = 'mine');
      await _load();
    });
  }

  Future<CookedDish?> _pickDish({required String title, required String subtitle}) async {
    final picked = await showModalBottomSheet<({CookedDish dish, String difficulty, String note})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _DishPickerSheet(repo: _repo, title: title, subtitle: subtitle),
    );
    return picked?.dish;
  }

  Future<void> _accept(CookOff co) => _run('accept:${co.id}', () async {
        await _repo.acceptCookOff(co.id);
        if (!mounted) return;
        context.showToast('⚔️ Accepted! Cook ${co.recipeTitle} within ${co.cookHours}h.');
        await _load();
      });

  Future<void> _vote(CookOff co) async {
    final side = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${co.emoji} ${co.recipeTitle}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Whose version wins?', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 16),
              for (final s in [('challenger', co.challenger), ('defender', co.defender)])
                if (s.$2 != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => Navigator.pop(ctx, s.$1),
                      tileColor: Colors.white.withValues(alpha: 0.03),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      leading: AvatarImg(emoji: s.$2!.avatarEmoji, imageUrl: s.$2!.avatarUrl, size: 36),
                      title: Text(s.$2!.handle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      trailing: Icon(Icons.how_to_vote_rounded, color: s.$1 == 'challenger' ? AppColors.coral : AppColors.cyan),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
    if (side == null || !mounted) return;
    await _run('vote:${co.id}', () async {
      await _repo.voteCookOff(co.id, side);
      if (!mounted) return;
      context.showToast('🗳 Vote counted!');
      await _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tier;
    final accent = tier?.color ?? AppColors.amber;
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
                  border: Border.all(color: accent.withValues(alpha: 0.13)),
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
                        child: RefreshIndicator(
                          color: accent,
                          onRefresh: _load,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
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
                              if (_loading && _board == null)
                                const Padding(
                                  padding: EdgeInsets.only(top: 80),
                                  child: Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)),
                                )
                              else if (_error != null && _board == null)
                                _EmptyState(emoji: '⚠️', title: "Couldn't load competitions", body: _error!, actionLabel: 'Retry', onAction: _load)
                              else if (_mainTab == 'competitions')
                                ..._competitionsTab(context, tier)
                              else
                                ..._cookoffsTab(context),
                            ],
                          ),
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

  List<Widget> _competitionsTab(BuildContext context, CompetitionTier? tier) {
    final tiers = _board?.tiers ?? const <CompetitionTier>[];
    if (tier == null) {
      return const [_EmptyState(emoji: '🏆', title: 'No competitions yet', body: 'New challenges will show up here.')];
    }
    final cooked = _board?.cookedCount ?? 0;
    return [
      Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            for (final t in tiers)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tierId = t.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: tier.id == t.id ? t.color : Colors.transparent, borderRadius: BorderRadius.circular(11)),
                    alignment: Alignment.center,
                    child: Text(t.label, style: TextStyle(color: tier.id == t.id ? Colors.white : AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
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
                      child: Text(
                        cooked >= tier.minCooks ? '✅ Unlocked — you have $cooked cooks' : '${tier.requirement!} · you have $cooked',
                        style: TextStyle(color: cooked >= tier.minCooks ? const Color(0xFF4CAF50) : AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: () => _rateSubmissions(tier),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Rate Submissions', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('Vote now · Earn 5 XP per rating', style: TextStyle(color: tier.color, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: tier.color),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (tier.comps.isEmpty)
        const _EmptyState(emoji: '⏳', title: 'Nothing live in this tier', body: 'Check back soon for the next challenge.'),
      for (var ci = 0; ci < tier.comps.length; ci++)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ZoomIn(
            duration: Duration(milliseconds: 300 + ci * 80),
            child: _CompetitionCard(
              comp: tier.comps[ci],
              tier: tier,
              busy: _busy.contains('enter:${tier.comps[ci].id}'),
              onEnter: () => _enter(tier.comps[ci], tier),
            ),
          ),
        ),
      GestureDetector(
        onTap: _startCookOff,
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
    final board = _cookOffs ?? const CookOffBoard(active: [], open: [], mine: []);
    final lists = {'active': board.active, 'open': board.open, 'mine': board.mine};
    final shown = lists[_cookoffFilter] ?? const <CookOff>[];
    return [
      Row(
        children: [
          for (final f in [('active', '🔥 Active'), ('open', '🤝 Open'), ('mine', '📋 Mine')])
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
                    child: Text('${f.$2} (${lists[f.$1]!.length})', textAlign: TextAlign.center, style: TextStyle(color: _cookoffFilter == f.$1 ? Colors.white : AppColors.muted, fontWeight: FontWeight.w700, fontSize: 11)),
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _busy.contains('start') ? null : _startCookOff,
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
                  Text('Post a dish you cooked — open for anyone', style: TextStyle(color: AppColors.muted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (shown.isEmpty)
        switch (_cookoffFilter) {
          'active' => const _EmptyState(emoji: '🔥', title: 'No active cook-offs', body: 'Accept an open challenge to start one.'),
          'open' => const _EmptyState(emoji: '🤝', title: 'No open challenges', body: 'Start a cook-off and be the first!'),
          _ => const _EmptyState(emoji: '⚔️', title: 'Your Cook-Off History', body: 'Start a cook-off or accept an open challenge to see your history here.'),
        },
      for (final co in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: co.status == 'open'
              ? _OpenCookOffCard(co: co, busy: _busy.contains('accept:${co.id}'), onAccept: () => _accept(co))
              : co.status == 'done' || co.status == 'expired'
                  ? _CookOffResult(co: co, myId: _repo.currentUserId)
                  : _CookOffCard(co: co, busy: _busy.contains('vote:${co.id}'), onVote: () => _vote(co)),
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
                    TextSpan(text: 'Fair play', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    TextSpan(text: ' — you can’t vote on your own cook-off, and each person gets one vote per matchup.'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.emoji, required this.title, required this.body, this.actionLabel, this.onAction});

  final String emoji;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(body, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5)),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!, style: const TextStyle(color: AppColors.amber))),
        ],
      ),
    );
  }
}

class _CompetitionCard extends StatelessWidget {
  const _CompetitionCard({required this.comp, required this.tier, required this.busy, required this.onEnter});

  final Competition comp;
  final CompetitionTier tier;
  final bool busy;
  final VoidCallback onEnter;

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
                Text('⏱ ${timeLeft(comp.endsAt)} remaining', style: const TextStyle(color: AppColors.amber, fontSize: 13, fontFamily: 'monospace')),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(comp.theme, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
                ),
                if (comp.prizes.isNotEmpty)
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
                                SizedBox(width: 32, child: Text(comp.prizes[i].place.split(' ')[0], style: const TextStyle(fontSize: 14, color: Colors.white))),
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
                    if (comp.avatarUrls.isNotEmpty) ...[
                      SocialProofAvatars(count: 3, urls: comp.avatarUrls),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      comp.entrants == 0 ? 'Be the first to enter' : '${comp.entrants} chef${comp.entrants == 1 ? '' : 's'} entered',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: busy ? null : onEnter,
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: comp.entered
                          ? null
                          : LinearGradient(colors: [tier.color, tier.id == 'casual' ? const Color(0xFF66BB6A) : tier.id == 'ranked' ? const Color(0xFFFFD54F) : AppColors.amber]),
                      color: comp.entered ? Colors.white.withValues(alpha: 0.06) : null,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: busy
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(comp.entered ? "✓ You're entered" : 'Enter Challenge ${comp.emoji}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Entry: ${tier.entryLabel(comp)}', style: TextStyle(color: AppColors.muted, fontSize: 11)),
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
  const _CookOffCard({required this.co, required this.busy, required this.onVote});

  final CookOff co;
  final bool busy;
  final VoidCallback onVote;

  @override
  Widget build(BuildContext context) {
    final voting = co.status == 'voting';
    final total = co.votesChallenger + co.votesDefender;
    final left = timeLeft(voting ? co.votingEndsAt : co.cookDeadline);
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
                    Text(co.recipeTitle, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        Text(voting ? '🗳 Voting' : '👨‍🍳 Cooking', style: TextStyle(color: voting ? AppColors.coral : AppColors.amber, fontSize: 10, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Text('$left left', style: TextStyle(color: AppColors.muted, fontSize: 10)),
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
              Expanded(child: _matchupSide(co.challenger, total > 0 ? co.votesChallenger / total : null, co.votesChallenger, AppColors.coral)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('VS', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w900, fontSize: 11))),
              Expanded(child: _matchupSide(co.defender, total > 0 ? co.votesDefender / total : null, co.votesDefender, AppColors.cyan)),
            ],
          ),
          if (voting && !co.mine && co.myVote == null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GestureDetector(
                onTap: busy ? null : onVote,
                child: Container(
                  width: double.infinity,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.coral, AppColors.amber]), borderRadius: BorderRadius.circular(100)),
                  child: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('🗳 Vote Now — Pick the Winner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            )
          else if (voting)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                co.mine ? 'Your cook-off — the community is voting' : '✓ You voted for ${co.myVote == 'challenger' ? co.challenger?.handle : co.defender.handle}',
                style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
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
                  Text('Both cooking — voting opens in $left', style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _matchupSide(CompUser? user, double? pct, int votes, Color barColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Row(
        children: [
          AvatarImg(emoji: user?.avatarEmoji ?? '❔', imageUrl: user?.avatarUrl, size: 24, borderWidth: 0),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.handle ?? 'Waiting…', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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

class _CookOffResult extends StatelessWidget {
  const _CookOffResult({required this.co, required this.myId});

  final CookOff co;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    final String title;
    final String sub;
    Color color = AppColors.muted;
    if (co.status == 'expired') {
      title = 'Expired: ${co.recipeTitle}';
      sub = 'Nobody accepted this challenge';
    } else {
      final opponent = co.defender.id == myId ? co.challenger : co.defender;
      final mineVotes = co.defender.id == myId ? co.votesDefender : co.votesChallenger;
      final theirVotes = co.defender.id == myId ? co.votesChallenger : co.votesDefender;
      final result = mineVotes > theirVotes ? 'Won' : mineVotes < theirVotes ? 'Lost' : 'Tied';
      color = result == 'Won' ? const Color(0xFF4CAF50) : result == 'Lost' ? AppColors.coral : AppColors.amber;
      title = '$result: ${co.recipeTitle} vs ${opponent?.handle ?? '—'}';
      sub = '$mineVotes votes to $theirVotes';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(
        children: [
          Text(co.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(sub, style: TextStyle(color: AppColors.muted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenCookOffCard extends StatelessWidget {
  const _OpenCookOffCard({required this.co, required this.busy, required this.onAccept});

  final CookOff co;
  final bool busy;
  final VoidCallback onAccept;

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
                    Text(co.recipeTitle, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        AvatarImg(emoji: co.defender.avatarEmoji, imageUrl: co.defender.avatarUrl, size: 16, borderWidth: 0),
                        const SizedBox(width: 6),
                        Flexible(child: Text(co.defender.handle, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.muted, fontSize: 11))),
                        Text(' · ', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                        Text('${co.cookHours}h', style: const TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w600)),
                        Text(' · ', style: TextStyle(color: AppColors.muted, fontSize: 9)),
                        Text(co.difficulty, style: TextStyle(color: AppColors.muted, fontSize: 10)),
                      ],
                    ),
                    if (co.note.isNotEmpty)
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
            child: co.mine
                ? Text('Your challenge · open for ${timeLeft(co.openUntil)}', style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600))
                : GestureDetector(
                    onTap: busy ? null : onAccept,
                    child: Container(
                      width: double.infinity,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _diffColor.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: _diffColor.withValues(alpha: 0.15)),
                      ),
                      child: busy
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _diffColor))
                          : Text('⚔️ Accept Challenge', style: TextStyle(color: _diffColor, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Picks a dish from the user's cook history; with [withChallengeOptions]
/// it also asks for difficulty and a short note (for a new cook-off).
class _DishPickerSheet extends StatefulWidget {
  const _DishPickerSheet({required this.repo, required this.title, required this.subtitle, this.withChallengeOptions = false});

  final CompetitionRepository repo;
  final String title;
  final String subtitle;
  final bool withChallengeOptions;

  @override
  State<_DishPickerSheet> createState() => _DishPickerSheetState();
}

class _DishPickerSheetState extends State<_DishPickerSheet> {
  late final Future<List<CookedDish>> _dishes = widget.repo.fetchCookedDishes();
  final _note = TextEditingController();
  CookedDish? _selected;
  String _difficulty = 'Medium';

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final dish = _selected;
    if (dish == null) return;
    Navigator.pop(context, (dish: dish, difficulty: _difficulty, note: _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(widget.subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 14),
                Flexible(
                  child: FutureBuilder<List<CookedDish>>(
                    future: _dishes,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2)));
                      }
                      final dishes = snap.data ?? const <CookedDish>[];
                      if (dishes.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            snap.hasError ? "Couldn't load your cooked dishes." : 'Cook a recipe first (Cook Mode → Finish) — your cooked dishes show up here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
                          ),
                        );
                      }
                      return ListView(
                        shrinkWrap: true,
                        children: [
                          for (final d in dishes)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: ListTile(
                                onTap: () => setState(() => _selected = d),
                                tileColor: _selected?.id == d.id ? AppColors.amber.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: _selected?.id == d.id ? AppColors.amber : Colors.transparent),
                                ),
                                leading: Text(d.emoji, style: const TextStyle(fontSize: 24)),
                                title: Text(d.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                trailing: _selected?.id == d.id ? const Icon(Icons.check_circle, color: AppColors.amber, size: 20) : null,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                if (widget.withChallengeOptions) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final d in const ['Easy', 'Medium', 'Hard'])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Center(child: Text(d)),
                              selected: _difficulty == d,
                              onSelected: (_) => setState(() => _difficulty = d),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _note,
                    maxLength: 140,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Trash talk (optional) — "Think you can beat it?"',
                      hintStyle: TextStyle(color: AppColors.muted, fontSize: 12),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _selected == null ? null : _submit,
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: _selected == null ? null : const LinearGradient(colors: [AppColors.coral, AppColors.amber]),
                      color: _selected == null ? Colors.white.withValues(alpha: 0.06) : null,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      widget.withChallengeOptions ? 'Post Cook-Off ⚔️' : 'Submit Entry',
                      style: TextStyle(color: _selected == null ? AppColors.muted : Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
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
