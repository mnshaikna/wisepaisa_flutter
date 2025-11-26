import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

enum RepeatType { none, daily, weekly, monthly }

class NotificationService {
  static final NotificationService _instance = NotificationService._();

  factory NotificationService() => _instance;

  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      // onDidReceiveLocalNotification is optional for older iOS versions
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> scheduleDailyReminder({
    required tz.TZDateTime dateTime,
    required int id,
    required RepeatType repeatType,
  }) async {
    final androidPlugin =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      final allowed = await androidPlugin.areNotificationsEnabled();
      if (!allowed!) await androidPlugin.requestExactAlarmsPermission();

      await androidPlugin.requestNotificationsPermission();
    }
    cancelAll();

    await _plugin.zonedSchedule(
      id,
      'Log Your Spending',
      'Track it today, manage it tomorrow! Log your expenses.',
      dateTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Channel for daily reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: 'Track it today, manage it tomorrow! Log your expenses.',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          repeatType == RepeatType.none
              ? null
              : repeatType == RepeatType.daily
              ? DateTimeComponents.time
              : repeatType == RepeatType.weekly
              ? DateTimeComponents.dayOfWeekAndTime
              : repeatType == RepeatType.monthly
              ? DateTimeComponents.dayOfMonthAndTime
              : null,
    );
  }
}
