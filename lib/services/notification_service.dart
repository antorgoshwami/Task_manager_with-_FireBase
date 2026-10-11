import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Runs in a separate isolate when a message arrives while the app is in the
/// background or terminated. Must be a top-level function.
///
/// * Messages with a `notification` payload are displayed by the OS/Firebase
///   automatically - nothing to do.
/// * Data-only messages are NOT displayed automatically, so we show a local
///   notification ourselves.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('BG message: ${message.messageId}');
  if (message.notification == null && message.data.isNotEmpty) {
    await NotificationService.instance.initLocal();
    await NotificationService.instance.showLocal(message);
  }
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  bool _localReady = false;
  StreamSubscription<String>? _tokenSub;

  /// The task ID of a tapped notification. TaskListScreen listens to this and
  /// opens the task. Because it is a ValueNotifier, a tap that happens before
  /// the UI exists (cold start) is still delivered once the list screen shows.
  final ValueNotifier<String?> tappedTaskId = ValueNotifier<String?>(null);

  // flutter_local_notifications has no web or Windows implementation. FCM
  // works in web builds, but this plugin cannot display foreground messages
  // there.
  bool get _supportsLocalNotifications =>
      !kIsWeb &&
      switch (defaultTargetPlatform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.macOS => true,
        _ => false,
      };

  // One Android channel per priority (bonus: different notification by priority)
  static final Map<String, AndroidNotificationChannel> _channels = {
    'high': const AndroidNotificationChannel(
      'high_priority_tasks',
      'High Priority Tasks',
      description: 'Urgent task notifications',
      importance: Importance.max,
    ),
    'medium': const AndroidNotificationChannel(
      'medium_priority_tasks',
      'Medium Priority Tasks',
      description: 'Normal task notifications',
      importance: Importance.defaultImportance,
    ),
    'low': const AndroidNotificationChannel(
      'low_priority_tasks',
      'Low Priority Tasks',
      description: 'Low priority task notifications',
      importance: Importance.low,
    ),
  };

  // ---------------------------------------------------------------------------
  // Setup
  // ---------------------------------------------------------------------------

  Future<void> initLocal() async {
    if (_localReady) return;
    if (!_supportsLocalNotifications) {
      _localReady = true;
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false, // permission is requested via FCM
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios, macOS: ios),
      // Called when the user taps a LOCAL notification (foreground case)
      onDidReceiveNotificationResponse: (response) =>
          _setTapped(response.payload),
    );

    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    for (final channel in _channels.values) {
      await androidImpl?.createNotificationChannel(channel);
    }
    _localReady = true;
  }

  Future<void> init() async {
    await initLocal();
    if (!_supportsMessaging) return;

    // Android 13+ and iOS runtime permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // We show our own local notification in the foreground, so stop iOS from
    // also presenting the FCM one (avoids duplicates).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // 1) FOREGROUND: FCM does not show anything -> create a local notification
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 2) BACKGROUND: user taps the system notification
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTapped);

    // 3) TERMINATED: app was launched by tapping a notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onMessageTapped(initial);
  }

  // ---------------------------------------------------------------------------
  // FCM token
  // ---------------------------------------------------------------------------

  Future<String?> getToken() async {
    if (!_supportsMessaging) return null;
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Could not get FCM token: $e');
      return null;
    }
  }

  /// Saves the device token to users/{uid} so a server / Cloud Function can
  /// target this user. Also keeps it updated when the token refreshes.
  Future<void> saveTokenForUser(String uid, {String? email}) async {
    if (!_supportsMessaging) return;
    final token = await getToken();
    debugPrint('FCM TOKEN: $token');
    if (token != null) await _writeToken(uid, token, email);

    await _tokenSub?.cancel();
    _tokenSub =
        _messaging.onTokenRefresh.listen((t) => _writeToken(uid, t, email));
  }

  Future<void> _writeToken(String uid, String token, String? email) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmToken': token,
      'email': email,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message: ${message.notification?.title}');
    await showLocal(message);
  }

  void _onMessageTapped(RemoteMessage message) =>
      _setTapped(message.data['taskId'] as String?);

  void _setTapped(String? taskId) {
    if (taskId != null && taskId.isNotEmpty) tappedTaskId.value = taskId;
  }

  /// Builds and shows a local notification from an FCM message.
  Future<void> showLocal(RemoteMessage message) async {
    if (!_supportsLocalNotifications) return;
    final title =
        message.notification?.title ?? message.data['title'] ?? 'New Task';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    final priority =
        (message.data['priority'] ?? 'medium').toString().toLowerCase();
    final channel = _channels[priority] ?? _channels['medium']!;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: switch (priority) {
          'high' => Priority.max,
          'low' => Priority.low,
          _ => Priority.defaultPriority,
        },
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31), // 32-bit id
      title,
      body,
      details,
      payload: message.data['taskId'], // delivered back on tap
    );
  }

  bool get _supportsMessaging =>
      kIsWeb ||
      switch (defaultTargetPlatform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.macOS => true,
        _ => false,
      };
}
