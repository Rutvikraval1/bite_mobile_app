import 'package:flutter/material.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';

/// A seed (pre-existing) comment/review shown under the fold.
class SeedComment {
  const SeedComment({
    required this.user,
    required this.avatarEmoji,
    required this.text,
    required this.time,
    this.likes = 0,
  });

  final String user;
  final String avatarEmoji;
  final String text;
  final String time;
  final int likes;
}

/// Social stats row (❤️ hearts · 🔖 saved · 💬 comments) + an expandable
/// inline comment panel. Shared between [RecipeDetailScreen] and
/// [PlaceDetailScreen] — ports the duplicated comments UI from
/// `screens-detail.jsx`.
class SocialCommentsBlock extends StatefulWidget {
  const SocialCommentsBlock({
    super.key,
    required this.hearts,
    required this.saved,
    required this.accentColor,
    required this.seedComments,
    required this.quickChips,
    this.baseCommentCount = 4,
    this.placeholder = 'Add a comment...',
    this.postedToast = '💬 Comment posted!',
  });

  final String hearts;
  final String saved;
  final Color accentColor;
  final List<SeedComment> seedComments;
  final List<String> quickChips;
  final int baseCommentCount;
  final String placeholder;
  final String postedToast;

  @override
  State<SocialCommentsBlock> createState() => _SocialCommentsBlockState();
}

class _SocialCommentsBlockState extends State<SocialCommentsBlock> {
  bool _expanded = false;
  final List<String> _posted = [];
  final Map<int, bool> _liked = {};
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _post(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _posted.add(trimmed);
      _controller.clear();
    });
    ToastService.instance.show(widget.postedToast);
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.baseCommentCount + _posted.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('❤️ ${widget.hearts}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(width: 12),
            Text('🔖 ${widget.saved}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _expanded
                      ? widget.accentColor.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _expanded
                        ? widget.accentColor.withValues(alpha: 0.27)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: _expanded
                    ? _pillContent(count)
                    : Pulse(
                        amount: 0.03,
                        duration: const Duration(milliseconds: 2500),
                        child: _pillContent(count),
                      ),
              ),
            ),
          ],
        ),
        if (_expanded) ...[
          const SizedBox(height: 12),
          SlideUp(
            duration: const Duration(milliseconds: 260),
            child: _panel(count),
          ),
        ],
      ],
    );
  }

  Widget _pillContent(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chat_bubble_outline_rounded,
            size: 13, color: _expanded ? widget.accentColor : AppColors.muted),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: TextStyle(
            color: _expanded ? widget.accentColor : AppColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        AnimatedRotation(
          turns: _expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(Icons.keyboard_arrow_down_rounded,
              size: 12, color: _expanded ? widget.accentColor : AppColors.muted),
        ),
      ],
    );
  }

  Widget _panel(int count) {
    final combined = <SeedComment>[
      for (final c in _posted.reversed)
        SeedComment(user: '@you', avatarEmoji: '🧑‍🍳', text: c, time: 'Now'),
      ...widget.seedComments,
    ];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.coral, widget.accentColor],
                    ),
                  ),
                  child: const Text('🧑‍🍳', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.glass,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: widget.placeholder,
                        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: _post,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _post(_controller.text),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.text.trim().isNotEmpty
                          ? AppColors.coral
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                    child: Icon(Icons.send_rounded,
                        size: 16,
                        color: _controller.text.trim().isNotEmpty
                            ? Colors.white
                            : AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final chip in widget.quickChips)
                  GestureDetector(
                    onTap: () => _post(chip),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Text(chip,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w500)),
                    ),
                  ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: combined.length,
              itemBuilder: (context, i) {
                final c = combined[i];
                final isYou = c.user == '@you';
                final liked = _liked[i] ?? false;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: i > 0
                        ? Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.03)))
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isYou
                                ? [AppColors.coral, AppColors.amber]
                                : [
                                    widget.accentColor.withValues(alpha: 0.2),
                                    AppColors.amber.withValues(alpha: 0.2),
                                  ],
                          ),
                        ),
                        child: Text(c.avatarEmoji, style: const TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(c.user,
                                    style: TextStyle(
                                        color: isYou ? AppColors.coral : Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 4),
                                Text(c.time,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(c.text,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                    height: 1.4)),
                            const SizedBox(height: 2),
                            GestureDetector(
                              onTap: () => setState(() => _liked[i] = !liked),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    size: 9,
                                    color: liked ? widget.accentColor : AppColors.muted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${c.likes + (liked ? 1 : 0)}',
                                    style: TextStyle(
                                        color: liked ? widget.accentColor : AppColors.muted,
                                        fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
