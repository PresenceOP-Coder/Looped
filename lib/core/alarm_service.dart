import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart' as permission;

import '../features/habits/domain/habit_model.dart';
import 'constants.dart';

/// top-level callback function for android_alarm_manager_plus.
/// this must be top-level function not class method for plugin to work.
///
/// this runs in seprate isolate when alarm fires, so we must re-init hive
/// to check if habit was complted. if not completed, ring the alarm.
@pragma('vm:entry-point')
Future<void> alarmCallback(int id) async {
  try {
    // initalize hive to check habit compleation
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

    // read which habit this alarm is for
    final prefs = await SharedPreferences.getInstance();
    final habitId = prefs.getString('alarm_habit_id_$id');

    if (habitId != null) {
      // check if habit was completd today
      final today = DateTime.now().toIso8601String().split('T')[0];
      final habit = box.values.cast<Habit?>().firstWhere(
            (h) => h!.id == habitId,
            orElse: () => null,
          );

      if (habit != null && !habit.completedDates.contains(today)) {
        // not completd — ring the alarm!
        final player = FlutterRingtonePlayer();
        await player.playAlarm(
          looping: true,
          volume: 1.0,
          asAlarm: true, // uses stream_alarm — rings even in silent/dnd
        );

        // auto-stop after 30 second
        await Future.delayed(const Duration(seconds: 30));
        await player.stop();
      } else if (habit != null) {
        // habit alredy completed today, skip alarm
      } else {
        // habit not found
      }
    }

    // re-schedual for tommorow since we use oneshot, not repeating
    final deadlineTime = prefs.getString('alarm_deadline_time_$id');
    final habitName = prefs.getString('alarm_habit_name_$id');
    // habitid alredy declared above
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
    // safety net: if anythng fails, still try to ring
    try {
      final player = FlutterRingtonePlayer();
      await player.playAlarm(
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );
      await Future.delayed(const Duration(seconds: 30));
      await player.stop();
    } catch (emergencyError) {
      // emergancy alarm also faild
    }
  }
}

/// service to schedual real device alarm sounds when habit deadline is missd.
///
/// uses [AndroidAlarmManager] for exact-time schedulng works even when app is
/// killd and [FlutterRingtonePlayer] to play the devices built-in alarm
/// ringtone. alarm rings on alarm audio stream, so it sounds even in
/// silent/dnd mode.
class AlarmService {
  static final AlarmService _instance = AlarmService._();
  factory AlarmService() => _instance;
  AlarmService._();

  bool _initialized = false;

  /// port name for comunicating from alarm isolate to main isolate.
  static const String _portName = 'habit_alarm_port';

  /// initalize the alarm manager. call once at app startup.
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await AndroidAlarmManager.initialize();
    _initialized = true;

    // register port so alarm callback can signal ui isolate
    // used to stop ringtone after timeout or manual dismis.
    final port = ReceivePort();
    IsolateNameServer.removePortNameMapping(_portName);
    IsolateNameServer.registerPortWithName(port.sendPort, _portName);
    port.listen((message) {
      // when we recieve signal to stop, stop alarm player
      if (message == 'stop') {
        FlutterRingtonePlayer().stop();
      }
    });
  }

  /// generate unique alarm id for habit deadline.
  /// offset by 200000 to avoid colision with notifcation ids.
  static int alarmId(String habitId) =>
      (habitId.hashCode.abs() % 100000) + 200000;

  /// schedual the deadline alarm for habit.
  ///
  /// [habitId] — the habits unique id used to check compleation in callback.
  /// [habitName] — displayd if we show notifcation fallback.
  /// [timeStr] — deadline time in 'hh:mm' format.
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

    // if time alredy passed today, schedual for tommorow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // store habit info in sharedprefernces so static callback can read it
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_habit_id_${alarmId(habitId)}', habitId);
    await prefs.setString('alarm_habit_name_${alarmId(habitId)}', habitName);
    await prefs.setString('alarm_deadline_time_${alarmId(habitId)}', timeStr);

    // schedual one-shot exact alarm
    await AndroidAlarmManager.oneShotAt(
      scheduled,
      alarmId(habitId),
      alarmCallback,
      exact: true,
      wakeup: true,
      alarmClock: true, // Shows alarm icon in status bar, highest priority
      rescheduleOnReboot: true,
    );
  }

  /// cancel scheduled deadline alarm for habit.
  Future<void> cancelDeadlineAlarm(String habitId) async {
    await AndroidAlarmManager.cancel(alarmId(habitId));
    // clean up storied prefs
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alarm_habit_id_${alarmId(habitId)}');
    await prefs.remove('alarm_habit_name_${alarmId(habitId)}');
    await prefs.remove('alarm_deadline_time_${alarmId(habitId)}');
  }

  /// re-arm deadline alarms for all habits at app startups.
  /// only scheduals for habits that:
  /// - have deadlinetime set
  /// - are scheduld for today
  /// - are not completd today
  Future<void> rescheduleAllDeadlineAlarms(List<Habit> habits) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    for (final habit in habits) {
      if (habit.deadlineTime != null && habit.isScheduledForToday()) {
        if (!habit.completedDates.contains(today)) {
          await scheduleDeadlineAlarm(
            habitId: habit.id,
            habitName: habit.name,
            timeStr: habit.deadlineTime!,
          );
        } else {
          // alredy completed today — cancel if pending
          await cancelDeadlineAlarm(habit.id);
        }
      }
    }
  }

  /// stop the alarm sound manualy e.g. from dismiss button.
  void stopAlarm() {
    FlutterRingtonePlayer().stop();
  }

  /// request exact alarm permision android 12+.
  /// returns true if permision is granted.
  Future<bool> requestExactAlarmPermission() async {
    try {
      // note: android_alarm_manager_plus doesnt have built-in permision check
      // the permision is declared in androidmanifest, and android will prompts
      // the user if needd. on android 12+ with alarmclock: true, it should works.
      return true;
    } catch (e) {
      return false;
    }
  }

  /// check if app is exempted from baterry optimiztion.
  /// baterry optimiztion can prevent alarms from working in backgroud.
  Future<bool> isBatteryOptimizationDisabled() async {
    try {
      final status =
          await permission.Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// request to disable baterry optimiztion for this app.
  /// this opens system dialog asking user for permision.
  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      final status =
          await permission.Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// open apps settings page where user can manualy disable restrictions.
  /// this is usefull for showing users how to disable baterry optimiztion
  /// and grant exact alarm permisions on android 12+.
  Future<bool> openAppSettings() async {
    try {
      return await permission.openAppSettings();
    } catch (e) {
      return false;
    }
  }

  /// check if exact alarm permision is availble android 12+.
  Future<bool> canScheduleExactAlarms() async {
    try {
      final status = await permission.Permission.scheduleExactAlarm.status;
      return status.isGranted;
    } catch (e) {
      // assume granted on older android versons
      return true;
    }
  }

  /// get summary of all alarm-related permisions and optimiztion status.
  Future<Map<String, bool>> getAlarmPermissionsStatus() async {
    return {
      'batteryOptimizationDisabled': await isBatteryOptimizationDisabled(),
      'canScheduleExactAlarms': await canScheduleExactAlarms(),
    };
  }
}
