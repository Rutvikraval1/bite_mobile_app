import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/genie_chat_data.dart';

/// Genie's full-screen chat — a locally-mocked "AI" conversation. Ports
/// `GenieChatScreen` from `screens-genie.jsx`. There is no chat-message
/// table or LLM backend, so replies are canned/keyword-matched with a
/// simulated typing delay to preserve the illusion of a live assistant.
class GenieChatScreen extends StatefulWidget {
  const GenieChatScreen({super.key});

  @override
  State<GenieChatScreen> createState() => _GenieChatScreenState();
}

class _GenieChatScreenState extends State<GenieChatScreen> {
  final List<GenieChatMessage> _messages = List.of(GenieChatData.seedMessages);
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _typing = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add(GenieChatMessage(fromUser: true, text: trimmed));
      _inputController.clear();
      _typing = true;
    });
    _scrollToBottom();
    final reply = GenieChatData.replyFor(trimmed);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(GenieChatMessage(fromUser: false, text: reply));
      });
      _scrollToBottom();
    });
  }

  void _sendQuickReply(String chip, int index) {
    setState(() {
      _messages.add(GenieChatMessage(fromUser: true, text: chip));
      _typing = true;
    });
    _scrollToBottom();
    final reply = GenieChatData.replyForQuickReply(chip, index);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _messages.add(GenieChatMessage(fromUser: false, text: reply));
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<FlowCubit>();
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(flow),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  for (final m in _messages) _ChatBubble(message: m),
                  SizedBox(
                    height: 138,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: GenieChatData.suggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final s = GenieChatData.suggestions[i];
                        return Glass(
                          borderRadius: 14,
                          padding: const EdgeInsets.all(14),
                          onTap: () => flow.setScreen(AppScreen.recipeDetail),
                          child: SizedBox(
                            width: 150,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                      colors: [
                                        s.color.withValues(alpha: 0.2),
                                        AppColors.bgCard,
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    s.emoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  s.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${s.time} · ${s.difficulty}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _GenieBubble(text: GenieChatData.followUp),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (
                        var i = 0;
                        i < GenieChatData.quickReplies.length;
                        i++
                      )
                        _QuickReplyChip(
                          label: GenieChatData.quickReplies[i],
                          onTap: () =>
                              _sendQuickReply(GenieChatData.quickReplies[i], i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_typing) const _TypingIndicator(),
                ],
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(FlowCubit flow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: flow.goBack,
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [AppColors.amber, AppColors.coral],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.amber.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🧞 Food Genie',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    _OnlineDot(),
                    SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ToastService.instance.show('⚙️ More options...'),
            child: const Icon(
              Icons.more_horiz,
              color: AppColors.muted,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                ToastService.instance.show('📸 Opening camera for scan...'),
            child: const Icon(
              Icons.camera_alt,
              color: AppColors.cyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.glass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Center(
                child: TextField(
                  controller: _inputController,
                  onSubmitted: _send,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ask Genie anything...',
                    hintStyle: TextStyle(color: AppColors.muted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _send(_inputController.text),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.saveGreen,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final GenieChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: message.fromUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: message.fromUser
            ? _bubble(
                text: message.text,
                bg: Colors.white.withValues(alpha: 0.08),
                border: AppColors.glassBorder,
                radius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
              )
            : _bubble(
                text: message.text,
                bg: AppColors.amber.withValues(alpha: 0.08),
                border: AppColors.amber.withValues(alpha: 0.15),
                radius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
              ),
      ),
    );
  }

  Widget _bubble({
    required String text,
    required Color bg,
    required Color border,
    required BorderRadius radius,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(color: border),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _GenieBubble extends StatelessWidget {
  const _GenieBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.15)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _dot(i),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dot(int i) {
    final t = (_controller.value + i * 0.2) % 1.0;
    final opacity = 0.4 + 0.6 * (0.5 - (t - 0.5).abs()) * 2;
    return Opacity(
      opacity: opacity.clamp(0.3, 1.0),
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: AppColors.amber,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
