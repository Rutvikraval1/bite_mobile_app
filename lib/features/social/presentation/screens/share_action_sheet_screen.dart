import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/badge_service.dart';
import '../../../../core/services/share_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/state/app_state_cubit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../auth/presentation/blocs/auth_cubit.dart';
import '../../../content/presentation/blocs/content_cubit.dart';
import '../../domain/social_models.dart';
import '../blocs/chat_cubit.dart';
import '../blocs/social_feed_cubit.dart';

/// Share destination pill definition.
class _ShareDest {
  const _ShareDest(this.id, this.icon, this.label, this.color);

  final String id;
  final String icon;
  final String label;
  final Color color;
}

const _dChat = _ShareDest('chat', '💬', 'b🌶te Chat', AppColors.coral);
const _dRoom = _ShareDest('room', '👨‍👩‍👧‍👦', 'Send to Kitchen', AppColors.cyan);
const _dFeed = _ShareDest('feed', '📸', 'Post to Feed', AppColors.amber);
const _dSms = _ShareDest('sms', '📱', 'Message', Colors.white);
const _dCopy = _ShareDest('copy', '🔗', 'Copy Link', AppColors.cyan);
const _dInstagram = _ShareDest('instagram', '📷', 'Instagram', Color(0xFFE1306C));
const _dWhatsApp = _ShareDest('whatsapp', '💬', 'WhatsApp', Color(0xFF25D366));
const _dMore = _ShareDest('more', '•••', 'More', Colors.white);

const List<Color> _avatarTints = [
  AppColors.cyan,
  AppColors.amber,
  AppColors.coral,
  AppColors.placesPurple,
  AppColors.drinksBlue,
];

/// A chat the item can be sent to — a DM/group or a joined room.
class _ChatDest {
  const _ChatDest({required this.id, required this.name, required this.emoji, this.avatarUrl, this.subtitle = ''});

  factory _ChatDest.conversation(ChatConversation c) => _ChatDest(
        id: c.id,
        name: c.title,
        emoji: c.isGroup ? c.emoji : (c.peer?.avatarEmoji ?? c.emoji),
        avatarUrl: c.isGroup ? null : c.peer?.avatarUrl,
        subtitle: c.isGroup ? 'Group' : (c.peer?.handle ?? ''),
      );

  factory _ChatDest.room(ChatRoom r) => _ChatDest(
        id: r.id,
        name: r.name,
        emoji: r.emoji,
        subtitle: r.isKitchen ? (r.isLive ? '🔴 Live kitchen' : 'Kitchen') : 'Community',
      );

  final String id;
  final String name;
  final String emoji;
  final String? avatarUrl;
  final String subtitle;
}

/// Share bottom sheet — ports `ShareActionSheet` from `screens-social.jsx`.
///
/// Reached via `AppScreen.shareSheet`. What's shared comes from
/// [ShareSelection] (set by the caller); otherwise the recipe/place the user
/// came from, otherwise an app invite. Destinations are real: in-app chat
/// messages and feed posts go through Supabase, WhatsApp / Messages /
/// Instagram open the app via deep link, More opens the OS share sheet.
class ShareActionSheet extends StatefulWidget {
  const ShareActionSheet({super.key});

  @override
  State<ShareActionSheet> createState() => _ShareActionSheetState();
}

class _ShareActionSheetState extends State<ShareActionSheet> {
  late final ShareTarget _target = _resolveTarget();
  String? _sent;
  bool _sharing = false;
  Timer? _closeTimer;

  ShareTarget _resolveTarget() {
    final picked = ShareSelection.instance.take();
    if (picked != null) return picked;
    final from = context.read<FlowCubit>().state.previous;
    if (from == AppScreen.recipeDetail) {
      final card = context.read<AppStateCubit>().state.selectedRecipe;
      if (card != null) return ShareTarget.card(card);
    }
    if (from == AppScreen.placeDetail) {
      final places = context.read<ContentCubit>().state.places;
      if (places.isNotEmpty) {
        final i = context.read<AppStateCubit>().state.activeCardIndex;
        return ShareTarget.card(places[i % places.length]);
      }
    }
    return ShareTarget.app();
  }

  bool get _canPost =>
      _target.recipeId != null && (_target.kind == ShareKind.recipe || _target.kind == ShareKind.cook);

  List<_ShareDest> get _destinations => [
        _dChat,
        _dRoom,
        if (_canPost) _dFeed,
        _dSms,
        _dCopy,
        _dInstagram,
        _dWhatsApp,
        _dMore,
      ];

  @override
  void initState() {
    super.initState();
    // Make sure the quick-send row has fresh conversations.
    final chat = context.read<ChatCubit>();
    if (chat.userId != null && chat.state.conversations.isEmpty) unawaited(chat.refresh());
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  void _goBack() {
    if (mounted) context.read<FlowCubit>().goBack();
  }

  /// Marks [dest] as done, awards the share badge and closes shortly after.
  void _done(String dest, String toast, {bool close = true}) {
    if (!mounted) return;
    ToastService.instance.show(toast);
    BadgeService.instance.award(const ['first_share']);
    setState(() {
      _sent = dest;
      _sharing = false;
    });
    if (close) {
      _closeTimer?.cancel();
      _closeTimer = Timer(const Duration(milliseconds: 1200), _goBack);
    }
  }

  void _idle() {
    if (mounted) setState(() => _sharing = false);
  }

  Future<void> _handleShare(_ShareDest dest, Rect? origin) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final text = _target.message;
    switch (dest.id) {
      case 'chat':
        _idle();
        await _pickAndSend(rooms: false);
      case 'room':
        _idle();
        await _pickAndSend(rooms: true);
      case 'feed':
        await _postToFeed();
      case 'sms':
        if (await ShareService.openSms(text)) {
          _done(dest.label, '📱 Opening Messages…', close: false);
        } else {
          await _native(dest.label, origin);
        }
      case 'copy':
        final link = _target.link;
        await ShareService.copy(link.isEmpty ? text : link);
        _done(dest.label, link.isEmpty ? '📋 Copied to clipboard!' : '🔗 Link copied!', close: false);
      case 'instagram':
        // Instagram can't take prefilled text — copy the caption first.
        await ShareService.copy(text);
        if (await ShareService.openInstagram()) {
          _done(dest.label, '📋 Caption copied — paste it in Instagram', close: false);
        } else {
          await _native(dest.label, origin);
        }
      case 'whatsapp':
        if (await ShareService.openWhatsApp(text)) {
          _done(dest.label, '💬 Opening WhatsApp…', close: false);
        } else {
          await _native(dest.label, origin);
        }
      default:
        await _native(dest.label, origin);
    }
  }

  Future<void> _native(String dest, Rect? origin) async {
    final ok = await ShareService.shareNative(text: _target.message, subject: _target.subject, origin: origin);
    if (ok) {
      _done(dest, '📤 Shared!');
    } else {
      _idle();
    }
  }

  Future<void> _postToFeed() async {
    final feed = context.read<SocialFeedCubit>();
    final caption = _target.kind == ShareKind.cook ? 'Just cooked this! 🔥' : 'Recommending this one 🌶';
    final post = await feed.sharePost(caption: caption, dishTitle: _target.title, recipeId: _target.recipeId);
    if (!mounted) return;
    if (post == null) {
      _idle();
      if (context.read<AuthCubit>().state.user == null) ToastService.instance.show('🔒 Sign in to post to the feed');
      return;
    }
    _done(_dFeed.label, '📸 Posted to your feed!', close: false);
    context.read<FlowCubit>().setScreen(AppScreen.socialFeed);
  }

  /// Lets the user pick a DM/group ([rooms] false) or a joined room, then
  /// sends the item there.
  Future<void> _pickAndSend({required bool rooms}) async {
    final chat = context.read<ChatCubit>();
    if (chat.userId == null) {
      ToastService.instance.show('🔒 Sign in to send in chat');
      return;
    }
    if (chat.state.loading || (rooms ? chat.state.rooms.isEmpty : chat.state.conversations.isEmpty)) {
      await chat.refresh();
      if (!mounted) return;
    }
    final dests = rooms ? _roomDests(chat.state) : _conversationDests(chat.state);
    if (dests.isEmpty) {
      ToastService.instance.show(rooms
          ? '👨‍👩‍👧‍👦 Join a Live Kitchen or community in Chat first'
          : '💬 No chats yet — start one from a creator profile or Chat');
      context.read<FlowCubit>().setScreen(AppScreen.chatList);
      return;
    }
    final picked = await showModalBottomSheet<_ChatDest>(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _ChatPicker(title: rooms ? 'Send to a room' : 'Send in b🌶te Chat', dests: dests),
    );
    if (picked == null || !mounted) return;
    await _sendTo(picked, dest: rooms ? _dRoom.label : _dChat.label);
  }

  List<_ChatDest> _conversationDests(ChatState s) => [
        for (final c in [...s.conversations.where((c) => !c.isRequest)]..sort((a, b) => b.sortTime.compareTo(a.sortTime)))
          _ChatDest.conversation(c),
      ];

  List<_ChatDest> _roomDests(ChatState s) => [
        for (final r in [...s.kitchens, ...s.rooms.where((r) => !r.isKitchen)])
          if (s.joinedRooms.containsKey(r.id)) _ChatDest.room(r),
      ];

  Future<void> _sendTo(_ChatDest to, {String? dest}) async {
    if (_sharing) return;
    final chat = context.read<ChatCubit>();
    final userId = chat.userId;
    if (userId == null) {
      ToastService.instance.show('🔒 Sign in to send in chat');
      return;
    }
    setState(() => _sharing = true);
    try {
      await chat.repository.sendMessage(
        userId: userId,
        conversationId: to.id,
        body: _target.message,
        recipeId: _target.recipeId,
      );
      unawaited(chat.refresh());
      _done(dest ?? to.name, '📨 Sent to ${to.name}!');
    } catch (e) {
      debugPrint('[share] chat send failed: $e');
      _idle();
      ToastService.instance.show(e.toString().contains('blocked')
          ? "🚫 You can't message ${to.name}."
          : '⚠️ Message not sent. Try again.');
    }
  }

  Future<void> _invite(Rect? origin) async {
    final link = ShareService.linkFor(ShareTarget.app(), ref: 'invite');
    if (link.isEmpty) {
      ToastService.instance.show('Invite link not configured');
      return;
    }
    final ok = await ShareService.shareNative(
      text: 'Join me on ${AppConfig.appName} 🌶 $link',
      subject: ShareTarget.app().subject,
      origin: origin,
    );
    if (ok) BadgeService.instance.award(const ['first_share']);
  }

  @override
  Widget build(BuildContext context) {
    final t = _target;
    final quickSend = context.select<ChatCubit, List<_ChatDest>>(
      (c) => _conversationDests(c.state).take(5).toList(),
    );
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      body: GestureDetector(
        onTap: _goBack,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: SlideUp(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                decoration: const BoxDecoration(
                  color: AppColors.bgDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 20),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF)))),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(colors: [AppColors.coral.withValues(alpha: 0.27), AppColors.bgCard]),
                              ),
                              alignment: Alignment.center,
                              child: t.imageUrl != null
                                  ? AppNetworkImage(
                                      t.imageUrl!,
                                      width: 48,
                                      height: 48,
                                      errorBuilder: (_) => Text(t.emoji, style: const TextStyle(fontSize: 22)),
                                    )
                                  : Text(t.emoji, style: const TextStyle(fontSize: 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                  if (t.subtitle.isNotEmpty)
                                    Text(t.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                            if (t.stat != null) Text(t.stat!, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('SHARE TO',
                              style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                      ),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        runSpacing: 12,
                        children: [
                          for (final d in _destinations)
                            Builder(
                              builder: (btnContext) => _DestButton(
                                dest: d,
                                sent: _sent == d.label,
                                onTap: () => _handleShare(d, ShareService.originOf(btnContext)),
                              ),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.only(top: 16),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x0FFFFFFF)))),
                        child: Column(
                          children: [
                            Builder(
                              builder: (btnContext) => GestureDetector(
                                onTap: () => _invite(ShareService.originOf(btnContext)),
                                child: Container(
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.coral.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.2)),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_alt_rounded, size: 18, color: AppColors.coral),
                                      SizedBox(width: 8),
                                      Text('Invite a Friend to b🌶te',
                                          style: TextStyle(color: AppColors.coral, fontSize: 14, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (quickSend.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 16),
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x0FFFFFFF)))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('QUICK SEND',
                                  style:
                                      TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  for (final (i, p) in quickSend.indexed)
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _sendTo(p),
                                        behavior: HitTestBehavior.opaque,
                                        child: Column(
                                          children: [
                                            _sent == p.name
                                                ? Container(
                                                    width: 44,
                                                    height: 44,
                                                    alignment: Alignment.center,
                                                    decoration: const BoxDecoration(
                                                        shape: BoxShape.circle, color: Color(0x264CAF50)),
                                                    child: const Text('✓', style: TextStyle(color: Color(0xFF4CAF50))),
                                                  )
                                                : p.avatarUrl != null
                                                    ? AvatarImg(emoji: p.emoji, imageUrl: p.avatarUrl, size: 44, borderWidth: 0)
                                                    : Container(
                                                        width: 44,
                                                        height: 44,
                                                        decoration: BoxDecoration(
                                                          shape: BoxShape.circle,
                                                          gradient: LinearGradient(colors: [
                                                            _avatarTints[i % _avatarTints.length].withValues(alpha: 0.27),
                                                            AppColors.bgCard
                                                          ]),
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: Text(p.emoji, style: const TextStyle(fontSize: 18)),
                                                      ),
                                            const SizedBox(height: 4),
                                            Text(p.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  for (var i = quickSend.length; i < 5; i++) const Spacer(),
                                ],
                              ),
                            ],
                          ),
                        ),
                      GestureDetector(
                        onTap: _goBack,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Text('Cancel', style: TextStyle(color: AppColors.muted, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatPicker extends StatelessWidget {
  const _ChatPicker({required this.title, required this.dests});

  final String title;
  final List<_ChatDest> dests;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: dests.length,
                itemBuilder: (_, i) {
                  final d = dests[i];
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(d),
                    leading: AvatarImg(emoji: d.emoji, imageUrl: d.avatarUrl, size: 40, borderWidth: 0),
                    title: Text(d.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: d.subtitle.isEmpty
                        ? null
                        : Text(d.subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    trailing: const Icon(Icons.send_rounded, size: 18, color: AppColors.coral),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestButton extends StatelessWidget {
  const _DestButton({required this.dest, required this.sent, required this.onTap});

  final _ShareDest dest;
  final bool sent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sent ? const Color(0x264CAF50) : AppColors.glass,
                border: Border.all(color: sent ? const Color(0xFF4CAF50) : dest.color.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: Text(sent ? '✓' : dest.icon, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 6),
            Text(dest.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(color: sent ? const Color(0xFF4CAF50) : AppColors.muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
