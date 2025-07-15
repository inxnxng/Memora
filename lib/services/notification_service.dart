import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final DarwinInitializationSettings initializationSettingsMacOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsMacOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
  }

  Future<void> scheduleDailyNotificationAtTime(int hour, int minute) async {
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Memora',
      '오늘의 기억력 훈련을 진행할 시간이에요! 🧠',
      _nextInstanceOfSelectedTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_notification_channel_id',
          'Daily Notifications',
          channelDescription: 'Daily notifications for memory training',
          // This is important for exact alarms on Android 12+
          // You might need to add `android:exported="true"` to your MainActivity in AndroidManifest.xml
          // if you encounter issues with notifications not showing.
          // For more details, refer to the flutter_local_notifications documentation.
          // https://pub.dev/packages/flutter_local_notifications#android-12-and-above
          // androidAllowWhileIdle: true, // This parameter is not directly available here.
        ),
        iOS: DarwinNotificationDetails(badgeNumber: 1),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(0);
  }

  tz.TZDateTime _nextInstanceOfSelectedTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<TimeOfDay?> getScheduledNotificationTime() async {
    final List<PendingNotificationRequest> pendingNotifications =
        await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    if (pendingNotifications.isNotEmpty) {
      final notification = pendingNotifications.firstWhere(
        (element) => element.id == 0,
        orElse: () => PendingNotificationRequest(0, '', '', null),
      );
      if (notification.payload != null) {
        // This part is tricky. The payload doesn't directly store the time.
        // We need to rely on the `matchDateTimeComponents: DateTimeComponents.time`
        // and assume the notification is scheduled for the next occurrence of that time.
        // For a more robust solution, we would save the time in shared preferences.
        // For now, we'll return null and let the UI default.
        return null;
      }
    }
    return null;
  }
}
