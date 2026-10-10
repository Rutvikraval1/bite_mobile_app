/// Lightweight description of "who this chat thread is with" — enough for
/// [ChatThreadScreen] to render its header before the conversation loads.
class ChatThreadRef {
  const ChatThreadRef({
    required this.conversationId,
    required this.name,
    required this.avatarLabel,
    this.kind = 'dm',
    this.peerUserId,
    this.peerHandle,
    this.subtitle,
  });

  final String conversationId;
  final String name;
  final String avatarLabel;

  /// dm | group | community | kitchen
  final String kind;
  final String? peerUserId;
  final String? peerHandle;
  final String? subtitle;

  bool get isRoom => kind == 'community' || kind == 'kitchen';
}

/// Holds which chat thread was most recently opened so [ChatThreadScreen]
/// — instantiated with no constructor args by the router — knows which
/// conversation to load. Set by the chat list, creator profile "Message"
/// and notification taps.
class ChatSelection {
  ChatSelection._();

  static final ChatSelection instance = ChatSelection._();

  ChatThreadRef? current;

  void select(ChatThreadRef ref) {
    current = ref;
  }
}

/// Holds which creator [CreatorProfileScreen] should show — set wherever a
/// creator avatar / handle / card is tapped before navigating there.
class CreatorSelection {
  CreatorSelection._();

  static final CreatorSelection instance = CreatorSelection._();

  String? handle;

  void select(String handle) {
    this.handle = handle;
  }
}
