import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(initSettings);

    // Create a default channel for Android 8.0+
    const AndroidNotificationChannel defaultChannel = AndroidNotificationChannel(
      'default_channel_id',
      'General',
      description: 'General notifications',
      importance: Importance.high,
    );
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(defaultChannel);

    // Request permissions on iOS
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request notifications permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showSuccess({required String title, required String body}) async {
    if (!_initialized) {
      if (kDebugMode) {
        // In debug builds try to self-init to avoid missing calls.
        await init();
      } else {
        return;
      }
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel_id',
      'General',
      channelDescription: 'General notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );

    // Also show an in-app banner for quick feedback while app is open
    _showInAppBanner(title: title, body: body);
  }

  void _showInAppBanner({required String title, required String body}) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.hideCurrentMaterialBanner();
    final banner = MaterialBanner(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: const Icon(Icons.check_circle, color: Colors.green),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(body),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => messenger.hideCurrentMaterialBanner(),
          child: const Text('DISMISS'),
        ),
      ],
      backgroundColor: Colors.white,
    );
    messenger.showMaterialBanner(banner);
    Future.delayed(const Duration(seconds: 3), () {
      final current = scaffoldMessengerKey.currentState;
      current?.hideCurrentMaterialBanner();
    });
  }
}


