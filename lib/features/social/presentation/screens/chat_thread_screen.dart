import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/animations/loops.dart';
import '../../data/chat_selection.dart';
import '../../data/mock_social_data.dart';

/// A single message bubble — either plain text or a shared-recipe card.
class _ThreadMessage {
  const _ThreadMessage({required this.from, this.text, this.recipe});

  final String from; // me | them
  final String? text;
  final ChatMessage? recipe;
}

/// One-on-one / group / kitchen chat thread — ports `ChatThreadScreen` from
/// `screens-social.jsx`.
///
/// The screen is instantiated with no constructor args by the router, so it
/// reads which thread to render from [ChatSelection.instance] — set by
/// whichever row in [ChatListScreen] was tapped.
class ChatThreadScreen extends StatefulWidget {
  const ChatThreadScreen({super.key});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  late final ChatThreadRef _thread = ChatSelection.instance.current;

  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_ThreadMessage> _sent = [];
  bool _showMenu = false;
  String? _menuAction; // muted | blocked | reported
  bool _isTyping = false;
  Timer? _typingTimer;
  Timer? _replyTimer;
  Timer? _menuActionTimer;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _typingTimer?.cancel();
    _replyTimer?.cancel();
    _menuActionTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send([String? text]) {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    setState(() {
      _sent.add(_ThreadMessage(from: 'me', text: value));
      _input.clear();
    });
    _scrollToBottom();
    _typingTimer?.cancel();
    _replyTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isTyping = true);
      _scrollToBottom();
    });
    _replyTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final reply = mockThreadReplies[_sent.length % mockThreadReplies.length];
      setState(() {
        _isTyping = false;
        _sent.add(_ThreadMessage(from: 'them', text: reply));
      });
      _scrollToBottom();
    });
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

  @override
  Widget build(BuildContext context) {
    final messages = [
      for (final m in mockThreadMessages) _ThreadMessage(from: m.from, text: m.text, recipe: m.isRecipe ? m : null),
      ..._sent,
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
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == messages.length) return const _TypingBubble();
                      return _MessageBubble(
                        message: messages[i],
                        onOpenRecipe: () => context.read<FlowCubit>().setScreen(AppScreen.recipeDetail),
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
                      for (final r in mockThreadQuickReplies)
                        GestureDetector(
                          onTap: () => setState(() => _input.text = r),
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
                            onChanged: (_) => setState(() {}),
                            onSubmitted: _send,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              hintText: 'Message ${_thread.name.split(' ').first}...',
                              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _input.text.trim().isNotEmpty ? () => _send() : null,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _input.text.trim().isNotEmpty ? AppColors.coral : Colors.white.withValues(alpha: 0.08),
                          ),
                          child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        ),
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
                    ('👤 View Profile', () {
                      setState(() => _showMenu = false);
                      context.read<FlowCubit>().setScreen(AppScreen.creatorProfile);
                    }, false),
                    ('🔇 Mute Conversation', () => _flashMenuAction('muted'), false),
                    ('🚫 Block User', () => _flashMenuAction('blocked', autoClear: false), false),
                    ('⚠️ Report', () => _flashMenuAction('reported'), true),
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
                    onUndo: _menuAction == 'blocked' ? () => setState(() => _menuAction = null) : null,
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
            child: Text(_thread.avatarLabel, style: const TextStyle(fontSize: 14, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_thread.name,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Row(
                  children: [
                    if (_thread.online) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(_thread.subtitle ?? (_thread.online ? 'Online' : ''),
                        style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.read<FlowCubit>().setScreen(AppScreen.creatorProfile),
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

  Widget _buildRecipe(ChatMessage recipe) {
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
              child: Text(recipe.recipeEmoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.recipeTitle ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(recipe.recipeCreator ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                  Text(recipe.recipeMeta ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
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
