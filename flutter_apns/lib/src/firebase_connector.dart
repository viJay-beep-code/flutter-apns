import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import 'connector.dart';

class FirebasePushConnector implements PushConnector {
  final ValueNotifier<bool?> _isDisabledByUser = ValueNotifier<bool?>(null);
  final ValueNotifier<String?> _token = ValueNotifier<String?>(null);
  final String _providerType = 'GCM';

  @override
  ValueNotifier<bool?> get isDisabledByUser => _isDisabledByUser;

  @override
  ValueNotifier<String?> get token => _token;

  @override
  String get providerType => _providerType;

  @override
  Future<void> configure({
    MessageHandler? onMessage,
    MessageHandler? onLaunch,
    MessageHandler? onResume,
    MessageHandler? onBackgroundMessage,
    FirebaseOptions? options,
  }) async {
    if (options != null) {
      await Firebase.initializeApp(options: options);
    }

    // Set up message handlers
    if (onMessage != null) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        onMessage(message);
      });
    }

    if (onLaunch != null) {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        onLaunch(message);
      });
    }

    if (onResume != null) {
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        onResume(message);
      });
    }

    if (onBackgroundMessage != null) {
      FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
    }

    // Get initial message if app was opened from notification
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null && onLaunch != null) {
      onLaunch(initialMessage);
    }

    // Get token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      _token.value = token;
    }

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
      _token.value = newToken;
    });
  }

  @override
  void requestNotificationPermissions() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    _isDisabledByUser.value =
        settings.authorizationStatus == AuthorizationStatus.denied;
  }

  @override
  Future<void> unregister() async {
    await FirebaseMessaging.instance.deleteToken();
    _token.value = null;
  }

  @override
  void dispose() {
    _isDisabledByUser.dispose();
    _token.dispose();
  }
}
