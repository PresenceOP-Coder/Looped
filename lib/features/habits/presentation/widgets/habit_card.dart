import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/habit_model.dart';
import '../../providers/habit_provider.dart';

class HabitCard extends ConsumerWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  // Professional color palette for categories
  Color _getCategoryColor() {
    switch (habit.category) {
      case 'Health':
        return const Color(0xFF10B981); // Emerald
      case 'Mindset':
        return const Color(0xFF8B5CF6); // Purple
      case 'Work':
        return const Color(0xFF3B82F6); // Blue
      case 'Growth':
        return const Color(0xFFF59E0B); // Orange
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final isDoneToday = habit.completedDates.contains(today);
    final streak = ref.read(habitProvider.notifier).getStreak(habit);
    final accentColor = _getCategoryColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDoneToday ? accentColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              isDoneToday ? accentColor.withOpacity(0.2) : Colors.grey.shade100,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Bouncy Checkmark Button
            GestureDetector(
              onTap: () =>
                  ref.read(habitProvider.notifier).toggleHabit(habit.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDoneToday ? accentColor : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDoneToday
                      ? [
                          BoxShadow(
                            color: accentColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  isDoneToday ? LucideIcons.check : LucideIcons.circle,
                  color: isDoneToday ? Colors.white : Colors.grey.shade300,
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
                      color:
                          isDoneToday ? Colors.grey : const Color(0xFF1E293B),
                      decoration:
                          isDoneToday ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
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
                      const SizedBox(width: 12),
                      Icon(LucideIcons.flame,
                          size: 14,
                          color: streak > 0
                              ? Colors.orange
                              : Colors.grey.shade300),
                      const SizedBox(width: 4),
                      Text(
                        '$streak Days',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              streak > 0 ? Colors.orange : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
