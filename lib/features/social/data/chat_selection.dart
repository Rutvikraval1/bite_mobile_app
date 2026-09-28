/// Lightweight description of "who this chat thread is with" — enough for
/// [ChatThreadScreen] to render its header.
class ChatThreadRef {
  const ChatThreadRef({
    required this.name,
    required this.avatarLabel,
    this.online = true,
    this.isGenie = false,
    this.subtitle,
  });

  final String name;
  final String avatarLabel;
  final bool online;
  final bool isGenie;
  final String? subtitle;
}

/// Holds which chat thread [ChatListScreen] most recently opened so
/// [ChatThreadScreen] — instantiated with no constructor args by the router
/// — knows who it's rendering.
///
/// This mirrors the JS prototype's single always-the-same demo thread
/// ("Sarah Chen") faithfully while still letting different rows in
/// [ChatListScreen] (DMs, live kitchens, groups) each open the thread wearing
/// their own name/avatar. A plain static singleton is enough here — the
/// value is read once when [ChatThreadScreen] is built after navigation, and
/// nothing needs to observe it reactively.
class ChatSelection {
  ChatSelection._();

  static final ChatSelection instance = ChatSelection._();

  ChatThreadRef current = const ChatThreadRef(name: 'Sarah Chen', avatarLabel: 'S');

  void select(ChatThreadRef ref) {
    current = ref;
  }
}
