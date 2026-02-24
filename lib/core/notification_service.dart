import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Top-level handler for notification taps when app is in background/terminated.
/// Must be a top-level function (not a class method) for background isolate.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  debugPrint('Background notification tapped: ${response.payload}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Foreground notification tapped: ${response.payload}');
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    _initialized = true;

    await requestPermissions();
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
    } catch (_) {
      try {
        final timezoneName = await FlutterTimezone.getLocalTimezone();
        final mapped = _timezoneMapping[timezoneName];
        if (mapped != null) {
          tz.setLocalLocation(tz.getLocation(mapped));
        } else {
          final offset = DateTime.now().timeZoneOffset;
          final hours = offset.inHours;
          final knownByOffset = _offsetToTimezone[hours];
          if (knownByOffset != null) {
            tz.setLocalLocation(tz.getLocation(knownByOffset));
          }
        }
      } catch (_) {}
    }
  }

  static const _timezoneMapping = <String, String>{
    'Asia/Calcutta': 'Asia/Kolkata',
    'Asia/Saigon': 'Asia/Ho_Chi_Minh',
    'Asia/Katmandu': 'Asia/Kathmandu',
    'Pacific/Ponape': 'Pacific/Pohnpei',
    'Pacific/Truk': 'Pacific/Chuuk',
    'America/Buenos_Aires': 'America/Argentina/Buenos_Aires',
    'America/Indianapolis': 'America/Indiana/Indianapolis',
    'America/Knox_IN': 'America/Indiana/Knox',
    'Asia/Rangoon': 'Asia/Yangon',
    'Europe/Kiev': 'Europe/Kyiv',
    'Pacific/Samoa': 'Pacific/Pago_Pago',
  };

  static const _offsetToTimezone = <int, String>{
    -12: 'Pacific/Wake',
    -11: 'Pacific/Pago_Pago',
    -10: 'Pacific/Honolulu',
    -9: 'America/Anchorage',
    -8: 'America/Los_Angeles',
    -7: 'America/Denver',
    -6: 'America/Chicago',
    -5: 'America/New_York',
    -4: 'America/Halifax',
    -3: 'America/Sao_Paulo',
    -2: 'Atlantic/South_Georgia',
    -1: 'Atlantic/Azores',
    0: 'Europe/London',
    1: 'Europe/Paris',
    2: 'Europe/Berlin',
    3: 'Europe/Moscow',
    4: 'Asia/Dubai',
    5: 'Asia/Karachi',
    6: 'Asia/Dhaka',
    7: 'Asia/Bangkok',
    8: 'Asia/Shanghai',
    9: 'Asia/Tokyo',
    10: 'Australia/Sydney',
    11: 'Pacific/Noumea',
    12: 'Pacific/Auckland',
    13: 'Pacific/Tongatapu',
  };

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    }
  }

  Future<void> scheduleHabitReminder({
    required String habitId,
    required String habitName,
    required String timeStr,
  }) async {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final notificationId = habitId.hashCode.abs() % 1000000;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      notificationId,
      'HabitFlow Reminder',
      'Time for: $habitName',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(String habitId) async {
    final notificationId = habitId.hashCode.abs() % 10000000;
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
