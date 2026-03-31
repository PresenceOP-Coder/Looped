import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants.dart';
import '../../providers/habit_provider.dart';
import '../widgets/habit_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habits = ref.watch(filteredHabitsProvider);
    final allHabits = ref.watch(habitProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    final scheduledToday =
        habits.where((h) => h.isScheduledForToday()).toList();
    final doneToday =
        scheduledToday.where((h) => h.completedDates.contains(todayStr)).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              today.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'My Routine',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Image.asset(
                            'assets/icons/looped_logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              LucideIcons.sparkles,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildStatTile(
                          context,
                          'Today\'s Goal',
                          '$doneToday/${scheduledToday.length}',
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 12),
                        _buildStatTile(
                          context,
                          'Success Rate',
                          scheduledToday.isEmpty
                              ? '0%'
                              : '${((doneToday / scheduledToday.length) * 100).round()}%',
                          const Color(0xFF6366F1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip(
                            context: context,
                            label: 'All',
                            isSelected: selectedCategory == null,
                            onTap: () => ref
                                .read(selectedCategoryProvider.notifier)
                                .state = null,
                            count: allHabits.length,
                          ),
                          ...AppConstants.categories.map((cat) {
                            final count = allHabits
                                .where((h) => h.category == cat.name)
                                .length;
                            return _buildFilterChip(
                              context: context,
                              label: cat.name,
                              isSelected: selectedCategory == cat.name,
                              onTap: () => ref
                                  .read(selectedCategoryProvider.notifier)
                                  .state = cat.name,
                              color: cat.color,
                              count: count,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: habits.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.sparkles,
                                size: 64,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.15)),
                            const SizedBox(height: 16),
                            Text(
                              selectedCategory != null
                                  ? 'No $selectedCategory habits yet'
                                  : 'Your routine is empty',
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverReorderableList(
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        return Dismissible(
                          key: Key('dismiss_${habit.id}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                title: const Text(
                                  'Delete Habit',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                content: Text(
                                  'Are you sure you want to delete "${habit.name}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.red.shade400,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return confirmed ?? false;
                          },
                          onDismissed: (direction) {
                            ref
                                .read(habitProvider.notifier)
                                .deleteHabit(habit.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${habit.name} removed from routine',
                                ),
                              ),
                            );
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(LucideIcons.trash2,
                                color: Colors.white),
                          ),
                          child: HabitCard(habit: habit, index: index),
                        );
                      },
                      itemCount: habits.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex--;
                        ref
                            .read(habitProvider.notifier)
                            .reorderHabits(oldIndex, newIndex);
                      },
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
    required int count,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? theme.colorScheme.primary).withValues(alpha: 0.1)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? (color ?? theme.colorScheme.primary).withValues(alpha: 0.3)
                  : theme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? (color ?? theme.colorScheme.primary)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (color ?? theme.colorScheme.primary)
                          .withValues(alpha: 0.15)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? (color ?? theme.colorScheme.primary)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(
      BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -1)),
          ],
        ),
      ),
    );
  }
}
