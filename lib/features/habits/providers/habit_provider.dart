import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/alarm_service.dart';
import '../../../core/constants.dart';
import '../../../core/notification_service.dart';
import '../../../core/streak_freeze_service.dart';
import '../domain/habit_model.dart';

final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  return HabitNotifier();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final freezeRemainingProvider = FutureProvider<int>((ref) async {
  return StreakFreezeService().getRemainingForCurrentMonth();
});

final filteredHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  if (selectedCategory == null) return habits;
  return habits.where((h) => h.category == selectedCategory).toList();
});

final todayHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(filteredHabitsProvider);
  return habits.where((h) => h.isScheduledForToday()).toList();
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  final _box = Hive.box<Habit>(AppConstants.habitBoxName);
  final _freezeService = StreakFreezeService();

  HabitNotifier() : super([]) {
    _loadHabits();
    Future.microtask(_applyAutoFreezeForYesterday);
  }

  void _loadHabits() {
    final habits = _box.values.toList();
    habits.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    state = habits;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _dateStr(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool _isScheduledOnDate(Habit habit, DateTime date) {
    if (habit.frequency == 'daily') return true;
    final weekday = date.weekday;
    if ((habit.frequency == 'custom' || habit.frequency == 'weekly') &&
        habit.targetDays != null) {
      return habit.targetDays!.contains(weekday);
    }
    return true;
  }

  Set<String> _effectiveDoneDates(Habit habit) {
    return {
      ...habit.completedDates,
      ...habit.freezeDates,
    };
  }

  Future<void> _applyAutoFreezeForYesterday() async {
    final yesterday =
        _dateOnly(DateTime.now().subtract(const Duration(days: 1)));
    if (!await _freezeService.shouldRunAutoFreezeForDate(yesterday)) {
      return;
    }

    final yesterdayStr = _dateStr(yesterday);
    final dayBeforeStr = _dateStr(yesterday.subtract(const Duration(days: 1)));

    for (final habit in List<Habit>.from(state)) {
      if (!_isScheduledOnDate(habit, yesterday)) {
        continue;
      }

      final doneDates = _effectiveDoneDates(habit);
      if (doneDates.contains(yesterdayStr)) {
        continue;
      }

      if (!doneDates.contains(dayBeforeStr)) {
        continue;
      }

      final consumed = await _freezeService.consumeFreezeForDate(
        habitId: habit.id,
        date: yesterday,
      );
      if (!consumed) {
        break;
      }

      final updatedFreezeDates = List<String>.from(habit.freezeDates)
        ..add(yesterdayStr)
        ..sort();
      final updatedHabit = habit.copyWith(freezeDates: updatedFreezeDates);
      await _box.put(habit.id, updatedHabit);

      state = [
        for (final h in state)
          if (h.id == habit.id) updatedHabit else h,
      ];
    }

    await _freezeService.markAutoFreezeRunForDate(yesterday);
  }

  Future<int> getRemainingFreezes() {
    return _freezeService.getRemainingForCurrentMonth();
  }

  Future<bool> applyManualFreezeForYesterday(String habitId) async {
    final habit = state.firstWhere((h) => h.id == habitId);
    final yesterday =
        _dateOnly(DateTime.now().subtract(const Duration(days: 1)));
    final yesterdayStr = _dateStr(yesterday);

    if (!_isScheduledOnDate(habit, yesterday)) {
      return false;
    }

    if (_effectiveDoneDates(habit).contains(yesterdayStr)) {
      return false;
    }

    final consumed = await _freezeService.consumeFreezeForDate(
      habitId: habit.id,
      date: yesterday,
    );
    if (!consumed) {
      return false;
    }

    final updatedFreezeDates = List<String>.from(habit.freezeDates)
      ..add(yesterdayStr)
      ..sort();
    final updatedHabit = habit.copyWith(freezeDates: updatedFreezeDates);
    await _box.put(habit.id, updatedHabit);

    state = [
      for (final h in state)
        if (h.id == habit.id) updatedHabit else h,
    ];

    return true;
  }

  Future<void> addHabit(
    String name,
    String category, {
    String? description,
    String frequency = 'daily',
    List<int>? targetDays,
    String? reminderTime,
    String? deadlineTime,
  }) async {
    final sortOrder = state.isEmpty ? 0 : state.last.sortOrder + 1;
    final newHabit = Habit.create(
      name: name,
      category: category,
      description: description,
      frequency: frequency,
      targetDays: targetDays,
      sortOrder: sortOrder,
      reminderTime: reminderTime,
      deadlineTime: deadlineTime,
    );
    await _box.put(newHabit.id, newHabit);
    state = [...state, newHabit];

    if (reminderTime != null) {
      await NotificationService().scheduleHabitReminder(
        habitId: newHabit.id,
        habitName: name,
        timeStr: reminderTime,
      );
    }

    if (deadlineTime != null) {
      await AlarmService().scheduleDeadlineAlarm(
        habitId: newHabit.id,
        habitName: name,
        timeStr: deadlineTime,
      );
    }
  }

  Future<void> updateHabit(
    String id, {
    String? name,
    String? category,
    String? description,
    String? frequency,
    List<int>? targetDays,
    bool clearTargetDays = false,
    String? reminderTime,
    bool clearReminderTime = false,
    String? deadlineTime,
    bool clearDeadlineTime = false,
  }) async {
    final habit = state.firstWhere((h) => h.id == id);
    final isCompletedToday = habit.isCompletedToday();
    final effectiveReminderTime =
        isCompletedToday ? habit.reminderTime : reminderTime;
    final effectiveDeadlineTime =
        isCompletedToday ? habit.deadlineTime : deadlineTime;
    // Reminder feature removed from the UI: always allow clearing reminderTime.
    final effectiveClearReminderTime = clearReminderTime;
    final effectiveClearDeadlineTime =
        isCompletedToday ? false : clearDeadlineTime;
    final updatedHabit = habit.copyWith(
      name: name,
      category: category,
      description: description,
      frequency: frequency,
      targetDays: targetDays,
      clearTargetDays: clearTargetDays,
      reminderTime: effectiveReminderTime,
      clearReminderTime: effectiveClearReminderTime,
      deadlineTime: effectiveDeadlineTime,
      clearDeadlineTime: effectiveClearDeadlineTime,
    );
    await _box.put(id, updatedHabit);
    state = [
      for (final h in state)
        if (h.id == id) updatedHabit else h,
    ];

    if (effectiveClearReminderTime) {
      await NotificationService().cancelReminder(id);
    } else if (effectiveReminderTime != null && !isCompletedToday) {
      await NotificationService().cancelReminder(id);
      await NotificationService().scheduleHabitReminder(
        habitId: id,
        habitName: updatedHabit.name,
        timeStr: effectiveReminderTime,
      );
    }

    if (effectiveClearDeadlineTime) {
      await AlarmService().cancelDeadlineAlarm(id);
    } else if (effectiveDeadlineTime != null && !isCompletedToday) {
      await AlarmService().cancelDeadlineAlarm(id);
      await AlarmService().scheduleDeadlineAlarm(
        habitId: id,
        habitName: updatedHabit.name,
        timeStr: effectiveDeadlineTime,
      );
    }
  }

  Future<void> toggleHabit(String id) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final habit = state.firstWhere((h) => h.id == id);

    List<String> updatesDates = List.from(habit.completedDates);

    final wasCompleted = updatesDates.contains(today);
    if (wasCompleted) {
      updatesDates.remove(today);
    } else {
      updatesDates.add(today);
    }

    final updatedHabit = habit.copyWith(completedDates: updatesDates);

    await _box.put(id, updatedHabit);

    state = [
      for (final h in state)
        if (h.id == id) updatedHabit else h,
    ];

    if (habit.deadlineTime != null) {
      if (!wasCompleted) {
        await _freezeService.clearRecoveryWindow(id);
        await AlarmService().cancelDeadlineAlarm(id);
        AlarmService().stopAlarm();
      } else {
        await _freezeService.startRecoveryWindow(habitId: id);
        final canRecover = await _freezeService.isRecoveryWindowActive(id);
        if (canRecover) {
          await AlarmService().scheduleDeadlineAlarm(
            habitId: id,
            habitName: habit.name,
            timeStr: habit.deadlineTime!,
          );
        }
      }
    }

    if (habit.reminderTime != null) {
      if (!wasCompleted) {
        await NotificationService().cancelReminder(id);
      } else {
        final canRecover = await _freezeService.isRecoveryWindowActive(id);
        if (canRecover) {
          await NotificationService().scheduleHabitReminder(
            habitId: id,
            habitName: habit.name,
            timeStr: habit.reminderTime!,
          );
        }
      }
    }
  }

  Future<void> deleteHabit(String id) async {
    await NotificationService().cancelReminder(id);
    await AlarmService().cancelDeadlineAlarm(id);
    await _box.delete(id);
    state = state.where((h) => h.id != id).toList();
  }

  Future<void> reorderHabits(int oldIndex, int newIndex) async {
    final items = List<Habit>.from(state);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    final updated = <Habit>[];
    for (int i = 0; i < items.length; i++) {
      final h = items[i].copyWith(sortOrder: i);
      await _box.put(h.id, h);
      updated.add(h);
    }
    state = updated;
  }

  int getStreak(Habit habit) {
    final doneDates = _effectiveDoneDates(habit);
    if (doneDates.isEmpty) return 0;

    var cursor = _dateOnly(DateTime.now());
    final todayStr = _dateStr(cursor);
    if (!doneDates.contains(todayStr)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!doneDates.contains(_dateStr(cursor))) {
        return 0;
      }
    }

    int streak = 0;
    while (doneDates.contains(_dateStr(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int getBestStreak(Habit habit) {
    final dates = _effectiveDoneDates(habit).toList()..sort();
    if (dates.isEmpty) return 0;

    int bestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < dates.length; i++) {
      final prev = DateTime.parse(dates[i - 1]);
      final current = DateTime.parse(dates[i]);
      if (current.difference(prev).inDays == 1) {
        currentStreak++;
        if (currentStreak > bestStreak) bestStreak = currentStreak;
      } else if (current.difference(prev).inDays > 1) {
        currentStreak = 1;
      }
    }
    return bestStreak;
  }
}
