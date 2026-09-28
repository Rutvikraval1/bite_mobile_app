import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/state/app_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/bite_scale.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../content/domain/entities/bite_card.dart';

/// Full-bleed current card — ports the current-card block from
/// `SwipeDeckScreen` in `screens-deck.jsx`.
class DeckCard extends StatefulWidget {
  const DeckCard({
    super.key,
    required this.card,
    required this.subTab,
    required this.accentColor,
    required this.scale,
    required this.infoExpanded,
    required this.onToggleInfo,
    required this.onTap,
    required this.onCreatorTap,
    required this.onOrderTap,
    required this.onMealTap,
    required this.onFavoriteTap,
    required this.onCallTap,
    required this.onDirectionsTap,
    required this.onReserveTap,
    required this.onTagTap,
    this.inMealItems = false,
    this.mealItemCount = 0,
  });

  final BiteCard card;
  final DeckTab subTab;
  final Color accentColor;
  final BiteScale scale;
  final bool infoExpanded;
  final VoidCallback onToggleInfo;
  final VoidCallback onTap;
  final VoidCallback onCreatorTap;
  final VoidCallback onOrderTap;
  final VoidCallback onMealTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onCallTap;
  final VoidCallback onDirectionsTap;
  final VoidCallback onReserveTap;
  final ValueChanged<String> onTagTap;
  final bool inMealItems;
  final int mealItemCount;

  @override
  State<DeckCard> createState() => _DeckCardState();
}

class _DeckCardState extends State<DeckCard> {
  bool _followed = false;
  bool _showTags = false;

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final c = widget.scale;
    final tiny = widget.scale.isTiny || c.isXS;
    final compact = c.isCompact || c.isS;
    final mainEmoji = card.emoji.isEmpty
        ? switch (widget.subTab) {
            DeckTab.food => '🍽',
            DeckTab.drinks => '🍸',
            DeckTab.places => '📍',
          }
        : card.emoji;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: EmojiThemes.cardBg(card.emoji),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (card.image != null && card.image!.isNotEmpty)
            _HeroPhoto(url: card.image!),
          // Darken overlay for text contrast
          ColoredBox(
            color: Colors.black.withValues(
              alpha: card.image != null ? 0.35 : 0.25,
            ),
          ),
          // Cinematic vignette
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  stops: const [0.3, 0.8, 1],
                ),
              ),
            ),
          ),
          // Diagonal light streak
          const IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: _DiagonalStreak(),
            ),
          ),
          // Ambient edge glows
          _EdgeGlows(color: widget.accentColor),
          // Emoji hero spread
          if (card.image == null || card.image!.isEmpty)
            _HeroSpread(
              emoji: mainEmoji,
              accent: widget.accentColor,
              tiny: tiny,
              compact: compact,
            ),
          // Parallax ingredient layers
          _ParallaxLayer(emoji: card.emoji, scale: widget.scale),
          // Companion emojis
          if (!c.isXS && !tiny) _Companions(card: card, compact: compact),
          // Swipe direction hints
          if (!c.isXS && !c.isS)
            const IgnorePointer(child: _SwipeHints()),
          // Bottom content
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomContent(
              card: card,
              subTab: widget.subTab,
              accent: widget.accentColor,
              scale: widget.scale,
              infoExpanded: widget.infoExpanded,
              onToggleInfo: widget.onToggleInfo,
              onTap: widget.onTap,
              onCreatorTap: widget.onCreatorTap,
              followed: _followed,
              onFollowToggle: () => setState(() => _followed = !_followed),
              onOrderTap: widget.onOrderTap,
              onMealTap: widget.onMealTap,
              onFavoriteTap: widget.onFavoriteTap,
              onCallTap: widget.onCallTap,
              onDirectionsTap: widget.onDirectionsTap,
              onReserveTap: widget.onReserveTap,
              showTags: _showTags,
              onToggleTags: () => setState(() => _showTags = !_showTags),
              onTagTap: widget.onTagTap,
              inMealItems: widget.inMealItems,
              mealItemCount: widget.mealItemCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return CardHeroReveal(
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _DiagonalStreak extends StatefulWidget {
  const _DiagonalStreak();

  @override
  State<_DiagonalStreak> createState() => _DiagonalStreakState();
}

class _DiagonalStreakState extends State<_DiagonalStreak>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(-0.4 * MediaQuery.sizeOf(context).width *
              (_controller.value % 1.4), 0),
          child: child,
        );
      },
      child: Transform.rotate(
        angle: 115 * math.pi / 180,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0x66FFFFFF),
                Color(0x33FFFFFF),
                Colors.transparent,
              ],
              stops: [0.4, 0.45, 0.5, 0.55],
            ),
          ),
        ),
      ),
    );
  }
}

class _EdgeGlows extends StatelessWidget {
  const _EdgeGlows({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 3,
            child: _GlowBar(
              colors: [
                Colors.transparent,
                color.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 2,
            child: _GlowBar(
              colors: [
                Colors.transparent,
                color.withValues(alpha: 0.27),
                Colors.transparent,
              ],
              delay: 1.5,
            ),
          ),
          Positioned(
            left: 0,
            top: '20%' == '20%' ? MediaQuery.sizeOf(context).height * 0.2 : 0,
            bottom: MediaQuery.sizeOf(context).height * 0.3,
            width: 2,
            child: _GlowBar(
              colors: [
                Colors.transparent,
                color.withValues(alpha: 0.2),
                Colors.transparent,
              ],
              vertical: true,
            ),
          ),
          Positioned(
            right: 0,
            top: MediaQuery.sizeOf(context).height * 0.2,
            bottom: MediaQuery.sizeOf(context).height * 0.3,
            width: 2,
            child: _GlowBar(
              colors: [
                Colors.transparent,
                color.withValues(alpha: 0.2),
                Colors.transparent,
              ],
              vertical: true,
              delay: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBar extends StatefulWidget {
  const _GlowBar({
    required this.colors,
    this.delay = 0,
    this.vertical = false,
  });

  final List<Color> colors;
  final double delay;
  final bool vertical;

  @override
  State<_GlowBar> createState() => _GlowBarState();
}

class _GlowBarState extends State<_GlowBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay > 0) {
      Future<void>.delayed(
        Duration(milliseconds: (widget.delay * 1000).round()),
        () {
          if (mounted) _controller.repeat();
        },
      );
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = (_controller.value * 1.5).clamp(0.0, 1.0);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            if (widget.vertical) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.colors,
                transform: _SlideTransform(
                  (t - 1) * 2,
                  vertical: true,
                  extent: bounds.height,
                ),
              ).createShader(bounds);
            }
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: widget.colors,
              transform: _SlideTransform(
                (t - 1) * 2,
                vertical: false,
                extent: bounds.width,
              ),
            ).createShader(bounds);
          },
          child: Container(color: Colors.white),
        );
      },
    );
  }
}

class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.factor, {required this.vertical, required this.extent});

  final double factor;
  final bool vertical;
  final double extent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    if (vertical) return Matrix4.translationValues(0, extent * factor, 0);
    return Matrix4.translationValues(extent * factor, 0, 0);
  }
}

class _HeroSpread extends StatelessWidget {
  const _HeroSpread({
    required this.emoji,
    required this.accent,
    required this.tiny,
    required this.compact,
  });

  final String emoji;
  final Color accent;
  final bool tiny;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final glow = (tiny ? 140 : compact ? 220 : 320).toDouble();
    final plateW = (tiny ? 130 : compact ? 200 : 280).toDouble();
    final plateH = (tiny ? 100 : compact ? 150 : 210).toDouble();
    final spec = (tiny ? 30 : compact ? 50 : 70).toDouble();
    final emojiSize = (tiny ? 56 : compact ? 88 : 140).toDouble();

    return Positioned(
      top: (tiny ? 0.38 : 0.42) * MediaQuery.sizeOf(context).height,
      left: 0,
      right: 0,
      child: Column(
        children: [
          SizedBox(
            width: glow,
            height: glow,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Radial spotlight
                Pulse(
                  amount: 0.06,
                  duration: const Duration(seconds: 4),
                  child: Container(
                    width: glow,
                    height: glow,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.05),
                          accent.withValues(alpha: 0.025),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.3, 0.6],
                      ),
                    ),
                  ),
                ),
                // Plate glow
                Pulse(
                  amount: 0.04,
                  duration: const Duration(milliseconds: 2750),
                  child: Container(
                    width: plateW,
                    height: plateH,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EmojiThemes.plateGlow(emoji),
                      boxShadow: [
                        BoxShadow(
                          color: EmojiThemes.plateGlow(emoji),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    transform: Matrix4.translationValues(0, plateH * 0.04, 0),
                  ),
                ),
                // Specular highlight
                Positioned(
                  top: -spec * 0.5,
                  left: -spec * 0.5,
                  child: Container(
                    width: spec,
                    height: spec,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x2EFFFFFF),
                          Color(0x14FFFFFF),
                          Colors.transparent,
                        ],
                        stops: [0, 0.35, 0.7],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: Offset(0, -glow * 0.72),
            child: CardHeroReveal(
              child: EmojiFloat(
                duration: const Duration(seconds: 3),
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: emojiSize,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: emojiSize * 0.22,
                        offset: Offset(0, emojiSize * 0.06),
                      ),
                      Shadow(
                        color: accent.withValues(alpha: 0.13),
                        blurRadius: emojiSize * 0.28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParallaxLayer extends StatelessWidget {
  const _ParallaxLayer({required this.emoji, required this.scale});

  final String emoji;
  final BiteScale scale;

  @override
  Widget build(BuildContext context) {
    final emojis = EmojiThemes.spreadEmojis(emoji);
    final c = scale;

    List<({String e, double? left, double? right, double top, double sz,
        double op, double blur, double dur, double delay, double rot, int z})>
        items;
    if (c.isXS) {
      items = [
        (e: emojis[0], left: 0.08, right: null, top: 0.22, sz: 14, op: 0.06,
            blur: 1.5, dur: 6, delay: 0, rot: -15, z: 0),
        (e: emojis[3], left: null, right: 0.10, top: 0.58, sz: 12, op: 0.05,
            blur: 1.5, dur: 5, delay: 1, rot: 12, z: 0),
      ];
    } else if (c.isTiny) {
      items = [
        (e: emojis[0], left: 0.08, right: null, top: 0.22, sz: 16, op: 0.06,
            blur: 1.5, dur: 6, delay: 0, rot: -15, z: 0),
        (e: emojis[2], left: null, right: 0.10, top: 0.40, sz: 14, op: 0.08,
            blur: 1, dur: 4.5, delay: 0.5, rot: 10, z: 0),
        (e: emojis[4], left: 0.14, right: null, top: 0.58, sz: 12, op: 0.05,
            blur: 1.5, dur: 5, delay: 1, rot: -8, z: 0),
      ];
    } else {
      final compact = c.isCompact;
      items = [
        (e: emojis[0], left: 0.06, right: null, top: 0.15,
            sz: compact ? 28 : 48, op: 0.07, blur: 2, dur: 6, delay: 0,
            rot: -20, z: 0),
        (e: emojis[1], left: null, right: 0.08, top: 0.55,
            sz: compact ? 32 : 52, op: 0.06, blur: 2.5, dur: 7, delay: 1,
            rot: 15, z: 0),
        (e: emojis[2], left: 0.15, right: null, top: 0.35,
            sz: compact ? 18 : 28, op: 0.14, blur: 0.8, dur: 4.2, delay: 0.3,
            rot: 8, z: 1),
        (e: emojis[3], left: null, right: 0.12, top: 0.25,
            sz: compact ? 16 : 26, op: 0.12, blur: 0.6, dur: 3.8, delay: 0.8,
            rot: -12, z: 1),
        (e: emojis[4], left: 0.20, right: null, top: 0.62,
            sz: compact ? 14 : 24, op: 0.10, blur: 0.5, dur: 4.5, delay: 1.5,
            rot: 22, z: 1),
        (e: emojis[5], left: null, right: 0.22, top: 0.68,
            sz: compact ? 12 : 18, op: 0.22, blur: 0, dur: 3, delay: 0.5,
            rot: -6, z: 1),
      ];
    }

    return IgnorePointer(
      child: Stack(
        children: [
          for (var i = 0; i < items.length; i++)
            Positioned(
              left: items[i].left != null ? items[i].left! * MediaQuery.sizeOf(context).width : null,
              right: items[i].right != null ? items[i].right! * MediaQuery.sizeOf(context).width : null,
              top: items[i].top * MediaQuery.sizeOf(context).height,
              child: Opacity(
                opacity: items[i].op,
                child: EmojiFloat(
                  duration: Duration(
                      milliseconds: (items[i].dur * 1000).round()),
                  child: Transform.rotate(
                    angle: items[i].rot * math.pi / 180,
                    child: Text(
                      items[i].e,
                      style: TextStyle(
                        fontSize: items[i].sz,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: items[i].blur * 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Companions extends StatelessWidget {
  const _Companions({required this.card, required this.compact});

  final BiteCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final seed = ((card.id | 0) * 2654435761) % 2147483647;
    if ((seed % 100) < 35) return const SizedBox.shrink();

    const pools = {
      '\$': ['🏪', '🪑', '🧃', '🥤', '🍴', '🧺'],
      '\$\$': ['🏬', '🍽', '🪑', '🎶', '🍴', '🌆'],
      '\$\$\$': ['🏨', '🍷', '🕯', '🎷', '✨', '🌃'],
      '\$\$\$\$': ['🏛', '🥂', '🕯', '✨', '🎼', '🌙'],
    };
    const outdoor = ['🧺', '🌳', '⛱', '🌻', '🌿', '🏕'];

    final base = EmojiThemes.spreadEmojis(card.emoji);
    var emojis = base;
    final isPlace = card.isPlace;
    if (isPlace && (seed % 100) < 50) {
      final price = card.priceLevel ?? '\$\$';
      final pool = pools[price] ?? pools['\$\$']!;
      final atmoIdx = seed % pool.length;
      final atmoIdx2 = (seed * 7) % pool.length;
      final picnic = (seed % 100) < 18;
      emojis = [
        base[0],
        pool[atmoIdx],
        base[2],
        pool[atmoIdx2],
        picnic ? outdoor[seed % outdoor.length] : base[4],
        pool[(atmoIdx + 2) % pool.length],
      ];
    }

    final mainSize = compact ? 88.0 : 140.0;
    final companionSize = mainSize * 0.48;
    final variant = seed % 4;

    final List<({String e, double? left, double? right, double top, double sz,
        double rot, int dur, double delay, int drop})> comps = [];
    if (variant == 0 || variant == 2 || variant == 3) {
      comps.add((
        e: emojis[2],
        left: 0.30,
        right: null,
        top: variant == 3 ? 0.58 : 0.38,
        sz: companionSize,
        rot: -15,
        dur: 4,
        delay: 0.3,
        drop: 1,
      ));
    }
    if (variant == 1 || variant == 2 || variant == 3) {
      comps.add((
        e: emojis[3],
        left: null,
        right: 0.30,
        top: variant == 3 ? 0.38 : 0.56,
        sz: companionSize * 0.92,
        rot: 18,
        dur: 4,
        delay: 0.7,
        drop: 1,
      ));
    }
    if ((seed % 100) < 28 && comps.isNotEmpty) {
      comps.add((
        e: emojis[5],
        left: 0.44,
        right: null,
        top: 0.72,
        sz: companionSize * 0.55,
        rot: 8,
        dur: 4,
        delay: 1.1,
        drop: 0,
      ));
    }

    return IgnorePointer(
      child: Stack(
        children: [
          for (var i = 0; i < comps.length; i++)
            Positioned(
              left: comps[i].left != null
                  ? comps[i].left! * MediaQuery.sizeOf(context).width
                  : null,
              right: comps[i].right != null
                  ? comps[i].right! * MediaQuery.sizeOf(context).width
                  : null,
              top: comps[i].top * MediaQuery.sizeOf(context).height,
              child: Opacity(
                opacity: 0.78,
                child: EmojiFloat(
                  duration: Duration(seconds: comps[i].dur),
                  child: Transform.rotate(
                    angle: comps[i].rot * math.pi / 180,
                    child: Text(
                      comps[i].e,
                      style: TextStyle(
                        fontSize: comps[i].sz,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: comps[i].drop * 12,
                            offset: Offset(0, comps[i].drop * 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SwipeHints extends StatelessWidget {
  const _SwipeHints();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 145,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Opacity(
                opacity: 0.15,
                child: Pulse(
                  amount: 0,
                  child: const Icon(Icons.keyboard_arrow_up_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(height: 2),
              const Opacity(
                opacity: 0.15,
                child: Icon(Icons.keyboard_arrow_up_rounded,
                    color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 110,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const Opacity(
                opacity: 0.10,
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(height: 2),
              Opacity(
                opacity: 0.10,
                child: Pulse(
                  amount: 0,
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomContent extends StatelessWidget {
  const _BottomContent({
    required this.card,
    required this.subTab,
    required this.accent,
    required this.scale,
    required this.infoExpanded,
    required this.onToggleInfo,
    required this.onTap,
    required this.onCreatorTap,
    required this.followed,
    required this.onFollowToggle,
    required this.onOrderTap,
    required this.onMealTap,
    required this.onFavoriteTap,
    required this.onCallTap,
    required this.onDirectionsTap,
    required this.onReserveTap,
    required this.showTags,
    required this.onToggleTags,
    required this.onTagTap,
    required this.inMealItems,
    required this.mealItemCount,
  });

  final BiteCard card;
  final DeckTab subTab;
  final Color accent;
  final BiteScale scale;
  final bool infoExpanded;
  final VoidCallback onToggleInfo;
  final VoidCallback onTap;
  final VoidCallback onCreatorTap;
  final bool followed;
  final VoidCallback onFollowToggle;
  final VoidCallback onOrderTap;
  final VoidCallback onMealTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onCallTap;
  final VoidCallback onDirectionsTap;
  final VoidCallback onReserveTap;
  final bool showTags;
  final VoidCallback onToggleTags;
  final ValueChanged<String> onTagTap;
  final bool inMealItems;
  final int mealItemCount;

  bool get _isPlace => card.isPlace;
  bool get _tiny => scale.isTiny || scale.isXS;
  bool get _compact => scale.isCompact || scale.isS;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(0, 0, 0, 0.95),
            Color.fromRGBO(0, 0, 0, 0.7),
            Colors.transparent,
          ],
          stops: [0, 0.4, 1],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        _tiny ? 12 : 20,
        _tiny ? 40 : _compact ? 80 : 120,
        _tiny ? 12 : 20,
        _tiny ? 56 : _compact ? 80 : 100,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator row
          PopIn(
            duration: const Duration(milliseconds: 240),
            child: Row(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: onCreatorTap,
                      child: Container(
                        width: _tiny ? 28 : 32,
                        height: _tiny ? 28 : 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.coral, AppColors.amber],
                          ),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1.5),
                        ),
                        child: Text(
                          '👩‍🍳',
                          style: TextStyle(fontSize: _tiny ? 12 : 14),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: GestureDetector(
                        onTap: onFollowToggle,
                        child: Container(
                          width: _tiny ? 14 : 16,
                          height: _tiny ? 14 : 16,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: followed
                                ? AppColors.saveGreen
                                : accent,
                            border: Border.all(
                                color: const Color(0xFF0D0D0D), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: (followed
                                        ? AppColors.saveGreen
                                        : accent)
                                    .withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Opacity(
                            opacity: followed ? 0.55 : 1,
                            child: Text(
                              followed ? '✓' : '+',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: _tiny ? 9 : 10,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCreatorTap,
                  child: Text(
                    card.creator,
                    style: TextStyle(
                      fontSize: _tiny ? 11 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Title row + chevron
          GestureDetector(
            onTap: onToggleInfo,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _LetterWaveTitle(
                    title: card.title,
                    fontSize: _tiny ? 18 : _compact ? 22 : 26,
                    accent: EmojiThemes.dishAccent(card.emoji),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: _tiny ? 22 : 28,
                  height: _tiny ? 22 : 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: infoExpanded
                        ? accent.withValues(alpha: 0.09)
                        : Colors.white.withValues(alpha: 0.04),
                    border: Border.all(
                      color: infoExpanded
                          ? accent.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: AnimatedRotation(
                    turns: infoExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: _tiny ? 12 : 14,
                      color: infoExpanded
                          ? accent
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Info expand wrapper
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            alignment: Alignment.topCenter,
            child: infoExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MetaRow(
                        card: card,
                        subTab: subTab,
                        tiny: _tiny,
                        showTags: showTags,
                        onToggleTags: onToggleTags,
                        onTagTap: onTagTap,
                      ),
                      if (showTags && card.tags.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        _TagsRow(tags: card.tags, tiny: _tiny, onTagTap: onTagTap),
                      ],
                      if (_isPlace) ...[
                        const SizedBox(height: 8),
                        _PlaceInfo(card: card, tiny: _tiny),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),
          // Action row
          if (_isPlace)
            _PlaceActions(
              card: card,
              tiny: _tiny,
              compact: _compact,
              onCallTap: onCallTap,
              onDirectionsTap: onDirectionsTap,
              onReserveTap: onReserveTap,
              onOrderTap: onOrderTap,
            )
          else
            _FoodActions(
              card: card,
              tiny: _tiny,
              accent: accent,
              onFavoriteTap: onFavoriteTap,
              onOrderTap: onOrderTap,
              onMealTap: onMealTap,
              inMealItems: inMealItems,
              mealItemCount: mealItemCount,
            ),
        ],
      ),
    );
  }
}

class _LetterWaveTitle extends StatefulWidget {
  const _LetterWaveTitle({
    required this.title,
    required this.fontSize,
    required this.accent,
  });

  final String title;
  final double fontSize;
  final Color accent;

  @override
  State<_LetterWaveTitle> createState() => _LetterWaveTitleState();
}

class _LetterWaveTitleState extends State<_LetterWaveTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chars = widget.title.split('');
    final stagger = chars.length > 16 ? 0.025 : 0.045;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (var i = 0; i < chars.length; i++)
              _CharWave(
                char: chars[i],
                progress: ((_controller.value * 1.7) - (0.5 + i * stagger))
                    .clamp(0.0, 1.0),
                fontSize: widget.fontSize,
              ),
          ],
        );
      },
    );
  }
}

class _CharWave extends StatelessWidget {
  const _CharWave({
    required this.char,
    required this.progress,
    required this.fontSize,
  });

  final String char;
  final double progress;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final wave = math.sin(progress * math.pi);
    return Transform.translate(
      offset: Offset(0, -wave * 6),
      child: Opacity(
        opacity: (progress * 1.6).clamp(0.0, 1.0),
        child: Text(
          char,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.5,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.card,
    required this.subTab,
    required this.tiny,
    required this.showTags,
    required this.onToggleTags,
    required this.onTagTap,
  });

  final BiteCard card;
  final DeckTab subTab;
  final bool tiny;
  final bool showTags;
  final VoidCallback onToggleTags;
  final ValueChanged<String> onTagTap;

  @override
  Widget build(BuildContext context) {
    final diffColor = switch (card.diff) {
      'Easy' => const Color(0xFF66BB6A),
      'Hard' => AppColors.coral,
      _ => AppColors.amber,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        children: [
          const Spacer(),
          if (card.tags.isNotEmpty)
            GestureDetector(
              onTap: onToggleTags,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: tiny ? 7 : 9, vertical: tiny ? 1 : 2),
                decoration: BoxDecoration(
                  color: showTags
                      ? AppColors.amber.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(100),
                  border:
                      Border.all(color: AppColors.amber.withValues(alpha: 0.13)),
                ),
                child: Row(
                  children: [
                    Text(
                      '#',
                      style: TextStyle(
                        fontSize: tiny ? 9 : 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.amber,
                      ),
                    ),
                    Text(
                      '${card.tags.length}',
                      style: TextStyle(
                        fontSize: tiny ? 8 : 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    AnimatedRotation(
                      turns: showTags ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: tiny ? 8 : 9, color: AppColors.cyan),
                    ),
                  ],
                ),
              ),
            ),
          if (card.saved.isNotEmpty) ...[
            const SizedBox(width: 6),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Transform.translate(
                    offset: Offset(i > 0 ? -4.0 * i : 0, 0),
                    child: Container(
                      width: tiny ? 11 : 13,
                      height: tiny ? 11 : 13,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const [
                          AppColors.coral,
                          AppColors.amber,
                          AppColors.cyan
                        ][i],
                        border: Border.all(
                            color: const Color(0xFF0D0D0D), width: 1.5),
                      ),
                      child: Text(
                        const ['👩', '🧑', '👨'][i],
                        style: TextStyle(fontSize: tiny ? 6 : 7),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Text(
                  card.saved,
                  style: TextStyle(
                    fontSize: tiny ? 9 : 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ],
          if (subTab != DeckTab.places && !tiny) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(100),
                border:
                    Border.all(color: AppColors.amber.withValues(alpha: 0.13)),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 8)),
                  const SizedBox(width: 3),
                  Text(
                    'Trending',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppColors.coral.withValues(alpha: 0.09)),
            ),
            child: Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: tiny ? 8 : 9, color: AppColors.coral),
                const SizedBox(width: 3),
                Text(
                  '${(card.id * 127 + 203) % 900 + 100}',
                  style: TextStyle(
                    fontSize: tiny ? 8 : 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.coral,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (card.serves > 0)
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: tiny ? 9 : 11, color: AppColors.muted),
                Text(
                  '${card.serves}',
                  style: TextStyle(
                    fontSize: tiny ? 9 : 11,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          if (card.heat > 0)
            Row(
              children: [
                for (var i = 0; i < card.heat; i++)
                  Text(
                    '🌶',
                    style: TextStyle(
                      fontSize: tiny ? 9 : 11,
                      fontWeight: FontWeight.w800,
                      color: card.heat >= 3 ? AppColors.coral : AppColors.amber,
                    ),
                  ),
                const SizedBox(width: 6),
              ],
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: diffColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: diffColor.withValues(alpha: 0.25)),
            ),
            child: Text(
              card.diff == 'Easy'
                  ? 'E'
                  : card.diff == 'Hard'
                      ? 'H'
                      : 'M',
              style: TextStyle(
                fontSize: tiny ? 9 : 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: diffColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  size: tiny ? 10 : 12, color: AppColors.muted),
              const SizedBox(width: 3),
              Text(
                tiny ? card.time.replaceAll(' min', 'm') : card.time,
                style: TextStyle(fontSize: tiny ? 10 : 12, color: AppColors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({
    required this.tags,
    required this.tiny,
    required this.onTagTap,
  });

  final List<String> tags;
  final bool tiny;
  final ValueChanged<String> onTagTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final tag in tags)
          GestureDetector(
            onTap: () => onTagTap(tag),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: tiny ? 7 : 10, vertical: tiny ? 2 : 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                tag.replaceFirst('#', ''),
                style: TextStyle(
                  fontSize: tiny ? 9 : 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PlaceInfo extends StatelessWidget {
  const _PlaceInfo({required this.card, required this.tiny});

  final BiteCard card;
  final bool tiny;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tiny ? 10 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tiny ? 10 : 12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x599B59B6),
            Color(0x409B59B6),
          ],
        ),
        border: Border.all(color: const Color(0x479B59B6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📍', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.address ?? '',
                      style: TextStyle(
                        fontSize: tiny ? 11 : 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${card.status ?? ''} · ${card.distance ?? ''}',
                      style: TextStyle(
                        fontSize: tiny ? 10 : 10.5,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (card.menuHighlights.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
            const SizedBox(height: 8),
            for (var i = 0;
                i < card.menuHighlights.length && i < 2;
                i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '• ${card.menuHighlights[i].name}',
                      style: TextStyle(
                        fontSize: tiny ? 10 : 11.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      card.menuHighlights[i].price,
                      style: TextStyle(
                        fontSize: tiny ? 10 : 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC084FC),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FoodActions extends StatelessWidget {
  const _FoodActions({
    required this.card,
    required this.tiny,
    required this.accent,
    required this.onFavoriteTap,
    required this.onOrderTap,
    required this.onMealTap,
    required this.inMealItems,
    required this.mealItemCount,
  });

  final BiteCard card;
  final bool tiny;
  final Color accent;
  final VoidCallback onFavoriteTap;
  final VoidCallback onOrderTap;
  final VoidCallback onMealTap;
  final bool inMealItems;
  final int mealItemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          label: '⭐',
          size: tiny ? 34 : 40,
          bg: const Color(0x14FFD700),
          border: const Color(0x33FFD700),
          onTap: onFavoriteTap,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: onOrderTap,
            child: Container(
              height: tiny ? 34 : 40,
              padding: EdgeInsets.symmetric(horizontal: tiny ? 10 : 16),
              decoration: BoxDecoration(
                color: const Color(0xB8224422),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0x4D50C850)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 6),
                  Text(
                    'Order',
                    style: TextStyle(
                      fontSize: tiny ? 10 : 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF66BB6A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onMealTap,
          child: Container(
            height: tiny ? 34 : 40,
            padding: EdgeInsets.symmetric(horizontal: tiny ? 10 : 16),
            decoration: BoxDecoration(
              color: inMealItems
                  ? AppColors.saveGreen.withValues(alpha: 0.12)
                  : AppColors.amber.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: inMealItems
                    ? AppColors.saveGreen.withValues(alpha: 0.35)
                    : AppColors.amber.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: inMealItems
                  ? [
                      const Text('🍽', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$mealItemCount',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.saveGreen,
                        ),
                      ),
                    ]
                  : [
                      const Text('➕', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        'Meal',
                        style: TextStyle(
                          fontSize: tiny ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.lock_outline_rounded,
                          size: 10, color: AppColors.amber),
                    ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.label,
    required this.size,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  final String label;
  final double size;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

class _PlaceActions extends StatelessWidget {
  const _PlaceActions({
    required this.card,
    required this.tiny,
    required this.compact,
    required this.onCallTap,
    required this.onDirectionsTap,
    required this.onReserveTap,
    required this.onOrderTap,
  });

  final BiteCard card;
  final bool tiny;
  final bool compact;
  final VoidCallback onCallTap;
  final VoidCallback onDirectionsTap;
  final VoidCallback onReserveTap;
  final VoidCallback onOrderTap;

  @override
  Widget build(BuildContext context) {
    final h = tiny ? 34.0 : compact ? 42.0 : 52.0;
    return Row(
      children: [
        _CircleAction(icon: Icons.call_rounded, color: const Color(0xFF66BB6A), size: tiny ? 34 : 44, onTap: onCallTap),
        const SizedBox(width: 6),
        _CircleAction(icon: Icons.navigation_rounded, color: AppColors.placesPurple, size: tiny ? 34 : 44, onTap: onDirectionsTap),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: onReserveTap,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: const Color(0x38A855F7),
                borderRadius: BorderRadius.circular(tiny ? 10 : 12),
                border: Border.all(color: const Color(0x73A855F7)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1AA855F7),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🪑', style: TextStyle(fontSize: tiny ? 11 : 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Reserve',
                    style: TextStyle(
                      fontSize: tiny ? 11 : 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFC084FC),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: onOrderTap,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: const Color(0x33F5A623),
                borderRadius: BorderRadius.circular(tiny ? 10 : 12),
                border: Border.all(color: const Color(0x73F5A623)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1AF5A623),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🛵', style: TextStyle(fontSize: tiny ? 11 : 14)),
                  const SizedBox(width: 6),
                  Text(
                    'Order',
                    style: TextStyle(
                      fontSize: tiny ? 11 : 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8),
          ],
        ),
        child: Icon(icon, size: size * 0.36, color: color),
      ),
    );
  }
}
