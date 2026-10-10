import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../../content/domain/entities/bite_card.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../data/chat_selection.dart';
import '../../domain/social_models.dart';
import '../blocs/chat_cubit.dart';
import '../blocs/social_feed_cubit.dart';
import '../social_navigation.dart';

/// Quick-reply chips above the composer.
const List<String> _quickReplies = ['Sounds great! 🙌', 'Friday works!', "Can't wait 🔥", 'Send recipe?'];

/// A single message bubble — either plain text or a shared-recipe card.
class _ThreadMessage {
  const _ThreadMessage({required this.from, this.text, this.recipe});

  final String from; // me | them
  final String? text;
  final BiteCard? recipe;
}

/// One-on-one / group / room chat thread — ports `ChatThreadScreen` from
/// `screens-social.jsx`.
///
/// The screen is instantiated with no constructor args by the router, so it
/// reads which conversation to render from [ChatSelection.instance] — set by
/// the chat list, a creator's "Message" button or a notification. Messages
/// are live via Realtime; typing and online state use broadcast/presence.
class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  ChatThreadRef? _thread = ChatSelection.instance.current;

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<ChatMessageItem> _messages = const [];
  bool _loading = true;
  bool _pending = false; // the user hasn't accepted this request yet
  bool _showMenu = false;
  String? _menuAction; // muted | blocked | reported
  bool _isTyping = false;
  bool _peerOnline = false;
  Timer? _typingTimer;
  Timer? _menuActionTimer;
  Timer? _readTimer;
  DateTime _lastTypingSent = DateTime(0);
  RealtimeChannel? _channel;

  late final ChatCubit _chat = context.read<ChatCubit>();
  String? get _myId => _chat.userId;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
    _open();
  }

  @override
  void dispose() {
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    _typingTimer?.cancel();
    _menuActionTimer?.cancel();
    _readTimer?.cancel();
    final ch = _channel;
    if (ch != null) _chat.repository.unsubscribe(ch);
    super.dispose();
  }

  Future<void> _open() async {
    final ref = _thread;
    final myId = _myId;
    if (ref == null || myId == null) {
      setState(() => _loading = false);
      return;
    }
    final repo = _chat.repository;
    try {
      if (ref.isRoom) {
        await _chat.joinRoom(ref.conversationId);
        if (ref.name.isEmpty) {
          final room = await repo.fetchRoom(ref.conversationId);
          if (room != null && mounted) {
            setState(() => _thread = ChatThreadRef(
                  conversationId: room.id,
                  name: room.name,
                  avatarLabel: room.emoji,
                  kind: room.kind,
                  subtitle: room.isKitchen ? 'Live Kitchen' : 'Group',
                ));
          }
        }
      } else {
        // Opened from a notification: fill in who this is with.
        final c = await repo.fetchConversation(myId, ref.conversationId);
        if (c != null && mounted) {
          setState(() {
            _pending = c.isRequest;
            if (ref.name.isEmpty || ref.peerUserId == null) {
              _thread = ChatThreadRef(
                conversationId: c.id,
                name: c.title,
                avatarLabel: c.isGroup ? c.emoji : (c.title.isEmpty ? '?' : c.title.characters.first.toUpperCase()),
                kind: c.kind,
                peerUserId: c.isGroup ? null : c.peer?.userId,
                peerHandle: c.isGroup ? null : c.peer?.handle,
                subtitle: c.isGroup ? 'Group' : null,
              );
            }
          });
        }
      }
      final messages = await repo.fetchMessages(ref.conversationId);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
      _jumpToBottom();
      _chat.markRead(ref.conversationId);
      _channel = repo.subscribeThread(
        conversationId: ref.conversationId,
        userId: myId,
        onMessage: _onIncoming,
        onTyping: (_) => _showTyping(),
        onPresence: (online) {
          final peer = _thread?.peerUserId;
          if (mounted) setState(() => _peerOnline = peer != null && online.contains(peer));
        },
      );
    } catch (e) {
      debugPrint('[chat] open failed: $e');
      if (!mounted) return;
      setState(() => _loading = false);
      ToastService.instance.show("⚠️ Couldn't load messages.");
    }
  }

  void _onIncoming(ChatMessageItem m) {
    if (!mounted || _messages.any((x) => x.id == m.id)) return;
    // Our own in-flight send echoes back — _send swaps in the saved row.
    final mine = m.senderId != null && m.senderId == _myId;
    if (mine && _messages.any((x) => x.pending && x.body == m.body)) return;
    setState(() {
      _messages = [..._messages, m];
      _isTyping = false;
    });
    _scrollToBottom();
    _readTimer?.cancel();
    _readTimer = Timer(const Duration(milliseconds: 800), () {
      final id = _thread?.conversationId;
      if (id != null) _chat.markRead(id);
    });
  }

  void _showTyping() {
    if (!mounted) return;
    setState(() => _isTyping = true);
    _scrollToBottom();
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isTyping = false);
    });
  }

  void _onInputChanged() {
    final ch = _channel;
    final myId = _myId;
    if (ch == null || myId == null || _input.text.trim().isEmpty) return;
    final now = DateTime.now();
    if (now.difference(_lastTypingSent) < const Duration(seconds: 2)) return;
    _lastTypingSent = now;
    _chat.repository.sendTyping(ch, myId);
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? text]) async {
    final value = (text ?? _input.text).trim();
    final ref = _thread;
    final myId = _myId;
    if (value.isEmpty || ref == null || myId == null) return;
    final temp = ChatMessageItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      conversationId: ref.conversationId,
      senderId: myId,
      body: value,
      createdAt: DateTime.now(),
      pending: true,
    );
    setState(() => _messages = [..._messages, temp]);
    _input.clear();
    _scrollToBottom();
    try {
      if (_pending) {
        // Replying to a request accepts it.
        await _chat.acceptRequest(ref.conversationId);
        _pending = false;
      }
      final sent = await _chat.repository.sendMessage(userId: myId, conversationId: ref.conversationId, body: value);
      if (!mounted) return;
      setState(() => _messages = [for (final m in _messages) m.id == temp.id ? sent : m]);
    } catch (e) {
      debugPrint('[chat] send failed: $e');
      if (!mounted) return;
      setState(() => _messages = [for (final m in _messages) if (m.id != temp.id) m]);
      if (_input.text.isEmpty) _input.text = value;
      final blocked = e.toString().contains('blocked');
      ToastService.instance.show(blocked ? "🚫 You can't message this person." : "⚠️ Message not sent. Try again.");
    }
  }

  void _flashMenuAction(String action, {bool autoClear = true}) {
    setState(() {
      _showMenu = false;
      _menuAction = action;
    });
    _menuActionTimer?.cancel();
    if (autoClear) {
      _menuActionTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _menuAction = null);
      });
    }
  }

  void _viewProfile() {
    setState(() => _showMenu = false);
    final handle = _thread?.peerHandle;
    if (handle == null) {
      ToastService.instance.show('👥 ${_thread?.name ?? 'This chat'} is a group');
      return;
    }
    openCreator(context, handle);
  }

  Future<void> _mute() async {
    final id = _thread?.conversationId;
    if (id == null) return;
    final ok = await _chat.setMuted(id, true);
    if (!mounted) return;
    if (ok) {
      _flashMenuAction('muted');
    } else {
      setState(() => _showMenu = false);
      ToastService.instance.show("⚠️ Couldn't mute. Try again.");
    }
  }

  Future<void> _block() async {
    final handle = _thread?.peerHandle;
    if (handle == null) {
      setState(() => _showMenu = false);
      ToastService.instance.show('👥 Groups can be muted, not blocked');
      return;
    }
    final ok = await context.read<SocialFeedCubit>().mute(handle, kind: 'block');
    if (!mounted) return;
    if (ok) {
      _flashMenuAction('blocked', autoClear: false);
    } else {
      setState(() => _showMenu = false);
      ToastService.instance.show("⚠️ Couldn't block. Try again.");
    }
  }

  Future<void> _undoBlock() async {
    final handle = _thread?.peerHandle;
    setState(() => _menuAction = null);
    if (handle != null) await context.read<SocialFeedCubit>().unmute(handle);
  }

  Future<void> _report() async {
    final id = _thread?.conversationId;
    if (id == null) return;
    final ok = await context.read<SocialFeedCubit>().report('conversation', id);
    if (!mounted) return;
    if (ok) {
      _flashMenuAction('reported');
    } else {
      setState(() => _showMenu = false);
      ToastService.instance.show("⚠️ Couldn't send report. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final myId = _myId;
    final content = context.watch<ContentCubit>().state;
    final messages = [
      for (final m in _messages)
        _ThreadMessage(
          from: m.senderId != null && m.senderId == myId ? 'me' : 'them',
          text: m.body,
          recipe: m.recipeId == null ? null : content.findCard(m.recipeId!),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral),
                          ),
                        )
                      : thread == null
                          ? const Center(
                              child: Text('Conversation not found', style: TextStyle(color: AppColors.muted)),
                            )
                          : messages.isEmpty && !_isTyping
                              ? Center(
                                  child: Text('Say hi to ${thread.name.split(' ').first} 👋',
                                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                                )
                              : ListView.builder(
                                  controller: _scroll,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  itemCount: messages.length + (_isTyping ? 1 : 0),
                                  itemBuilder: (context, i) {
                                    if (i == messages.length) return const _TypingBubble();
                                    return _MessageBubble(
                                      message: messages[i],
                                      onOpenRecipe: () => openRecipe(context, messages[i].recipe?.id),
                                    );
                                  },
                                ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in _quickReplies)
                        GestureDetector(
                          onTap: () => _input.text = r,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Text(r, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x0FFFFFFF)))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.glass,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _input,
                            onSubmitted: _send,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              hintText: 'Message ${(thread?.name ?? '').split(' ').first}...',
                              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Only the send button depends on the typed text — listen
                      // to the controller here instead of setState per keystroke.
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _input,
                        builder: (context, value, _) {
                          final hasText = value.text.trim().isNotEmpty;
                          return GestureDetector(
                            onTap: hasText ? () => _send() : null,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasText ? AppColors.coral : Colors.white.withValues(alpha: 0.08),
                              ),
                              child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_showMenu)
              Positioned(
                top: 60,
                right: 16,
                child: _ContextMenu(
                  items: [
                    ('👤 View Profile', _viewProfile, false),
                    ('🔇 Mute Conversation', _mute, false),
                    ('🚫 Block User', _block, false),
                    ('⚠️ Report', _report, true),
                  ],
                ),
              ),
            if (_menuAction != null)
              Positioned(
                top: 70,
                left: 20,
                right: 20,
                child: PopIn(
                  duration: const Duration(milliseconds: 250),
                  child: _ActionToast(
                    action: _menuAction!,
                    onUndo: _menuAction == 'blocked' ? _undoBlock : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.read<FlowCubit>().goBack(),
            child: const Icon(Icons.arrow_back_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [AppColors.cyan.withValues(alpha: 0.4), AppColors.coral.withValues(alpha: 0.4)]),
            ),
            alignment: Alignment.center,
            child: Text(_thread?.avatarLabel ?? '💬', style: const TextStyle(fontSize: 14, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_thread?.name ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    if (_peerOnline) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(_thread?.subtitle ?? (_peerOnline ? 'Online' : ''),
                        style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _viewProfile,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.person_outline_rounded, size: 18, color: AppColors.muted),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.call_outlined, size: 18, color: AppColors.muted),
          ),
          GestureDetector(
            onTap: () => setState(() => _showMenu = !_showMenu),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.onOpenRecipe});

  final _ThreadMessage message;
  final VoidCallback onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    final me = message.from == 'me';
    final recipe = message.recipe;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
        decoration: BoxDecoration(
          color: me ? AppColors.coral.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(me ? 16 : 4),
            bottomRight: Radius.circular(me ? 4 : 16),
          ),
          border: Border.all(color: me ? AppColors.coral.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: recipe != null ? _buildRecipe(recipe) : _buildText(),
      ),
    );
  }

  Widget _buildText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(message.text ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
    );
  }

  Widget _buildRecipe(BiteCard recipe) {
    return GestureDetector(
      onTap: onOpenRecipe,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(colors: [AppColors.coral.withValues(alpha: 0.27), AppColors.bgCard]),
              ),
              alignment: Alignment.center,
              child: Text(recipe.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(recipe.creator, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  Text('${recipe.time} · ${recipe.diff}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  const Text('View Recipe →', style: TextStyle(color: AppColors.coral, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SlideUp(
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var d = 0; d < 3; d++)
                Padding(
                  padding: EdgeInsets.only(left: d > 0 ? 4 : 0),
                  child: Pulse(
                    amount: 0.5,
                    duration: Duration(milliseconds: 1000 + d * 100),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.muted),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextMenu extends StatelessWidget {
  const _ContextMenu({required this.items});

  final List<(String label, VoidCallback action, bool danger)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 32)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            GestureDetector(
              onTap: items[i].$2,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  border: i < items.length - 1
                      ? const Border(bottom: BorderSide(color: Color(0x0AFFFFFF)))
                      : null,
                ),
                child: Text(items[i].$1,
                    style: TextStyle(
                        color: items[i].$3 ? AppColors.coral : Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionToast extends StatelessWidget {
  const _ActionToast({required this.action, this.onUndo});

  final String action;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final blocked = action == 'blocked';
    final label = switch (action) {
      'muted' => '🔇 Conversation muted',
      'blocked' => '🚫 User blocked — undo?',
      _ => '⚠️ Report submitted. Thank you.',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: blocked ? AppColors.coral.withValues(alpha: 0.13) : const Color(0x1F4CAF50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blocked ? AppColors.coral.withValues(alpha: 0.27) : const Color(0x4D4CAF50)),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                  color: blocked ? AppColors.coral : const Color(0xFF4CAF50), fontSize: 13, fontWeight: FontWeight.w600)),
          if (onUndo != null)
            GestureDetector(
              onTap: onUndo,
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Undo', style: TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}
