import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../domain/social_models.dart';
import '../blocs/social_feed_cubit.dart';

/// Comment quick-reply chips.
const List<String> commentQuickChips = ['🔥 Fire!', '😍 Love this!', 'Need recipe!', '💯 Amazing', 'Saving this'];

/// Comments bottom sheet — ports the `commentSheet` overlay from
/// `SocialFeedScreen`. Input + quick-reply chips live at the top (the
/// "modern 2026 pattern" the prototype calls out), the scrollable comment
/// list is below. Comments for [post] live in `public.post_comments`.
class CommentSheet extends StatefulWidget {
  const CommentSheet({
    super.key,
    required this.post,
    required this.myAvatarEmoji,
    required this.onClose,
  });

  final FeedPost post;
  final String myAvatarEmoji;
  final VoidCallback onClose;

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _controller = TextEditingController();
  List<PostComment> _comments = const [];
  Set<String> _liked = {};
  bool _loading = true;
  bool _posting = false;

  late final SocialFeedCubit _feed = context.read<SocialFeedCubit>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = _feed.userId;
    try {
      final comments = await _feed.repository.fetchComments(widget.post.id);
      final liked = userId == null
          ? <String>{}
          : await _feed.repository.fetchLikedCommentIds(userId, [for (final c in comments) c.id]);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _liked = liked;
        _loading = false;
      });
      _feed.setCommentCount(widget.post.id, comments.length);
    } catch (e) {
      debugPrint('[social] comments load failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ToastService.instance.show("⚠️ Couldn't load comments.");
    }
  }

  Future<void> _post(String text) async {
    final trimmed = text.trim();
    final userId = _feed.userId;
    if (trimmed.isEmpty || _posting || userId == null) return;
    setState(() => _posting = true);
    final handle = await _feed.ensureHandle();
    if (!mounted) return;
    if (handle == null) {
      setState(() => _posting = false);
      ToastService.instance.show('⚠️ Pick a username in Edit Profile to comment.');
      return;
    }
    try {
      final comment = await _feed.repository.addComment(
        userId: userId,
        handle: handle,
        postId: widget.post.id,
        body: trimmed,
      );
      if (!mounted) return;
      setState(() {
        _comments = [comment, ..._comments];
        _posting = false;
      });
      _controller.clear();
      _feed.setCommentCount(widget.post.id, _comments.length);
      ToastService.instance.show('💬 Comment posted!');
    } catch (e) {
      debugPrint('[social] comment failed: $e');
      if (!mounted) return;
      setState(() => _posting = false);
      ToastService.instance.show("⚠️ Couldn't post comment. Try again.");
    }
  }

  /// Optimistic comment like; reverts on failure.
  Future<void> _toggleLike(PostComment c) async {
    final userId = _feed.userId;
    if (userId == null) return;
    final wasLiked = _liked.contains(c.id);
    void apply(bool like) => setState(() {
          _liked = like ? {..._liked, c.id} : ({..._liked}..remove(c.id));
          _comments = [
            for (final x in _comments)
              x.id == c.id ? x.copyWith(likesCount: (x.likesCount + (like ? 1 : -1)).clamp(0, 1 << 31)) : x,
          ];
        });
    apply(!wasLiked);
    try {
      if (wasLiked) {
        await _feed.repository.unlikeComment(userId, c.id);
      } else {
        await _feed.repository.likeComment(userId, c.id);
      }
    } catch (e) {
      debugPrint('[social] comment like failed: $e');
      if (mounted) apply(wasLiked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myId = _feed.userId;
    final displayCount = _comments.length;
    final rows = _comments;

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
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
                      ),
                    )
                  else if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 28, 20, 36),
                      child: Text('No comments yet — be the first! 💬',
                          style: TextStyle(color: AppColors.muted, fontSize: 13)),
                    ),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      shrinkWrap: true,
                      itemCount: rows.length,
                      itemBuilder: (context, i) {
                        final c = rows[i];
                        final liked = _liked.contains(c.id);
                        final isYou = c.userId != null && c.userId == myId;
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
                                    emoji: isYou ? widget.myAvatarEmoji : (c.creator?.avatarEmoji ?? '🧑‍🍳'),
                                    imageUrl: c.creator?.avatarUrl,
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
                                              c.authorHandle,
                                              style: TextStyle(
                                                color: isYou ? AppColors.coral : Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(_time(c.createdAt),
                                                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                                            if (isYou) ...[
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
                                        Text(c.body,
                                            style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.7),
                                                fontSize: 13,
                                                height: 1.4)),
                                        const SizedBox(height: 4),
                                        GestureDetector(
                                          onTap: () => _toggleLike(c),
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
                                                '${c.likesCount}',
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

  String _time(DateTime at) {
    final t = Formatters.timeAgo(at);
    return t == 'now' ? 'Just now' : t;
  }
}
