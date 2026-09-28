import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/router/app_screen.dart';
import '../../../../core/router/flow_cubit.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/animations/entrance.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../../core/widgets/avatar_img.dart';
import '../../../../core/widgets/floating_pill_nav.dart';
import '../../../../core/widgets/glass.dart';
import '../../data/chat_selection.dart';
import '../../data/mock_social_data.dart';

/// Messages hub — ports `ChatListScreen` from `screens-social.jsx`.
/// Reachable via the bottom [FloatingPillNav]; renders full-screen leaving
/// room for it.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _activeTab = 'messages';
  final Set<int> _requestDismissed = {};
  String _groupTier = 'foodies';

  void _openThread(ChatThreadRef ref) {
    ChatSelection.instance.select(ref);
    context.read<FlowCubit>().setScreen(AppScreen.chatThread);
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = mockChats.where((c) => c.unread).length;
    final requestCount = mockChatRequests.length - _requestDismissed.length;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Messages',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        GestureDetector(
                          onTap: () => ToastService.instance.show('✏️ New conversation...'),
                          child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.glass,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded, size: 16, color: AppColors.muted),
                          SizedBox(width: 10),
                          Text('Search conversations...', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _TabButton(
                            label: 'Messages ($unreadCount)',
                            selected: _activeTab == 'messages',
                            onTap: () => setState(() => _activeTab = 'messages'),
                          ),
                          _TabButton(
                            label: 'Groups',
                            selected: _activeTab == 'groups',
                            onTap: () => setState(() => _activeTab = 'groups'),
                          ),
                          _TabButton(
                            label: 'Requests ($requestCount)',
                            selected: _activeTab == 'requests',
                            onTap: () => setState(() => _activeTab = 'requests'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_activeTab == 'groups') _buildGroupsTab(),
                  if (_activeTab == 'messages') _buildMessagesTab(),
                  if (_activeTab == 'requests') _buildRequestsTab(),
                ],
              ),
            ),
          ),
          const FloatingPillNav(),
        ],
      ),
    );
  }

  Widget _buildMessagesTab() {
    return Column(
      children: [
        for (var i = 0; i < mockChats.length; i++)
          ZoomIn(
            duration: Duration(milliseconds: 220 + i * 25),
            child: _ChatRow(
              chat: mockChats[i],
              onTap: () {
                final chat = mockChats[i];
                if (chat.isGenie) {
                  context.read<FlowCubit>().setScreen(AppScreen.genieChat);
                  return;
                }
                _openThread(ChatThreadRef(name: chat.name, avatarLabel: chat.name[0].toUpperCase()));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    final visible = [
      for (var i = 0; i < mockChatRequests.length; i++)
        if (!_requestDismissed.contains(i)) i,
    ];
    if (visible.isEmpty) {
      return const EmptyState(
        emoji: '📭',
        title: 'No pending requests',
        message: '',
        compact: true,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Messages from people you don't follow. Accept to start chatting.",
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
          ),
          for (final i in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ZoomIn(
                duration: Duration(milliseconds: 220 + i * 40),
                child: _RequestCard(
                  request: mockChatRequests[i],
                  onAccept: () => _openThread(
                    ChatThreadRef(name: mockChatRequests[i].name, avatarLabel: mockChatRequests[i].name[0]),
                  ),
                  onDecline: () => setState(() => _requestDismissed.add(i)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    final groups = mockCommunityGroups[_groupTier] ?? const [];
    final tierColor = switch (_groupTier) {
      'creators' => AppColors.cyan,
      'critics' => AppColors.amber,
      _ => AppColors.coral,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                _GroupTierButton(id: 'foodies', label: '🍽 Foodies', color: AppColors.coral, selected: _groupTier == 'foodies', onTap: () => setState(() => _groupTier = 'foodies')),
                _GroupTierButton(id: 'creators', label: '⭐ Creators', color: AppColors.cyan, selected: _groupTier == 'creators', onTap: () => setState(() => _groupTier = 'creators')),
                _GroupTierButton(id: 'critics', label: '🌶 Critics', color: AppColors.amber, selected: _groupTier == 'critics', onTap: () => setState(() => _groupTier = 'critics')),
              ],
            ),
          ),
          const Text('🔥 LIVE KITCHENS',
              style: TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mockLiveKitchens.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final k = mockLiveKitchens[i];
                return ZoomIn(
                  duration: Duration(milliseconds: 220 + i * 60),
                  child: GestureDetector(
                    onTap: () {
                      _openThread(ChatThreadRef(name: k.name, avatarLabel: k.emoji, isGenie: false, subtitle: 'Live Kitchen'));
                      ToastService.instance.show('Entering ${k.name}...');
                    },
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: k.color.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: k.color.withValues(alpha: 0.13)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(k.emoji, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(k.active,
                                    style: TextStyle(
                                        color: k.isLive ? const Color(0xFF4CAF50) : AppColors.muted,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(k.name,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          Text('${k.members} members', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text('💬 COMMUNITIES',
              style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          for (var i = 0; i < groups.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Opacity(
                opacity: groups[i].unlock == 'Sous Chef' ? 0.5 : 1,
                child: ZoomIn(
                  duration: Duration(milliseconds: 220 + i * 40),
                  child: Glass(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(14),
                    onTap: () {
                      if (groups[i].unlock == 'Sous Chef') {
                        ToastService.instance.show('🔒 Reach Sous Chef to unlock this room');
                        return;
                      }
                      _openThread(ChatThreadRef(name: groups[i].name, avatarLabel: groups[i].emoji, subtitle: 'Group'));
                      ToastService.instance.show('Joined ${groups[i].name}!');
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: tierColor.withValues(alpha: 0.13)),
                          ),
                          alignment: Alignment.center,
                          child: Text(groups[i].emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(groups[i].name,
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  if (groups[i].unlock != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: groups[i].unlock == 'Sous Chef'
                                            ? Colors.white.withValues(alpha: 0.06)
                                            : AppColors.amber.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        groups[i].unlock == 'Sous Chef' ? '🔒 Sous Chef' : '✓ ${groups[i].unlock}',
                                        style: TextStyle(
                                            color: groups[i].unlock == 'Sous Chef' ? AppColors.muted : AppColors.amber,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(groups[i].desc,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(groups[i].members, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                            if (groups[i].newCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: AppColors.coral.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(100)),
                                child: Text('${groups[i].newCount} new',
                                    style: const TextStyle(color: AppColors.coral, fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Text('👨‍👩‍👧‍👦 MY GROUPS',
                style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ),
          for (var i = 0; i < mockMyGroups.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ZoomIn(
                duration: Duration(milliseconds: 220 + i * 60),
                child: Glass(
                  borderRadius: 14,
                  padding: const EdgeInsets.all(14),
                  onTap: () {
                    _openThread(ChatThreadRef(name: mockMyGroups[i].name, avatarLabel: mockMyGroups[i].emoji, subtitle: 'Group'));
                    ToastService.instance.show('Opening ${mockMyGroups[i].name}...');
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0x1F4CAF50),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x404CAF50)),
                        ),
                        alignment: Alignment.center,
                        child: Text(mockMyGroups[i].emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mockMyGroups[i].name,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                            Text(mockMyGroups[i].lastMsg, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${mockMyGroups[i].members} members', style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                          Text(mockMyGroups[i].time, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          GestureDetector(
            onTap: () => ToastService.instance.show('✨ Create a new group...'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.only(top: 4, bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.27)),
              ),
              child: const Text('+ Create New Group',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.coral : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupTierButton extends StatelessWidget {
  const _GroupTierButton({
    required this.id,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.13) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(color: selected ? color : AppColors.muted, fontWeight: FontWeight.w600, fontSize: 11)),
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.chat, required this.onTap});

  final ChatPreview chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: chat.isGenie ? AppColors.amber.withValues(alpha: 0.04) : null,
          border: Border(
            bottom: const BorderSide(color: Color(0x0AFFFFFF)),
            left: BorderSide(color: chat.isGenie ? AppColors.amber.withValues(alpha: 0.5) : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          children: [
            if (chat.unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.coral),
              ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: chat.isGenie
                    ? const RadialGradient(colors: [AppColors.amber, AppColors.coral])
                    : LinearGradient(colors: [AppColors.cyan.withValues(alpha: 0.27), AppColors.coral.withValues(alpha: 0.27)]),
              ),
              alignment: Alignment.center,
              child: Text(chat.isGenie ? '🧞' : chat.name[0],
                  style: TextStyle(fontSize: chat.isGenie ? 18 : 16, color: Colors.white)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(chat.name,
                      style: TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: chat.unread ? FontWeight.w700 : FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(chat.preview,
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
            Text(chat.time, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onAccept, required this.onDecline});

  final ChatRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Glass(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.coral.withValues(alpha: 0.27), AppColors.amber.withValues(alpha: 0.27)]),
                ),
                clipBehavior: Clip.antiAlias,
                child: AvatarImg(emoji: request.avatarEmoji, size: 40, borderWidth: 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    if (request.mutual != null)
                      Text('🔗 ${request.mutual}', style: const TextStyle(color: AppColors.amber, fontSize: 11)),
                  ],
                ),
              ),
              Text(request.time, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('"${request.preview}"', style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4)),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(100)),
                    child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onDecline,
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: const Text('Decline', style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w500, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
