import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/content/domain/entities/bite_card.dart';
import '../config/app_config.dart';
import '../config/app_env.dart';

/// What a share is about — drives the copy and the link.
enum ShareKind { recipe, place, creator, cook, app }

/// Something the user can share (recipe, place, creator profile, a finished
/// cook, or the app itself) — enough to render the share sheet preview and
/// build the outgoing message + link.
@immutable
class ShareTarget {
  const ShareTarget({
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.emoji = '🌶',
    this.imageUrl,
    this.stat,
    this.recipeId,
    this.handle,
  });

  factory ShareTarget.card(BiteCard card) => ShareTarget(
        kind: card.isPlace ? ShareKind.place : ShareKind.recipe,
        title: card.title,
        subtitle: card.isPlace
            ? [card.cuisine, if (card.address != null) card.address!].where((s) => s.isNotEmpty).join(' · ')
            : 'by ${card.creator} · ${card.time}',
        emoji: card.emoji,
        imageUrl: card.image,
        stat: card.isPlace ? (card.rating == null ? null : '⭐ ${card.rating}') : '❤️ ${card.hearts}',
        recipeId: card.isPlace ? null : card.id,
      );

  factory ShareTarget.app() => const ShareTarget(
        kind: ShareKind.app,
        title: 'b🌶te',
        subtitle: 'Swipe, cook & share recipes with friends',
      );

  final ShareKind kind;
  final String title;
  final String subtitle;
  final String emoji;
  final String? imageUrl;

  /// Short right-aligned stat in the preview, e.g. "❤️ 2.4K".
  final String? stat;

  /// Set for catalog recipes — attached to chat messages / feed posts so they
  /// render as a recipe card.
  final int? recipeId;

  /// Creator handle (with `@`) for [ShareKind.creator].
  final String? handle;

  /// App link for this target, built on the configured `INVITE_URL` (the
  /// same link Settings → Invite uses). Empty when it isn't configured.
  String get link => ShareService.linkFor(this);

  /// The outgoing message (text + link).
  String get message {
    final app = AppConfig.appName;
    final text = switch (kind) {
      ShareKind.recipe => '$emoji $title ${subtitle.isEmpty ? '' : '($subtitle) '}— found it on $app',
      ShareKind.place => '📍 $title${subtitle.isEmpty ? '' : ' · $subtitle'} — found it on $app',
      ShareKind.creator => '👩‍🍳 Check out $title${handle == null ? '' : ' ($handle)'} on $app',
      ShareKind.cook => '🔥 I just cooked $title on $app!',
      ShareKind.app => 'Join me on $app 🌶',
    };
    final url = link;
    return url.isEmpty ? text : '$text $url';
  }

  /// Subject line for email-style share targets.
  String get subject => switch (kind) {
        ShareKind.app => 'Join me on ${AppConfig.appName}',
        _ => '$title on ${AppConfig.appName}',
      };
}

/// Hands the [ShareTarget] to `ShareActionSheet`, which the router builds
/// with no constructor args. Set right before navigating to
/// `AppScreen.shareSheet`; the sheet consumes it once.
class ShareSelection {
  ShareSelection._();

  static final ShareSelection instance = ShareSelection._();

  ShareTarget? _pending;

  void select(ShareTarget target) => _pending = target;

  ShareTarget? take() {
    final t = _pending;
    _pending = null;
    return t;
  }
}

/// Native share + app deep links (WhatsApp, SMS, Instagram) + clipboard.
abstract final class ShareService {
  /// [AppEnv.inviteUrl] with a query param pointing at [target]
  /// (`?recipe=12`, `?creator=chefpriya`, `?ref=challenge`).
  static String linkFor(ShareTarget target, {String? ref}) {
    final base = AppEnv.inviteUrl.trim();
    if (base.isEmpty) return '';
    final uri = Uri.tryParse(base);
    if (uri == null) return base;
    final params = <String, String>{
      ...uri.queryParameters,
      if (target.recipeId != null) 'recipe': '${target.recipeId}',
      if (target.kind == ShareKind.creator && target.handle != null)
        'creator': target.handle!.replaceFirst('@', ''),
      'ref': ?ref,
    };
    return (params.isEmpty ? uri : uri.replace(queryParameters: params)).toString();
  }

  /// Anchor rect for the iPad share popover, from the tapped widget.
  static Rect? originOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Opens the OS share sheet. Returns true unless the user dismissed it or
  /// sharing failed.
  static Future<bool> shareNative({
    required String text,
    String? subject,
    Rect? origin,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
      );
      return result.status != ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('[share] native share failed: $e');
      return false;
    }
  }

  /// WhatsApp with [text] prefilled; falls back to wa.me in the browser.
  static Future<bool> openWhatsApp(String text) async {
    final encoded = Uri.encodeComponent(text);
    if (await _launch(Uri.parse('whatsapp://send?text=$encoded'))) return true;
    return _launch(Uri.parse('https://wa.me/?text=$encoded'));
  }

  /// The SMS composer with [text] prefilled.
  static Future<bool> openSms(String text) {
    final encoded = Uri.encodeComponent(text);
    // iOS expects `sms:&body=`, Android `sms:?body=`.
    final sep = defaultTargetPlatform == TargetPlatform.iOS ? '&' : '?';
    return _launch(Uri.parse('sms:${sep}body=$encoded'));
  }

  /// Opens the Instagram app (it doesn't accept prefilled text).
  static Future<bool> openInstagram() => _launch(Uri.parse('instagram://app'));

  static Future<void> copy(String text) => Clipboard.setData(ClipboardData(text: text));

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[share] launch $uri failed: $e');
      return false;
    }
  }
}
