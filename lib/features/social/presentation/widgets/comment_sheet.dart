import 'package:flutter/material.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../data/mock_social_data.dart';

/// Comments bottom sheet — ports the `commentSheet` overlay from
/// `SocialFeedScreen`. Input + quick-reply chips live at the top (the
/// "modern 2026 pattern" the prototype calls out), the scrollable comment
/// list is below.
class CommentSheet extends StatefulWidget {
  const CommentSheet({
    super.key,
    required this.myAvatarEmoji,
    required this.initialUserComments,
    required this.onClose,
    required this.onPosted,
  });

  final String myAvatarEmoji;
  final List<String> initialUserComments;
  final VoidCallback onClose;
  final ValueChanged<List<String>> onPosted;

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  late final List<String> _userComments = [...widget.initialUserComments];
  final TextEditingController _controller = TextEditingController();
  final Set<int> _liked = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _post(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() => _userComments.add(trimmed));
    widget.onPosted(_userComments);
    _controller.clear();
    ToastService.instance.show('💬 Comment posted!');
  }

  @override
  Widget build(BuildContext context) {
    final displayCount = mockSampleComments.length + _userComments.length;
    final rows = [
      for (final c in _userComments.reversed)
        SocialComment(user: '@you', avatarEmoji: widget.myAvatarEmoji, text: c, time: 'Just now', likes: 0, isYou: true),
      ...mockSampleComments,
    ];

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: SlideUp(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: AppColors.bgDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Color(0x14FFFFFF)),
                  left: BorderSide(color: Color(0x14FFFFFF)),
                  right: BorderSide(color: Color(0x14FFFFFF)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Comments (${_fmt(displayCount)})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: widget.onClose,
                              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppColors.coral, AppColors.amber]),
                              ),
                              alignment: Alignment.center,
                              child: Text(widget.myAvatarEmoji, style: const TextStyle(fontSize: 14)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.glass,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.glassBorder),
                                ),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: _controller,
                                  onTap: () {
                                    if (_controller.text.isEmpty) {
                                      setState(() => _controller.text =
                                          'This looks amazing! 🤤🔥 Need to try this ASAP');
                                    }
                                  },
                                  onSubmitted: _post,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    hintText: 'Add a comment...',
                                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, _) {
                                final hasText = _controller.text.trim().isNotEmpty;
                                return GestureDetector(
                                  onTap: hasText ? () => _post(_controller.text) : null,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: hasText ? AppColors.coral : Colors.white.withValues(alpha: 0.06),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(Icons.send_rounded,
                                        size: 16, color: hasText ? Colors.white : AppColors.muted),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final chip in commentQuickChips)
                                GestureDetector(
                                  onTap: () => _post(chip),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                                    ),
                                    child: Text(chip,
                                        style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0x0FFFFFFF)),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      shrinkWrap: true,
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final c = rows[i];
                        final liked = _liked.contains(i);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0x0AFFFFFF))),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AvatarImg(
                                    emoji: c.avatarEmoji,
                                    imageUrl: c.avatarUrl,
                                    size: 36,
                                    borderWidth: 0,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              c.user,
                                              style: TextStyle(
                                                color: c.isYou ? AppColors.coral : Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(c.time,
                                                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                            if (c.isYou) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.coral.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('YOU',
                                                    style: TextStyle(
                                                        color: AppColors.coral,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(c.text,
                                            style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.7),
                                                fontSize: 13,
                                                height: 1.4)),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            if (liked) {
                                              _liked.remove(i);
                                            } else {
                                              _liked.add(i);
                                            }
                                          }),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                                size: 10,
                                                color: liked ? AppColors.coral : AppColors.muted,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${c.likes + (liked ? 1 : 0)}',
                                                style: TextStyle(
                                                  color: liked ? AppColors.coral : AppColors.muted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(int n) => n.toString();
}
