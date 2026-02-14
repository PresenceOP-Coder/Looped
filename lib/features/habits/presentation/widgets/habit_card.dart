import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants.dart';
import '../../domain/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../screens/habit_detail_screen.dart';
import 'add_habit_modal.dart';

class HabitCard extends ConsumerWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = DateTime.now().toIso8601String().split('T')[0];
    final isDoneToday = habit.completedDates.contains(today);
    final streak = ref.read(habitProvider.notifier).getStreak(habit);
    final accentColor = AppConstants.getCategory(habit.category).color;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HabitDetailScreen(habitId: habit.id),
        ),
      ),
      onLongPress: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddHabitModal(existingHabit: habit),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDoneToday ? accentColor.withOpacity(0.05) : theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color:
                isDoneToday ? accentColor.withOpacity(0.2) : theme.dividerColor,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // drag handle
              Icon(
                LucideIcons.gripVertical,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.2),
              ),
              const SizedBox(width: 8),

              // checkmark buttion
              GestureDetector(
                onTap: () =>
                    ref.read(habitProvider.notifier).toggleHabit(habit.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDoneToday
                        ? accentColor
                        : theme.colorScheme.onSurface.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDoneToday
                            ? accentColor.withOpacity(0.3)
                            : Colors.transparent,
                        blurRadius: isDoneToday ? 12 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isDoneToday ? LucideIcons.check : LucideIcons.circle,
                    color: isDoneToday
                        ? Colors.white
                        : theme.colorScheme.onSurface.withOpacity(0.2),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDoneToday
                            ? theme.colorScheme.onSurface.withOpacity(0.4)
                            : theme.colorScheme.onSurface,
                        decoration:
                            isDoneToday ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            habit.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: accentColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (habit.frequency != 'daily') ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              habit.frequency.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Icon(LucideIcons.flame,
                            size: 14,
                            color: streak > 0
                                ? Colors.orange
                                : theme.colorScheme.onSurface.withOpacity(0.2)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$streak Days',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: streak > 0
                                  ? Colors.orange
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.3),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(LucideIcons.chevronRight,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.2)),
            ],
          ),
        ),
      ),
    );
  }
}
