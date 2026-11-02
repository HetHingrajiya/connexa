import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/routing/app_router.dart';
import 'package:connexa/features/notifications/services/notification_service.dart';
import 'package:connexa/firebase_options.dart';

/// Top-level background message handler required by Firebase Cloud Messaging.
/// Must be an entry-point function outside any class.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (_) {
        await Firebase.initializeApp();
      }
    }
  } catch (_) {
    // Ignore initialization failure in background isolate if credentials missing
  }
}

/// Global provider for [FcmPushService].
final Provider<FcmPushService> fcmPushServiceProvider =
    Provider<FcmPushService>((Ref ref) {
      final NotificationService notifService = ref.watch(
        notificationServiceProvider,
      );
      return FcmPushService(notifService);
    });

/// Service managing Firebase Cloud Messaging push notifications, device tokens,
/// permissions, foreground/background handlers, and deep-link navigation.
class FcmPushService {
  FcmPushService(this._notificationService);

  final NotificationService _notificationService;

  static bool _isInitialized = false;
  static bool _isFirebaseAvailable = false;
  static String? _currentToken;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static final Set<String> _processedMessageIds = <String>{};

  /// Whether the current runtime platform supports Firebase Cloud Messaging.
  static bool get isPlatformSupported {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Whether Firebase is available and initialized.
  static bool get isFirebaseAvailable => _isFirebaseAvailable;

  /// Currently active FCM token if registered.
  static String? get currentToken => _currentToken;

  /// Safely initializes Firebase and FCM listeners at application boot.
  /// Never crashes the app if Firebase configuration is missing or on unsupported platforms.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (!isPlatformSupported) {
      debugPrint('FCM: Unsupported platform (${kIsWeb ? 'web' : 'desktop'}). Push notifications disabled.');
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (_) {
          await Firebase.initializeApp();
        }
      }
      _isFirebaseAvailable = true;
      debugPrint('FCM: Firebase initialized successfully for connexa-d17f6.');

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for background notification tap that brings app to foreground
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for terminated-state notification tap
      final RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      _isFirebaseAvailable = false;
      debugPrint('FCM: Firebase initialization skipped or unconfigured ($e). Running in in-app notification mode.');
    }
  }

  /// Requests notification permissions and registers the FCM device token with Connexa API.
  Future<bool> registerDeviceToken() async {
    if (!_isFirebaseAvailable || !isPlatformSupported) {
      return false;
    }

    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Request notification permissions on iOS/Android 13+
      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final bool isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (!isAuthorized) {
        debugPrint('FCM: Notification permissions not granted (${settings.authorizationStatus}).');
        return false;
      }

      final String platform = kIsWeb
          ? 'web'
          : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'mobile'));

      // Listen for token generation and rotation events
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onRegistered.listen((
        String newToken,
      ) async {
        if (newToken.isNotEmpty && newToken != _currentToken) {
          _currentToken = newToken;
          await _notificationService.registerDeviceToken(
            newToken,
            platform: platform,
          );
          debugPrint('FCM: Device token registered / refreshed via onRegistered.');
        }
      });

      // Trigger FCM app instance registration
      try {
        await messaging.register();
      } catch (_) {}

      // Retrieve device token with fallback for initial sync
      // ignore: deprecated_member_use
      final String? token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('FCM: Token retrieval deferred until onRegistered event.');
        return true;
      }

      _currentToken = token;
      final bool registered = await _notificationService.registerDeviceToken(
        token,
        platform: platform,
      );

      if (registered) {
        debugPrint('FCM: Device token registered with backend successfully.');
      }

      return registered;
    } catch (e) {
      debugPrint('FCM: Failed to register device token: $e');
      return false;
    }
  }

  /// Unregisters the current device token from Connexa API upon member logout.
  Future<bool> unregisterCurrentDeviceToken() async {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    final String? token = _currentToken;
    if (token == null || token.isEmpty) {
      return true;
    }

    try {
      final bool removed = await _notificationService.unregisterDeviceToken(
        token,
      );
      _currentToken = null;
      debugPrint('FCM: Device token removed on logout.');
      return removed;
    } catch (e) {
      debugPrint('FCM: Failed to unregister device token on logout: $e');
      _currentToken = null;
      return false;
    }
  }

  /// Handles incoming push notifications while the app is in foreground.
  static void _handleForegroundMessage(RemoteMessage message) {
    if (_isDuplicateMessage(message)) return;

    debugPrint(
      'FCM Foreground Message: ${message.notification?.title} - ${message.notification?.body}',
    );

    // Context-sensitive in-app handling if navigator context is available
    final BuildContext? context = rootNavigatorKey.currentContext;
    if (context != null && message.notification != null) {
      final String title = message.notification!.title ?? 'New Notification';
      final String body = message.notification!.body ?? '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (body.isNotEmpty)
                Text(
                  body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () => handleNotificationNavigation(message.data),
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Handles user tapping a notification from system notification drawer.
  static void _handleMessageOpenedApp(RemoteMessage message) {
    if (_isDuplicateMessage(message)) return;

    debugPrint('FCM Notification Tapped: ${message.data}');
    handleNotificationNavigation(message.data);
  }

  /// Navigates to the appropriate screen using payload reference information.
  static void handleNotificationNavigation(Map<String, dynamic> data) {
    final String? refType = data['referenceType']?.toString().toLowerCase();
    final String? refId = data['referenceId']?.toString();
    final String? eventType = data['eventType']?.toString();

    final BuildContext? context = rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('FCM Navigation: Navigator context unavailable.');
      return;
    }

    if (refType == 'connection') {
      if (eventType == 'ConnectionRequestReceived') {
        context.push('/network?tab=1'); // Pending requests tab
      } else {
        context.push('/network?tab=0'); // My connections tab
      }
    } else if (refType == 'inquiry') {
      if (refId != null && refId.isNotEmpty && refId != '0') {
        context.push('/inquiries/$refId');
      } else {
        context.push('/inquiries');
      }
    } else if (refType == 'product') {
      if (refId != null && refId.isNotEmpty && refId != '0') {
        context.push('/products/$refId');
      } else {
        context.push('/products');
      }
    } else if (refType == 'verification') {
      context.push('/profile/verification');
    } else if (refType == 'rfq') {
      if (refId != null && refId.isNotEmpty && refId != '0') {
        context.push('/rfqs/$refId');
      } else {
        context.push('/rfqs');
      }
    } else if (refType == 'order') {
      if (refId != null && refId.isNotEmpty && refId != '0') {
        context.push('/orders/$refId');
      } else {
        context.push('/orders');
      }
    } else {
      context.push('/notifications');
    }
  }

  /// Deduplicates messages based on messageId to prevent duplicate banner/actions.
  static bool _isDuplicateMessage(RemoteMessage message) {
    final String? id = message.messageId;
    if (id == null || id.isEmpty) return false;

    if (_processedMessageIds.contains(id)) {
      return true;
    }

    _processedMessageIds.add(id);
    if (_processedMessageIds.length > 100) {
      _processedMessageIds.remove(_processedMessageIds.first);
    }
    return false;
  }
}
