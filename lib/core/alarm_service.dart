import 'dart:isolate';
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

/// Shows a high-priority heads-up notification for a habit alarm.
/// Works in both foreground and background isolates.
Future<void> _showAlarmNotification(
    String habitName, int notificationId) async {
  final plugin = FlutterLocalNotificationsPlugin();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings);

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
    timeoutAfter: 60000, // auto-dismiss after 60 seconds
  );

  const details = NotificationDetails(android: androidDetails);

  await plugin.show(
    notificationId,
    'HabitFlow Alarm',
    'Deadline reached for: $habitName',
    details,
  );
}

/// Re-schedules the alarm for tomorrow. Only proceeds if no one else
/// (e.g. the main isolate) has rescheduled/cancelled since this callback started.
Future<void> _rescheduleAlarmForTomorrow(int id, int expectedGen) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    // Force fresh read from disk (cross-isolate safety)
    await prefs.reload();
    final currentGen = prefs.getInt('alarm_gen_$id') ?? 0;
    if (currentGen != expectedGen) {
      debugPrint(
          'Skipping reschedule for alarm $id: gen changed ($expectedGen → $currentGen)');
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
      debugPrint('Rescheduled alarm $id for tomorrow: $nextAlarm');
    }
  } catch (e) {
    debugPrint('Failed to reschedule alarm $id: $e');
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
    await prefs.reload(); // fresh read from disk
    alarmGen = prefs.getInt('alarm_gen_$id') ?? 0;
    final habitId = prefs.getString('alarm_habit_id_$id');
    final habitName = prefs.getString('alarm_habit_name_$id') ?? 'Your Habit';

    if (habitId != null) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final habit = box.values.cast<Habit?>().firstWhere(
            (h) => h!.id == habitId,
            orElse: () => null,
          );

      if (habit != null) {
        final notificationId = (habitId.hashCode.abs() % 1000000) + 1000000;
        await _showAlarmNotification(habitName, notificationId);

        try {
          final player = FlutterRingtonePlayer();
          await player.playAlarm(
            looping: true,
            volume: 1.0,
            asAlarm: true,
          );
          await Future.delayed(const Duration(seconds: 30));
          await player.stop();
        } catch (_) {}

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
      if (message == 'stop') {
        FlutterRingtonePlayer().stop();
      }
    });
  }

  static int alarmId(String habitId) =>
      (habitId.hashCode.abs() % 1000000) + 2000000;

  Future<void> scheduleDeadlineAlarm({
    required String habitId,
    required String habitName,
    required String timeStr,
  }) async {
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final isToday = scheduled.year == now.year &&
        scheduled.month == now.month &&
        scheduled.day == now.day;

    final id = alarmId(habitId);

    // Bump generation so any running background callback won't overwrite this
    final prefs = await SharedPreferences.getInstance();
    final newGen = (prefs.getInt('alarm_gen_$id') ?? 0) + 1;
    await prefs.setInt('alarm_gen_$id', newGen);

    // Store alarm metadata BEFORE scheduling so the callback can always find it
    await prefs.setString('alarm_habit_id_$id', habitId);
    await prefs.setString('alarm_habit_name_$id', habitName);
    await prefs.setString('alarm_deadline_time_$id', timeStr);

    // oneShotAt with alarmClock:true uses setAlarmClock which auto-replaces
    // any existing alarm with the same ID — no need for a separate cancel
    await AndroidAlarmManager.oneShotAt(
      scheduled,
      id,
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true,
      rescheduleOnReboot: true,
    );

    debugPrint(
        'Alarm scheduled: habit=$habitName id=$id at=$scheduled gen=$newGen');
    debugPrint(
        'Alarm schedule detail: now=$now scheduled=$scheduled sameDay=$isToday');
  }

  Future<void> cancelDeadlineAlarm(String habitId) async {
    final id = alarmId(habitId);
    await AndroidAlarmManager.cancel(id);

    // Bump generation so any running background callback won't reschedule
    final prefs = await SharedPreferences.getInstance();
    final newGen = (prefs.getInt('alarm_gen_$id') ?? 0) + 1;
    await prefs.setInt('alarm_gen_$id', newGen);

    debugPrint('Alarm cancelled: habitId=$habitId alarmId=$id gen=$newGen');
  }

  Future<void> rescheduleAllDeadlineAlarms(List<Habit> habits) async {
    for (final habit in habits) {
      if (habit.deadlineTime != null && habit.isScheduledForToday()) {
        await scheduleDeadlineAlarm(
          habitId: habit.id,
          habitName: habit.name,
          timeStr: habit.deadlineTime!,
        );
      }
    }
  }

  void stopAlarm() {
    FlutterRingtonePlayer().stop();
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
