import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();

    // 2. Android Initialization Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // 3. General Initialization Settings
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // 4. Initialize Plugin
    await _notificationsPlugin.initialize(initializationSettings);

    // 5. Request Android 13+ permissions
    if (!kIsWeb) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    }
  }

  /// Schedules a local notification for an upcoming installment.
  ///
  /// [notificationsEnabled] — pass `AppSettings.notificationsEnabled` to skip if disabled.
  /// [leadDays] — how many days before [scheduledDate] to send the reminder (default: 1).
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    bool notificationsEnabled = true,
    int leadDays = 1,
  }) async {
    if (kIsWeb) return;
    if (!notificationsEnabled) return; // Respect user preference

    // Schedule `leadDays` before the payment date at 9:00 AM
    final notificationDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day - leadDays,
      9,
      0,
    );

    // If scheduled time is already in the past, skip
    if (notificationDate.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzDate = tz.TZDateTime.from(notificationDate, tz.local);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'installment_reminders',
      'Installment Reminders',
      channelDescription: 'Notifications for upcoming installment payments',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Displays a notification locally when an FCM message is received.
  static Future<void> showFcmNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'installment_reminders',
        'Installment Reminders',
        channelDescription: 'Notifications for upcoming installment payments',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
      );
    }
  }

  /// Cancels a single scheduled notification by ID.
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(id);
  }

  /// Cancels all scheduled notifications for a deleted installment.
  static Future<void> cancelNotificationsForInstallment(
      int baseId, int installmentCount) async {
    if (kIsWeb) return;
    for (int i = 0; i < installmentCount; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
  }
}
