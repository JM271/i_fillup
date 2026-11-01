import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'water_repository.dart';
import 'texts.dart';

/// Push notifications tell hosts about new refill requests. The message is
/// sent by the notifyHostOfRequest Cloud Function in functions/index.js.
///
/// Uses FCM registration tokens, which the function sends to with
/// sendEachForMulticast; the newer installation-ID API needs a matching
/// server-side send, so the token API is kept on purpose.
// ignore_for_file: deprecated_member_use
class PushNotifications {
  static WaterRepository? _registered;
  static StreamSubscription<String>? _tokenRefresh;

  static bool get supported =>
      !kIsWeb &&
      Firebase.apps.isNotEmpty &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Asks for permission once and stores this device's push address.
  static Future<void> enable(WaterRepository repository) async {
    if (repository.isDemo || !supported || _registered != null) return;
    _registered = repository;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null) await repository.savePushToken(token);
      _tokenRefresh = messaging.onTokenRefresh.listen(repository.savePushToken);
    } catch (error) {
      debugPrint('Push notifications unavailable: $error');
    }
  }

  /// Stops notifications to this device; call before signing out.
  static Future<void> disable() async {
    final repository = _registered;
    _registered = null;
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;
    if (repository == null || !supported) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await repository.removePushToken(token);
    } catch (error) {
      debugPrint('Could not remove push address: $error');
    }
  }

  /// [onRequest] runs with the notification text while the app is open;
  /// [onOpen] runs when the user taps a notification.
  static List<StreamSubscription<RemoteMessage>> listen({
    required void Function(String text) onRequest,
    required VoidCallback onOpen,
  }) {
    if (!supported) return const [];
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) onOpen();
    });
    return [
      FirebaseMessaging.onMessage.listen(
        (message) =>
            onRequest(message.notification?.body ?? tr.newRefillRequest),
      ),
      FirebaseMessaging.onMessageOpenedApp.listen((_) => onOpen()),
    ];
  }
}
