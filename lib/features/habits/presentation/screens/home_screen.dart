import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_habit_modal.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitProvider);
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final doneToday = habits.where((h) => h.completedDates.contains(todayStr)).length;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6366F1),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Text(
                              'My Routine',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: const Icon(LucideIcons.trendingUp, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildStatTile('Today\'s Goal', '$doneToday/${habits.length}', const Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        _buildStatTile('Success Rate', habits.isEmpty ? '0%' : '${((doneToday/habits.length)*100).round()}%', const Color(0xFF6366F1)),
                      ],
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
                          Icon(LucideIcons.sparkles, size: 64, color: Colors.grey.shade200),
                          const SizedBox(height: 16),
                          Text(
                            'Your routine is empty',
                            style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final habit = habits[index];
                        return Dismissible(
                          key: Key(habit.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            ref.read(habitProvider.notifier).deleteHabit(habit.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${habit.name} removed from routine'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFF1E293B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            child: const Icon(LucideIcons.trash2, color: Colors.white),
                          ),
                          child: HabitCard(habit: habit),
                        );
                      },
                      childCount: habits.length,
                    ),
                  ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabitModal(context),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        label: const Text('Add New Habit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
          ],
        ),
      ),
    );
  }

  void _showAddHabitModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHabitModal(),
    );
  }
}