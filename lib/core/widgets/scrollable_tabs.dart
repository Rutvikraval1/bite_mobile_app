import 'package:flutter/material.dart';

/// A horizontally scrollable row of pills with overflow edge fades.
/// Ports `ScrollableTabs` from `ui.jsx`.
class ScrollableTabs extends StatefulWidget {
  const ScrollableTabs({
    super.key,
    required this.children,
    this.leftPad = 12,
    this.rightPad = 40,
    this.itemGap = 6,
  });

  final List<Widget> children;
  final double leftPad;
  final double rightPad;
  final double itemGap;

  @override
  State<ScrollableTabs> createState() => _ScrollableTabsState();
}

class _ScrollableTabsState extends State<ScrollableTabs> {
  final ScrollController _controller = ScrollController();
  bool _hasRight = false;
  bool _hasLeft = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _controller.position;
    final newRight = position.maxScrollExtent - position.pixels > 4;
    final newLeft = position.pixels > 4;
    setState(() {
      _hasLeft = newLeft;
      _hasRight = newRight;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          ListView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              SizedBox(width: widget.leftPad),
              for (var i = 0; i < widget.children.length; i++) ...[
                if (i > 0) SizedBox(width: widget.itemGap),
                widget.children[i],
              ],
              SizedBox(width: widget.rightPad),
            ],
          ),
          if (_hasLeft)
            const Positioned(left: 0, top: 0, bottom: 0, width: 40, child: _EdgeFade()),
          if (_hasRight)
            const Positioned(right: 0, top: 0, bottom: 0, width: 40, child: _EdgeFade()),
        ],
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF0D0D0D),
            const Color(0xFF0D0D0D).withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
