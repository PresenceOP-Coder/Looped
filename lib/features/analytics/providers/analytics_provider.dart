import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants.dart';
import '../../habits/providers/habit_provider.dart';

class AnalyticsStats {
  final int totalHabits;
  final int totalCompletions;
  final int perfectDays;
  final int longestStreak;
  final String? mostConsistentHabit;
  final int activeDays;

  const AnalyticsStats({
    required this.totalHabits,
    required this.totalCompletions,
    required this.perfectDays,
    required this.longestStreak,
    this.mostConsistentHabit,
    required this.activeDays,
  });
}

class DayCompletion {
  final DateTime date;
  final int count;
  final String dayLabel;

  const DayCompletion({
    required this.date,
    required this.count,
    required this.dayLabel,
  });
}

class CategoryStat {
  final String name;
  final Color color;
  final IconData icon;
  final int completions;
  final double percentage;

  const CategoryStat({
    required this.name,
    required this.color,
    required this.icon,
    required this.completions,
    required this.percentage,
  });
}

class HabitStreak {
  final String habitName;
  final String category;
  final int currentStreak;
  final int bestStreak;

  const HabitStreak({
    required this.habitName,
    required this.category,
    required this.currentStreak,
    required this.bestStreak,
  });
}

class DayOfWeekStat {
  final String day;
  final double avgCompletions;

  const DayOfWeekStat({required this.day, required this.avgCompletions});
}

final analyticsStatsProvider = Provider<AnalyticsStats>((ref) {
  final habits = ref.watch(habitProvider);
  final notifier = ref.read(habitProvider.notifier);

  if (habits.isEmpty) {
    return const AnalyticsStats(
      totalHabits: 0,
      totalCompletions: 0,
      perfectDays: 0,
      longestStreak: 0,
      activeDays: 0,
    );
  }

  // Count only actual completions (not freezes) for metrics
  final totalCompletions =
      habits.fold<int>(0, (sum, h) => sum + h.completedDates.length);

  // Include both completions and freezes for perfect days calculation
  final allDates = <String>{};
  for (final h in habits) {
    allDates.addAll(h.completedDates);
    allDates.addAll(h.freezeDates);
  }

  int perfectDays = 0;
  for (final date in allDates) {
    final completedOrFrozen = habits.every(
        (h) => h.completedDates.contains(date) || h.freezeDates.contains(date));
    if (completedOrFrozen) perfectDays++;
  }

  int longestStreak = 0;
  String? mostConsistentHabit;
  for (final h in habits) {
    final best = notifier.getBestStreak(h);
    if (best > longestStreak) {
      longestStreak = best;
      mostConsistentHabit = h.name;
    }
  }

  return AnalyticsStats(
    totalHabits: habits.length,
    totalCompletions: totalCompletions,
    perfectDays: perfectDays,
    longestStreak: longestStreak,
    mostConsistentHabit: mostConsistentHabit,
    activeDays: allDates.length,
  );
});

final weeklyCompletionsProvider = Provider<List<DayCompletion>>((ref) {
  final habits = ref.watch(habitProvider);
  final now = DateTime.now();
  final days = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return List.generate(7, (i) {
    final date = now.subtract(Duration(days: 6 - i));
    final dateStr = date.toIso8601String().split('T')[0];
    // Count habits completed or frozen on this date
    final count = habits
        .where((h) =>
            h.completedDates.contains(dateStr) ||
            h.freezeDates.contains(dateStr))
        .length;
    return DayCompletion(
      date: date,
      count: count,
      dayLabel: days[date.weekday - 1],
    );
  });
});

final categoryStatsProvider = Provider<List<CategoryStat>>((ref) {
  final habits = ref.watch(habitProvider);
  if (habits.isEmpty) return [];

  final totalCompletions =
      habits.fold<int>(0, (sum, h) => sum + h.completedDates.length);
  if (totalCompletions == 0) return [];

  final Map<String, int> catCompletions = {};
  for (final h in habits) {
    catCompletions[h.category] =
        (catCompletions[h.category] ?? 0) + h.completedDates.length;
  }

  return catCompletions.entries.map((e) {
    final cat = AppConstants.getCategory(e.key);
    return CategoryStat(
      name: e.key,
      color: cat.color,
      icon: cat.icon,
      completions: e.value,
      percentage: e.value / totalCompletions * 100,
    );
  }).toList()
    ..sort((a, b) => b.completions.compareTo(a.completions));
});

final streaksLeaderboardProvider = Provider<List<HabitStreak>>((ref) {
  final habits = ref.watch(habitProvider);
  final notifier = ref.read(habitProvider.notifier);

  final streaks = habits.map((h) {
    return HabitStreak(
      habitName: h.name,
      category: h.category,
      currentStreak: notifier.getStreak(h),
      bestStreak: notifier.getBestStreak(h),
    );
  }).toList();

  streaks.sort((a, b) => b.currentStreak.compareTo(a.currentStreak));
  return streaks;
});

final dayOfWeekStatsProvider = Provider<List<DayOfWeekStat>>((ref) {
  final habits = ref.watch(habitProvider);
  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final Map<int, int> dayCounts = {
    for (int i = 1; i <= 7; i++) i: 0,
  };

  for (final h in habits) {
    // Count both completions and freezes
    for (final dateStr in h.completedDates) {
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        dayCounts[date.weekday] = dayCounts[date.weekday]! + 1;
      }
    }
    for (final dateStr in h.freezeDates) {
      final date = DateTime.tryParse(dateStr);
      if (date != null) {
        dayCounts[date.weekday] = dayCounts[date.weekday]! + 1;
      }
    }
  }

  if (habits.isEmpty) {
    return dayNames
        .asMap()
        .entries
        .map((e) => DayOfWeekStat(day: e.value, avgCompletions: 0))
        .toList();
  }

  final earliest =
      habits.map((h) => h.createdAt).reduce((a, b) => a.isBefore(b) ? a : b);
  final weeksActive =
      (DateTime.now().difference(earliest).inDays / 7).ceil().clamp(1, 9999);

  return List.generate(7, (i) {
    final weekday = i + 1;
    return DayOfWeekStat(
      day: dayNames[i],
      avgCompletions: dayCounts[weekday]! / weeksActive,
    );
  });
});

final heatmapDataProvider = Provider<Map<String, int>>((ref) {
  final habits = ref.watch(habitProvider);
  final now = DateTime.now();
  final Map<String, int> heatmap = {};

  for (int i = 0; i < 90; i++) {
    final date = now.subtract(Duration(days: 89 - i));
    final dateStr = date.toIso8601String().split('T')[0];
    // Count habits completed or frozen on this date
    final count = habits
        .where((h) =>
            h.completedDates.contains(dateStr) ||
            h.freezeDates.contains(dateStr))
        .length;
    heatmap[dateStr] = count;
  }

  return heatmap;
});
