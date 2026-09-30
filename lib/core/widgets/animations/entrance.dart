import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// PopIn — scale 0 → 1.2 → 1 with fade. Ports `@keyframes popIn`.
class PopIn extends StatefulWidget {
  const PopIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutBack,
    this.begin = 0,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final double begin;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 0, end: 1.2),
            weight: 50,
          ),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1), weight: 50),
        ]).animate(_controller),
        child: widget.child,
      ),
    );
  }
}

/// ZoomIn — scale 0.85 → 1 with fade. Ports `@keyframes zoomIn`.
class ZoomIn extends StatefulWidget {
  const ZoomIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<ZoomIn> createState() => _ZoomInState();
}

class _ZoomInState extends State<ZoomIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.85, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: widget.curve),
        ),
        child: widget.child,
      ),
    );
  }
}

/// SlideUp — translateY(100%) → 0 with fade. Ports `@keyframes slideUp`.
class SlideUp extends StatefulWidget {
  const SlideUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  State<SlideUp> createState() => _SlideUpState();
}

class _SlideUpState extends State<SlideUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offset = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      child: SlideTransition(position: offset, child: widget.child),
    );
  }
}

/// StaggerReveal — reveals children one-by-one with staggered delays.
class StaggerReveal extends StatelessWidget {
  const StaggerReveal({
    super.key,
    required this.children,
    this.stagger = const Duration(milliseconds: 80),
    this.axis = Axis.vertical,
  });

  final List<Widget> children;
  final Duration stagger;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          _StaggeredItem(
            index: i,
            stagger: stagger,
            axis: axis,
            child: children[i],
          ),
      ],
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({
    required this.index,
    required this.stagger,
    required this.axis,
    required this.child,
  });

  final int index;
  final Duration stagger;
  final Axis axis;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.stagger * widget.index, _controller.forward);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    final begin = widget.axis == Axis.vertical
        ? const Offset(0, 0.15)
        : const Offset(0.1, 0);
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: begin, end: Offset.zero).animate(animation),
        child: widget.child,
      ),
    );
  }
}

/// FadeInOut — one-shot fade in → hold → fade out. Ports `@keyframes fadeInOut`.
class FadeInOut extends StatefulWidget {
  const FadeInOut({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2800),
  });

  final Widget child;
  final Duration duration;

  @override
  State<FadeInOut> createState() => _FadeInOutState();
}

class _FadeInOutState extends State<FadeInOut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 30),
        TweenSequenceItem(tween: ConstantTween(1), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 30),
      ]).animate(_controller),
      child: widget.child,
    );
  }
}

/// CardHeroReveal — scale 0.94 + blur → 1. Ports `@keyframes cardHeroReveal`.
class CardHeroReveal extends StatefulWidget {
  const CardHeroReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final Duration duration;

  @override
  State<CardHeroReveal> createState() => _CardHeroRevealState();
}

class _CardHeroRevealState extends State<CardHeroReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  late final Animation<double> _scale =
      Tween(begin: 0.94, end: 1.0).animate(_curve);
  late final Animation<double> _blur =
      Tween(begin: 4.0, end: 0.0).animate(_curve);

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Once finished, drop the blur layer entirely — a zero-sigma
          // ImageFiltered still forces an offscreen pass every frame.
          if (_controller.isCompleted) return child!;
          final sigma = _blur.value;
          return Transform.scale(
            scale: _scale.value,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
