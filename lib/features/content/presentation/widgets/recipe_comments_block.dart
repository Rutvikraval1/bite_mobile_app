import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../data/repositories/recipe_comments_repository.dart';
import '../../domain/entities/recipe_comment.dart';

/// Social stats row (❤️ hearts · 🔖 saved · 💬 comments) + an expandable
/// comment panel backed by `public.recipe_comments`. Same look as
/// [SocialCommentsBlock], but comments are loaded from / saved to Supabase
/// and users can delete their own.
class RecipeCommentsBlock extends StatefulWidget {
  const RecipeCommentsBlock({
    super.key,
    required this.itemType,
    required this.itemId,
    required this.hearts,
    required this.saved,
    required this.initialCount,
    required this.accentColor,
    this.quickChips = const [],
    this.readOnly = false,
    this.repository,
  });

  /// `recipe` or `drink`.
  final String itemType;
  final int itemId;
  final String hearts;
  final String saved;

  /// `comments_count` from the card, shown until the real list loads.
  final int initialCount;
  final Color accentColor;
  final List<String> quickChips;

  /// Shows comments without the input box — used when the signed-in user
  /// views their own recipe.
  final bool readOnly;
  final RecipeCommentsRepository? repository;

  @override
  State<RecipeCommentsBlock> createState() => _RecipeCommentsBlockState();
}

class _RecipeCommentsBlockState extends State<RecipeCommentsBlock> {
  late final RecipeCommentsRepository _repo =
      widget.repository ?? RecipeCommentsRepository();
  final TextEditingController _controller = TextEditingController();

  bool _expanded = false;
  bool _loading = true;
  bool _posting = false;
  String? _error;
  List<RecipeComment> _comments = const [];
  String? _userId;
  String? _handle;
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RecipeCommentsBlock old) {
    super.didUpdateWidget(old);
    if (old.itemId != widget.itemId || old.itemType != widget.itemType) {
      _comments = const [];
      _loading = true;
      _error = null;
      _load();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      _userId = _repo.currentUserId;
      final comments = await _repo.fetch(widget.itemType, widget.itemId);
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[recipe-comments] load failed: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _isMissingTable(e)
            ? 'Comments are not set up on the server yet.'
            : "Couldn't load comments.";
      });
    }
  }

  Future<void> _post(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _posting) return;
    if (trimmed.length > 500) {
      ToastService.instance.show('⚠️ Comments can be up to 500 characters.');
      return;
    }
    final userId = _userId;
    if (userId == null) {
      ToastService.instance.show('⚠️ Sign in to comment.');
      return;
    }
    setState(() => _posting = true);
    try {
      final handle = _handle ??= await _repo.fetchMyHandle(userId);
      if (!mounted) return;
      if (handle == null) {
        setState(() => _posting = false);
        ToastService.instance.show(
          '⚠️ Pick a username in Edit Profile to comment.',
        );
        return;
      }
      final comment = await _repo.add(
        userId: userId,
        handle: handle,
        itemType: widget.itemType,
        itemId: widget.itemId,
        body: trimmed,
      );
      if (!mounted) return;
      setState(() {
        _comments = [comment, ..._comments];
        _posting = false;
        _error = null;
      });
      _controller.clear();
      ToastService.instance.show('💬 Comment posted!');
    } catch (e) {
      debugPrint('[recipe-comments] post failed: $e');
      if (!mounted) return;
      setState(() => _posting = false);
      ToastService.instance.show(
        _isMissingTable(e)
            ? '⚠️ Comments are not set up on the server yet.'
            : "⚠️ Couldn't post comment. Try again.",
      );
    }
  }

  /// True when the `recipe_comments` migration hasn't been applied.
  static bool _isMissingTable(Object e) =>
      e is PostgrestException && (e.code == 'PGRST205' || e.code == '42P01');

  /// Optimistic delete of the user's own comment; restored on failure.
  Future<void> _delete(RecipeComment c) async {
    final userId = _userId;
    if (userId == null || _deleting.contains(c.id)) return;
    final before = _comments;
    setState(() {
      _deleting.add(c.id);
      _comments = [
        for (final x in _comments)
          if (x.id != c.id) x,
      ];
    });
    try {
      await _repo.delete(userId, c.id);
      ToastService.instance.show('🗑 Comment deleted');
    } catch (e) {
      debugPrint('[recipe-comments] delete failed: $e');
      if (mounted) setState(() => _comments = before);
      ToastService.instance.show("⚠️ Couldn't delete comment. Try again.");
    } finally {
      if (mounted) setState(() => _deleting.remove(c.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Until the list loads, the card's stored count is the best we have.
    final count = _loading || _error != null
        ? widget.initialCount
        : _comments.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '❤️ ${widget.hearts}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(width: 12),
            Text(
              '🔖 ${widget.saved}',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
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
          SlideUp(duration: const Duration(milliseconds: 260), child: _panel()),
        ],
      ],
    );
  }

  Widget _pillContent(int count) {
    final color = _expanded ? widget.accentColor : AppColors.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chat_bubble_outline_rounded, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        AnimatedRotation(
          turns: _expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 300),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _panel() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (!widget.readOnly) _inputRow(),
          if (!widget.readOnly && widget.quickChips.isNotEmpty)
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Text(
                          chip,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          _body(),
        ],
      ),
    );
  }

  Widget _inputRow() {
    return Container(
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
                enabled: !_posting,
                maxLength: 500,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(color: AppColors.muted, fontSize: 12),
                  border: InputBorder.none,
                  isDense: true,
                  counterText: '',
                ),
                onSubmitted: _post,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final hasText = _controller.text.trim().isNotEmpty;
              return GestureDetector(
                onTap: hasText && !_posting
                    ? () => _post(_controller.text)
                    : null,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasText
                        ? AppColors.coral
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                  child: _posting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          size: 16,
                          color: hasText ? Colors.white : AppColors.muted,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.coral,
          ),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        child: Column(
          children: [
            Text(
              '⚠️ $_error',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: widget.accentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (_comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(14, 16, 14, 18),
        child: Text(
          'No comments yet — be the first! 💬',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _comments.length,
        itemBuilder: (context, i) => _commentRow(_comments[i], i),
      ),
    );
  }

  Widget _commentRow(RecipeComment c, int i) {
    final isYou = c.userId == _userId;
    final t = Formatters.timeAgo(c.createdAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: i > 0
            ? Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarImg(
            emoji: c.avatarEmoji,
            imageUrl: c.avatarUrl,
            size: 26,
            borderWidth: 0,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.authorHandle,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isYou ? AppColors.coral : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t == 'now' ? 'Just now' : t,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  c.body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (isYou)
            GestureDetector(
              onTap: () => _delete(c),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
