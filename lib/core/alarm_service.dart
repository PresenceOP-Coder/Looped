import 'dart:isolate';
import 'dart:async';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart' as permission;

import '../features/habits/domain/habit_model.dart';
import 'constants.dart';

Future<void> _showAlarmNotification(
    String habitName, int notificationId) async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings);

  const stopAction = AndroidNotificationAction(
    'STOP_ALARM',
    'Stop alarm',
    showsUserInterface: false,
  );

  const androidDetails = AndroidNotificationDetails(
    'habit_alarm_channel',
    'Habit Alarms',
    channelDescription: 'Alarm notifications for habit deadlines',
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    playSound: true,
    enableVibration: true,
    ongoing: true,
    autoCancel: false,
    icon: '@mipmap/ic_launcher',
    timeoutAfter: 60000,
    actions: [stopAction],
  );

  const details = NotificationDetails(android: androidDetails);

  await plugin.show(
    notificationId,
    'HabitFlow Alarm',
    'Deadline reached for: $habitName',
    details,
    payload: habitName,
  );
}

Future<void> _rescheduleAlarmForTomorrow(int id, int expectedGen) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final currentGen = prefs.getInt('alarm_gen_$id') ?? 0;
    if (currentGen != expectedGen) {
      return;
    }

    final deadlineTime = prefs.getString('alarm_deadline_time_$id');
    final habitId = prefs.getString('alarm_habit_id_$id');
    final habitName = prefs.getString('alarm_habit_name_$id');

    if (deadlineTime != null && habitId != null && habitName != null) {
      final parts = deadlineTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final nextAlarm =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);

      await AndroidAlarmManager.oneShotAt(
        nextAlarm,
        id,
        alarmCallback,
        exact: true,
        wakeup: true,
        alarmClock: true,
        rescheduleOnReboot: true,
      );
    }
  } catch (e) {
    debugPrint('Failed to reschedule alarm for id=$id: $e');
  }
}

@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  int? alarmGen;
  try {
    WidgetsFlutterBinding.ensureInitialized();

    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }

    late Box<Habit> box;
    try {
      box = Hive.box<Habit>(AppConstants.habitBoxName);
    } catch (_) {
      box = await Hive.openBox<Habit>(AppConstants.habitBoxName);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    alarmGen = prefs.getInt('alarm_gen_$id') ?? 0;
    final habitId = prefs.getString('alarm_habit_id_$id');
    final habitName = prefs.getString('alarm_habit_name_$id') ?? 'Your Habit';

    if (habitId != null) {
      final habit = box.values.cast<Habit?>().firstWhere(
            (h) => h!.id == habitId,
            orElse: () => null,
          );

      if (habit != null) {
        final notificationId = (habitId.hashCode.abs() % 1000000) + 1000000;
        await prefs.setBool('alarm_ringing', true);
        // If the app is currently running, notify the UI isolate to show the prompt.
        IsolateNameServer.lookupPortByName(AlarmService._portName)
            ?.send('ring');

        try {
          await _showAlarmNotification(habitName, notificationId);
        } catch (_) {}

        try {
          final player = FlutterRingtonePlayer();
          await player.playAlarm(
            looping: true,
            volume: 1.0,
            asAlarm: true,
          );

          // Stop early if the user taps “Stop alarm” (which flips `alarm_ringing`).
          final end = DateTime.now().add(const Duration(seconds: 90));
          while (DateTime.now().isBefore(end)) {
            // Important: another isolate might update SharedPreferences.
            // Re-get the instance + reload so we don't read a cached value.
            final latestPrefs = await SharedPreferences.getInstance();
            await latestPrefs.reload();
            final shouldKeepRinging =
                latestPrefs.getBool('alarm_ringing') ?? true;
            if (!shouldKeepRinging) break;
            await Future.delayed(const Duration(milliseconds: 500));
          }

          await player.stop();
        } catch (_) {}

        await prefs.setBool('alarm_ringing', false);
        IsolateNameServer.lookupPortByName(AlarmService._portName)
            ?.send('stop');

        await Future.delayed(const Duration(seconds: 30));
        await _rescheduleAlarmForTomorrow(id, alarmGen);
      }
    }
  } catch (e) {
    try {
      await _showAlarmNotification(
          'Habit Deadline', (id.hashCode.abs() % 1000000) + 1000000);
    } catch (_) {}
  }
}

class AlarmService {
  static final AlarmService _instance = AlarmService._();
  factory AlarmService() => _instance;
  AlarmService._();

  bool _initialized = false;

  static const String _portName = 'habit_alarm_port';

  final StreamController<bool> _alarmPromptController =
      StreamController<bool>.broadcast();

  Stream<bool> get alarmPromptStream => _alarmPromptController.stream;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await AndroidAlarmManager.initialize();
    _initialized = true;

    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(port.sendPort, _portName);
    port.listen((message) {
      if (message == 'ring') {
        _alarmPromptController.add(true);
      } else if (message == 'stop') {
        FlutterRingtonePlayer().stop();
        _alarmPromptController.add(false);
      }
    });
  }

  // New alarm id generation:
  // - Avoids modulo compression that can cause collisions (overwrites).
  // - Keeps the id within a safe positive int range.
  static int alarmId(String habitId) {
    final masked = habitId.hashCode & 0x3fffffff; // 30-bit positive range
    return masked + 2000000;
  }

  // Legacy alarm id generation (kept for migration/cancel).
  static int legacyAlarmId(String habitId) =>
      (habitId.hashCode.abs() % 1000000) + 2000000;

  Future<void> scheduleDeadlineAlarm({
    required String habitId,
    required String habitName,
    required String timeStr,
  }) async {
    // On Android 13/14+, exact alarms can be denied at runtime in release builds.
    // If permission is not granted, skip scheduling to avoid silent failures.
    final canSchedule = await canScheduleExactAlarms();
    if (!canSchedule) {
      final granted = await requestExactAlarmPermission();
      if (!granted) {
        return;
      }
    }

    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final id = alarmId(habitId);

    final prefs = await SharedPreferences.getInstance();
    final newGen = (prefs.getInt('alarm_gen_$id') ?? 0) + 1;
    await prefs.setInt('alarm_gen_$id', newGen);

    await prefs.setString('alarm_habit_id_$id', habitId);
    await prefs.setString('alarm_habit_name_$id', habitName);
    await prefs.setString('alarm_deadline_time_$id', timeStr);

    await AndroidAlarmManager.oneShotAt(
      scheduled,
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      rescheduleOnReboot: true,
    );
  }

  Future<void> cancelDeadlineAlarm(String habitId) async {
    final id = alarmId(habitId);
    // Cancel both:
    // - legacy id (previous versions / migration)
    // - current id
    await AndroidAlarmManager.cancel(legacyAlarmId(habitId));
    await AndroidAlarmManager.cancel(alarmId(habitId));

    final prefs = await SharedPreferences.getInstance();
    final newGen = (prefs.getInt('alarm_gen_$id') ?? 0) + 1;
    await prefs.setInt('alarm_gen_$id', newGen);
  }

  Future<void> rescheduleAllDeadlineAlarms(List<Habit> habits) async {
    for (final habit in habits) {
      if (habit.deadlineTime != null && habit.isScheduledForToday()) {
        // Migration: remove any legacy alarms so they don't overwrite/show duplicates.
        await AndroidAlarmManager.cancel(legacyAlarmId(habit.id));

        await scheduleDeadlineAlarm(
          habitId: habit.id,
          habitName: habit.name,
          timeStr: habit.deadlineTime!,
        );
      }
    }
  }

  Future<void> stopAlarm() async {
    FlutterRingtonePlayer().stop();
    _alarmPromptController.add(false);
    final prefs = await SharedPreferences.getInstance();
    // Await so the alarmCallback isolate sees the update quickly.
    await prefs.setBool('alarm_ringing', false);
  }

  /// Used by notification taps/full-screen intents to force the UI prompt.
  void notifyAlarmRang() {
    _alarmPromptController.add(true);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('alarm_ringing', true);
    });
  }

  Future<bool> requestExactAlarmPermission() async {
    try {
      final status = await permission.Permission.scheduleExactAlarm.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final status =
          await permission.Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final status =
          await permission.Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await permission.openAppSettings();
    } catch (e) {
      return false;
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    try {
      final status = await permission.Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      return true;
    }
  }

  Future<Map<String, bool>> getAlarmPermissionsStatus() async {
    return {
      'batteryOptimizationDisabled': await isBatteryOptimizationDisabled(),
      'canScheduleExactAlarms': await canScheduleExactAlarms(),
    };
  }
}
