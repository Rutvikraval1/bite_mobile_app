import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/competition_repository.dart';

/// Head-to-head Elo-ranked voting for a competition's submissions, plus a
/// live leaderboard. Ports `EloVotingScreen`. Entries come from
/// `competition_entries` (`elo_board` RPC); each vote goes through
/// `cast_elo_vote`, which updates both Elo scores, enforces the daily cap
/// and awards XP on the server.
class EloVotingScreen extends StatefulWidget {
  const EloVotingScreen({super.key});

  @override
  State<EloVotingScreen> createState() => _EloVotingScreenState();
}

class _EloVotingScreenState extends State<EloVotingScreen> {
  final _repo = CompetitionRepository();
  final _rng = math.Random();
  final _comp = CompetitionSelection.instance.current;

  int _matchIndex = 0;
  String? _chosen; // "left" | "right"
  bool _transitioning = false;
  bool _showLeaderboard = false;
  String? _slideOut;

  List<EloEntry> _entries = const [];
  int _votesCount = 0;
  int _dailyCap = 50;
  bool _loading = true;
  String? _error;
  List<EloEntry>? _pair;

  /// Entries the user can vote on (not their own).
  List<EloEntry> get _votable => _entries.where((e) => !e.mine).toList();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final comp = _comp;
    if (comp == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final board = await _repo.fetchEloBoard(comp.id);
      if (!mounted) return;
      setState(() {
        _entries = board.entries;
        _votesCount = board.votesToday;
        _dailyCap = board.dailyCap;
        _loading = false;
        _pair = _nextPair();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = CompetitionRepository.messageFor(e);
      });
    }
  }

  /// A random pair of two different votable entries, avoiding repeating
  /// the previous pair when possible.
  List<EloEntry>? _nextPair() {
    final pool = _votable;
    if (pool.length < 2) return null;
    final prev = _pair?.map((e) => e.id).toSet() ?? const <String>{};
    for (var attempt = 0; attempt < 6; attempt++) {
      final a = _rng.nextInt(pool.length);
      var b = _rng.nextInt(pool.length - 1);
      if (b >= a) b++;
      final pair = [pool[a], pool[b]];
      if (pool.length <= 2 || !(prev.contains(pair[0].id) && prev.contains(pair[1].id))) return pair;
    }
    return [pool[0], pool[1]];
  }

  void _setElo(String id, int elo) {
    _entries = [for (final e in _entries) e.id == id ? e.withElo(elo) : e];
  }

  Future<void> _handleVote(String side) async {
    final pair = _pair;
    if (_transitioning || pair == null) return;
    if (_votesCount >= _dailyCap) {
      context.showToast('🏆 Daily rating cap reached! Come back tomorrow for more points.');
      return;
    }
    final winner = side == 'left' ? pair[0] : pair[1];
    final loser = side == 'left' ? pair[1] : pair[0];
    final loserSide = side == 'left' ? 'right' : 'left';

    setState(() {
      _chosen = side;
      _transitioning = true;
      _slideOut = loserSide;
    });

    try {
      final res = await _repo.castEloVote(winnerId: winner.id, loserId: loser.id);
      if (!mounted) return;
      if (res.capped) {
        setState(() => _votesCount = res.votesToday);
        context.showToast('🏆 Daily rating cap reached! Come back tomorrow for more points.');
      } else {
        setState(() {
          if (res.winnerElo != null) _setElo(winner.id, res.winnerElo!);
          if (res.loserElo != null) _setElo(loser.id, res.loserElo!);
          _votesCount = res.votesToday;
        });
        if (res.newXp != null) context.read<AppStateCubit>().setXp(res.newXp!);
        if (_votesCount % 5 == 0) {
          context.showToast('⭐ +25 XP earned! ($_votesCount/$_dailyCap daily ratings)');
        }
      }
    } catch (e) {
      if (mounted) context.showToast(CompetitionRepository.messageFor(e));
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _chosen = null;
      _slideOut = null;
      _transitioning = false;
      _matchIndex++;
      _pair = _nextPair();
    });
  }

  @override
  Widget build(BuildContext context) {
    final comp = _comp;
    final pair = _pair;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.read<FlowCubit>().goBack(),
                    child: const Icon(Icons.arrow_back, size: 22, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          comp == null ? 'Rate Submissions' : '${comp.emoji} ${comp.title}',
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: AppColors.muted, fontSize: 11),
                            children: const [
                              TextSpan(text: 'Pick the better dish · '),
                              TextSpan(text: '5 XP/vote', style: TextStyle(color: AppColors.amber)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showLeaderboard = !_showLeaderboard),
                    child: Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.amber),
                        const SizedBox(width: 4),
                        Text('$_votesCount/$_dailyCap', style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_showLeaderboard && pair != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('MATCHUP #${_matchIndex + 1}', style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2)),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.amber, strokeWidth: 2))
                  : _error != null
                      ? _message('⚠️', "Couldn't load entries", _error!)
                      : comp == null
                          ? _message('🏆', 'No competition selected', 'Open a competition and tap Rate Submissions.')
                          : _showLeaderboard
                              ? _buildLeaderboard()
                              : pair == null
                                  ? _message(
                                      '🍽',
                                      'Not enough entries yet',
                                      _entries.isEmpty
                                          ? 'Nobody has entered this competition yet. Check back soon!'
                                          : 'There need to be at least two entries from other cooks to vote.',
                                      showLeaderboard: _entries.isNotEmpty,
                                    )
                                  : _buildVoting(pair),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String emoji, String title, String body, {bool showLeaderboard = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body, textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5)),
            if (showLeaderboard)
              TextButton(
                onPressed: () => setState(() => _showLeaderboard = true),
                child: const Text('🏆 View Leaderboard', style: TextStyle(color: AppColors.amber)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoting(List<EloEntry> pair) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Expanded(child: _CardSide(entry: pair[0], side: 'left', chosen: _chosen, slideOut: _slideOut, transitioning: _transitioning, onTap: () => _handleVote('left'))),
                Transform.translate(
                  offset: const Offset(0, 0),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.bgDark,
                      border: Border.all(color: AppColors.amber.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Pulse(
                      duration: Duration(milliseconds: 2500),
                      child: Text('VS', style: TextStyle(color: AppColors.amber, fontSize: 14, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
                Expanded(child: _CardSide(entry: pair[1], side: 'right', chosen: _chosen, slideOut: _slideOut, transitioning: _transitioning, onTap: () => _handleVote('right'))),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                  children: const [
                    TextSpan(text: 'Tap the dish that looks better — your vote uses '),
                    TextSpan(text: 'Elo ranking', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '$_votesCount vote${_votesCount != 1 ? 's' : ''} today · ${_entries.length} entries',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 11),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showLeaderboard = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.amber.withValues(alpha: 0.09), AppColors.coral.withValues(alpha: 0.03)]),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.amber.withValues(alpha: 0.27)),
                      ),
                      child: const Text('🏆 View Leaderboard', style: TextStyle(color: AppColors.amber, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.read<FlowCubit>().goBack(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                      child: Text('Done Voting', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboard() {
    final leaderboard = [..._entries]..sort((a, b) => b.elo.compareTo(a.elo));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('📊 Live Leaderboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            GestureDetector(
              onTap: () => setState(() => _showLeaderboard = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(100), border: Border.all(color: AppColors.amber.withValues(alpha: 0.13))),
                child: const Text('Back to Voting', style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            leaderboard.isEmpty
                ? 'No entries yet.'
                : 'Rankings update with every community vote using the Elo rating system — same method used in chess rankings.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
          ),
        ),
        for (var rank = 0; rank < leaderboard.length; rank++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LeaderboardRow(entry: leaderboard[rank], rank: rank, elo: leaderboard[rank].elo),
          ),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How Elo Ranking Works', style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Each entry starts at 1200 points. When you pick a winner, they gain points and the loser drops. '
                  'Beating a higher-ranked entry earns more points. After all community votes, the highest Elo score wins the competition.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.42), fontSize: 11, height: 1.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardSide extends StatelessWidget {
  const _CardSide({required this.entry, required this.side, required this.chosen, required this.slideOut, required this.transitioning, required this.onTap});

  final EloEntry entry;
  final String side;
  final String? chosen;
  final String? slideOut;
  final bool transitioning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isChosen = chosen == side;
    final isLoser = chosen != null && chosen != side;
    final isSliding = slideOut == side;

    double scale = 1;
    double opacity = 1;
    Offset offset = Offset.zero;
    if (isSliding) {
      offset = Offset(0, side == 'left' ? -1.2 : 1.2);
      scale = 0.8;
      opacity = 0;
    } else if (isChosen) {
      scale = 1.02;
    } else if (isLoser) {
      scale = 0.95;
      opacity = 0.4;
    }

    return GestureDetector(
      onTap: transitioning ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(offset.dx * 100, offset.dy * 100, 0)
          ..scaleByDouble(scale, scale, scale, 1),
        transformAlignment: Alignment.center,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: opacity,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isChosen ? AppColors.amber : Colors.white.withValues(alpha: 0.09), width: isChosen ? 3 : 1),
              boxShadow: isChosen ? [BoxShadow(color: AppColors.amber.withValues(alpha: 0.27), blurRadius: 30)] : null,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: entry.gradient),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: entry.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Center(child: Opacity(opacity: 0.4, child: Text(entry.emoji, style: const TextStyle(fontSize: 64)))),
                    ),
                  )
                else
                  Opacity(opacity: 0.4, child: Text(entry.emoji, style: const TextStyle(fontSize: 64))),
                if (isChosen)
                  PopIn(
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.amber.withValues(alpha: 0.87), boxShadow: [BoxShadow(color: AppColors.amber.withValues(alpha: 0.4), blurRadius: 24)]),
                      child: const Icon(Icons.emoji_events_rounded, size: 28, color: Colors.white),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 40, 10, 12),
                    decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xE6000000)])),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.2)),
                        Text(entry.creator.handle, style: TextStyle(color: AppColors.muted, fontSize: 11)),
                      ],
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

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry, required this.rank, required this.elo});

  final EloEntry entry;
  final int rank;
  final int elo;

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 0 ? AppColors.amber : rank == 1 ? const Color(0xFFC0C0C0) : rank == 2 ? const Color(0xFFCD7F32) : Colors.white.withValues(alpha: 0.08);
    return Glass(
      borderRadius: 14,
      borderColor: rank == 0 ? AppColors.amber.withValues(alpha: 0.27) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rank == 0 ? AppColors.amber.withValues(alpha: 0.13) : rank == 1 ? const Color(0x1FC0C0C0) : rank == 2 ? const Color(0x1FCD7F32) : Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: rankColor, width: 1.5),
            ),
            child: Text(
              rank == 0 ? '👑' : '${rank + 1}',
              style: TextStyle(color: rank <= 2 ? rankColor : AppColors.muted, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: LinearGradient(colors: entry.gradient)),
            child: Text(entry.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(entry.creator.handle, style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$elo', style: TextStyle(color: rank == 0 ? AppColors.amber : Colors.white, fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
              Text('ELO', style: TextStyle(color: AppColors.muted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
