import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/mock_profile_data.dart';

const _dailyCap = 50;

/// Head-to-head Elo-ranked voting for a competition's submissions, plus a
/// live leaderboard. Ports `EloVotingScreen`. No voting table exists yet —
/// Elo scores are computed and held locally for the session.
class EloVotingScreen extends StatefulWidget {
  const EloVotingScreen({super.key});

  @override
  State<EloVotingScreen> createState() => _EloVotingScreenState();
}

class _EloVotingScreenState extends State<EloVotingScreen> {
  int _matchIndex = 0;
  String? _chosen; // "left" | "right"
  bool _transitioning = false;
  final Map<int, int> _scores = {};
  int _votesCount = 0;
  bool _showLeaderboard = false;
  String? _slideOut;

  // Built once instead of on every build/vote.
  late final List<List<EloEntry>> _matchups = _buildMatchups();

  List<List<EloEntry>> _buildMatchups() {
    final entries = EloVotingData.entries;
    final pairs = <List<EloEntry>>[];
    for (var i = 0; i + 1 < entries.length; i += 2) {
      pairs.add([entries[i], entries[i + 1]]);
    }
    return pairs;
  }

  void _handleVote(String side) {
    if (_transitioning) return;
    if (_votesCount >= _dailyCap) {
      context.showToast('🏆 Daily rating cap reached! Come back tomorrow for more points.');
      return;
    }
    final matchups = _matchups;
    if (matchups.isEmpty) return;
    final pair = matchups[_matchIndex % matchups.length];
    final left = pair[0];
    final right = pair[1];
    final winner = side == 'left' ? left : right;
    final loser = side == 'left' ? right : left;
    final loserSide = side == 'left' ? 'right' : 'left';
    final winnerElo = (_scores[winner.id] ?? winner.elo).toDouble();
    final loserElo = (_scores[loser.id] ?? loser.elo).toDouble();
    final eW = 1 / (1 + math.pow(10, (loserElo - winnerElo) / 400));
    final delta = (32 * (1 - eW)).round();

    setState(() {
      _chosen = side;
      _transitioning = true;
      _scores[winner.id] = (_scores[winner.id] ?? winner.elo) + delta;
      _scores[loser.id] = (_scores[loser.id] ?? loser.elo) - delta;
      _votesCount++;
      _slideOut = loserSide;
    });

    if (_votesCount % 5 == 0) {
      context.showToast('⭐ +25 pts earned! ($_votesCount/$_dailyCap daily ratings)');
    }

    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _chosen = null;
        _slideOut = null;
        _transitioning = false;
        _matchIndex++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchups = _matchups;
    if (matchups.isEmpty) return const Scaffold(backgroundColor: AppColors.bgDark);
    final pair = matchups[_matchIndex % matchups.length];

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
                        const Text('🌮 Taco Challenge', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: AppColors.muted, fontSize: 11),
                            children: const [
                              TextSpan(text: 'Pick the better taco · '),
                              TextSpan(text: '5 pts/vote', style: TextStyle(color: AppColors.amber)),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('MATCHUP #${_matchIndex + 1}', style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2)),
            ),
            Expanded(
              child: _showLeaderboard ? _buildLeaderboard() : _buildVoting(pair),
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
                    TextSpan(text: 'Tap the taco that looks better — your vote uses '),
                    TextSpan(text: 'Elo ranking', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '$_votesCount vote${_votesCount != 1 ? 's' : ''} cast · ${_matchups.length * 2} entries · ${_matchups.length} matchups per round',
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
    final leaderboard = [...EloVotingData.entries]..sort((a, b) => (_scores[b.id] ?? b.elo).compareTo(_scores[a.id] ?? a.elo));
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
            'Rankings update in real-time based on community votes using the Elo rating system — same method used in chess rankings.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
          ),
        ),
        for (var rank = 0; rank < leaderboard.length; rank++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LeaderboardRow(entry: leaderboard[rank], rank: rank, elo: _scores[leaderboard[rank].id] ?? leaderboard[rank].elo),
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
                        Text(entry.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.2)),
                        Text(entry.creator, style: TextStyle(color: AppColors.muted, fontSize: 11)),
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
                Text(entry.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(entry.creator, style: TextStyle(color: AppColors.muted, fontSize: 11)),
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
