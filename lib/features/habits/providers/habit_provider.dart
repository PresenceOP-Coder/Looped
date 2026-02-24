import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/alarm_service.dart';
import '../../../core/constants.dart';
import '../../../core/notification_service.dart';
import '../domain/habit_model.dart';

final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  return HabitNotifier();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

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

  HabitNotifier() : super([]) {
    _loadHabits();
  }

  void _loadHabits() {
    final habits = _box.values.toList();
    habits.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    state = habits;
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
    final effectiveClearReminderTime =
        isCompletedToday ? false : clearReminderTime;
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

    // Always manage deadline alarm based on final state of the habit
    if (effectiveClearDeadlineTime) {
      await AlarmService().cancelDeadlineAlarm(id);
    } else if (effectiveDeadlineTime != null && !isCompletedToday) {
      // Cancel old alarm first, then reschedule
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

    // --- Manage deadline alarm ---
    if (habit.deadlineTime != null) {
      if (!wasCompleted) {
        // Was NOT completed → now IS completed → cancel alarm + stop any playing sound
        await AlarmService().cancelDeadlineAlarm(id);
        AlarmService().stopAlarm();
      } else {
        // Was completed → now UN-completed → always reschedule alarm
        // If deadline hasn't passed today, schedule for today; otherwise tomorrow
        await AlarmService().scheduleDeadlineAlarm(
          habitId: id,
          habitName: habit.name,
          timeStr: habit.deadlineTime!,
        );
      }
    }

    // --- Manage notification reminder ---
    if (habit.reminderTime != null) {
      if (!wasCompleted) {
        // Completed → cancel today's reminder
        await NotificationService().cancelReminder(id);
      } else {
        // Un-completed → reschedule reminder
        await NotificationService().scheduleHabitReminder(
          habitId: id,
          habitName: habit.name,
          timeStr: habit.reminderTime!,
        );
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
    if (habit.completedDates.isEmpty) return 0;
    final dates = List<String>.from(habit.completedDates)
      ..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();

    final lastDate = DateTime.parse(dates.first);
    final difference = today.difference(lastDate).inDays;

    if (difference > 1) return 0;

    int streak = 0;

    for (int i = 0; i < dates.length; i++) {
      if (i == 0) {
        streak = 1;
      } else {
        final prev = DateTime.parse(dates[i - 1]);
        final current = DateTime.parse(dates[i]);
        if (prev.difference(current).inDays == 1) {
          streak++;
        } else {
          break;
        }
      }
    }
    return streak;
  }

  int getBestStreak(Habit habit) {
    if (habit.completedDates.isEmpty) return 0;
    final dates = List<String>.from(habit.completedDates)
      ..sort((a, b) => a.compareTo(b));

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
