import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../features/notifications/data/notification_repository.dart';
import '../config/app_env.dart';
import 'toast_service.dart';

/// Payload handed to the app when a push is tapped.
typedef PushOpenHandler =
    void Function(String? actionDest, Map<String, dynamic> data);

/// Background messages are shown by the OS; nothing to do here, but FCM
/// requires a registered top-level handler.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {}

/// Firebase Cloud Messaging wrapper: init, permission, token registration
/// (`device_tokens` table), foreground toasts and tap routing.
///
/// Config comes from `.env` (`FIREBASE_*`). If those are blank it falls back
/// to `google-services.json` / `GoogleService-Info.plist`. If neither is
/// present push is disabled and the rest of the app keeps working.
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  bool _ready = false;
  bool get isReady => _ready;

  String? _token;
  String? _userId;
  NotificationRepository? _repository;
  final List<StreamSubscription<dynamic>> _subs = [];

  /// Call once at startup, before [runApp].
  Future<void> init() async {
    try {
      final options = _optionsFromEnv();
      if (options != null) {
        await Firebase.initializeApp(options: options);
      } else {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      _ready = true;
      debugPrint('[bite] Firebase ready — push enabled');
    } catch (e) {
      debugPrint('[bite] Firebase not configured — push disabled: $e');
    }
  }

  /// Registers this device for [userId] and starts listening for pushes.
  Future<void> attach({
    required String userId,
    required NotificationRepository repository,
    required PushOpenHandler onOpen,
    VoidCallback? onForegroundMessage,
  }) async {
    if (!_ready || _userId == userId) return;
    await detach();
    _userId = userId;
    _repository = repository;
    final messaging = FirebaseMessaging.instance;
    try {
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // The APNs token must exist before an FCM token can be issued.
        await messaging.getAPNSToken();
      }
      final token = await messaging.getToken();
      // Debug only: copy this into Firebase console → Messaging → "Send test
      // message" to check delivery to this device.
      if (kDebugMode) debugPrint('[bite] FCM token: $token');
      if (token != null) await _saveToken(token);

      _subs
        ..add(messaging.onTokenRefresh.listen(_saveToken))
        ..add(
          FirebaseMessaging.onMessage.listen((m) {
            final n = m.notification;
            if (n != null) {
              ToastService.instance.show(
                [n.title, n.body].whereType<String>().join(' — '),
              );
            }
            onForegroundMessage?.call();
          }),
        )
        ..add(
          FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m, onOpen)),
        );

      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(initial, onOpen);
    } catch (e) {
      debugPrint('[bite] push attach failed: $e');
    }
  }

  /// Unregisters this device (sign-out).
  Future<void> detach() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final token = _token;
    final repo = _repository;
    _token = null;
    _userId = null;
    _repository = null;
    if (token != null && repo != null) {
      try {
        await repo.deleteDeviceToken(token);
      } catch (e) {
        debugPrint('[bite] deleteDeviceToken failed: $e');
      }
    }
  }

  Future<void> _saveToken(String token) async {
    final userId = _userId;
    final repo = _repository;
    if (userId == null || repo == null) return;
    _token = token;
    try {
      await repo.saveDeviceToken(userId, token, defaultTargetPlatform.name);
    } catch (e) {
      debugPrint('[bite] saveDeviceToken failed: $e');
    }
  }

  void _open(RemoteMessage m, PushOpenHandler onOpen) {
    final dest = m.data['action_dest'] as String?;
    final raw = m.data['payload'];
    Map<String, dynamic> data = const {};
    if (raw is String && raw.isNotEmpty) {
      try {
        data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    onOpen(dest == null || dest.isEmpty ? null : dest, data);
  }

  static FirebaseOptions? _optionsFromEnv() {
    final projectId = AppEnv.firebaseProjectId;
    final senderId = AppEnv.firebaseMessagingSenderId;
    if (projectId.isEmpty || senderId.isEmpty) return null;
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final apiKey = isIos
        ? AppEnv.firebaseIosApiKey
        : AppEnv.firebaseAndroidApiKey;
    final appId = isIos ? AppEnv.firebaseIosAppId : AppEnv.firebaseAndroidAppId;
    if (apiKey.isEmpty || appId.isEmpty) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      storageBucket: AppEnv.firebaseStorageBucket.isEmpty
          ? null
          : AppEnv.firebaseStorageBucket,
      iosBundleId: isIos && AppEnv.firebaseIosBundleId.isNotEmpty
          ? AppEnv.firebaseIosBundleId
          : null,
    );
  }
}
