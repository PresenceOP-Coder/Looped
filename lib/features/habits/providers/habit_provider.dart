import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants.dart';
import '../domain/habit_model.dart';

final habitProvider = StateNotifierProvider<HabitNotifier, List<Habit>>((ref) {
  return HabitNotifier();
});

class HabitNotifier extends StateNotifier<List<Habit>> {
  final _box = Hive.box<Habit>(AppConstants.habitBoxName);

  HabitNotifier() : super([]) {
    _loadHabits();
  }
  void _loadHabits() {
    state = _box.values.toList().reversed.toList();
  }

  Future<void> addHabit(String name, String category) async {
    final newHabit = Habit.create(name: name, category: category);

    await _box.put(newHabit.id, newHabit);

    state = [newHabit, ...state];
  }

  Future<void> toggleHabit(String id) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final habit = state.firstWhere((h) => h.id == id);

    List<String> updatesDates = List.from(habit.completedDates);

    if (updatesDates.contains(today)) {
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
  }

  Future<void> deleteHabit(String id) async {
    await _box.delete(id);
    state = state.where((h) => h.id != id).toList();
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
}
