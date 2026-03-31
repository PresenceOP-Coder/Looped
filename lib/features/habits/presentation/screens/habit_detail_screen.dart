import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants.dart';
import '../../domain/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../widgets/add_habit_modal.dart';

class HabitDetailScreen extends ConsumerWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final habits = ref.watch(habitProvider);
    final habit = habits.cast<Habit?>().firstWhere(
          (h) => h!.id == habitId,
          orElse: () => null,
        );

    if (habit == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Habit not found')),
      );
    }

    final cat = AppConstants.getCategory(habit.category);
    final streak = ref.read(habitProvider.notifier).getStreak(habit);
    final bestStreak = ref.read(habitProvider.notifier).getBestStreak(habit);
    final totalCompletions = habit.completedDates.length;
    final freezeRemainingAsync = ref.watch(freezeRemainingProvider);
    final freezeRemaining = freezeRemainingAsync.valueOrNull ?? 0;

    String? frequencyLabel;
    if (habit.frequency != 'daily') {
      if (habit.targetDays != null && habit.targetDays!.isNotEmpty) {
        const dayAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        frequencyLabel =
            habit.targetDays!.map((d) => dayAbbr[d - 1]).join(', ');
      } else {
        frequencyLabel =
            habit.frequency[0].toUpperCase() + habit.frequency.substring(1);
      }
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _headerAction(
                          context: context,
                          icon: LucideIcons.arrowLeft,
                          onTap: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        _headerAction(
                          context: context,
                          icon: LucideIcons.pencil,
                          onTap: () => _showEditModal(context, habit),
                        ),
                        const SizedBox(width: 8),
                        _headerAction(
                          context: context,
                          icon: LucideIcons.trash2,
                          iconColor: Colors.red.shade400,
                          onTap: () => _confirmDelete(context, ref, habit),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HABIT DETAILS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 32),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  habit.name,
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                    color: theme.colorScheme.onSurface,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Started ${DateFormat('MMM d, yyyy').format(habit.createdAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _detailChip(
                            context: context,
                            icon: LucideIcons.layers,
                            text: habit.category.toUpperCase(),
                            tint: cat.color,
                          ),
                          if (frequencyLabel != null)
                            _detailChip(
                              context: context,
                              icon: LucideIcons.repeat,
                              text: frequencyLabel,
                              tint: theme.colorScheme.primary,
                            ),
                          if (habit.reminderTime != null)
                            _detailChip(
                              context: context,
                              icon: LucideIcons.bell,
                              text: 'Reminder ${habit.reminderTime}',
                              tint: theme.colorScheme.primary,
                            ),
                          if (habit.deadlineTime != null)
                            _detailChip(
                              context: context,
                              icon: LucideIcons.alarmClock,
                              text: 'Deadline ${habit.deadlineTime}',
                              tint: Colors.red.shade400,
                            ),
                        ],
                      ),
                      if (habit.description != null &&
                          habit.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Text(
                            habit.description!,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.65),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 146,
                  child: Row(
                    children: [
                      _buildStatCard(
                        context,
                        'Current Streak',
                        '$streak',
                        LucideIcons.flame,
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        context,
                        'Best Streak',
                        '$bestStreak',
                        LucideIcons.trophy,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        context,
                        'Total Done',
                        '$totalCompletions',
                        LucideIcons.checkCircle,
                        const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: freezeRemaining > 0
                        ? () async {
                            final applied = await ref
                                .read(habitProvider.notifier)
                                .applyManualFreezeForYesterday(habit.id);
                            ref.invalidate(freezeRemainingProvider);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  applied
                                      ? 'Freeze applied for yesterday.'
                                      : 'Could not apply freeze for yesterday.',
                                ),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(LucideIcons.snowflake, size: 16),
                    label: Text(
                        'Use Freeze for Yesterday ($freezeRemaining left)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _FocusTimer(
                  habitId: habit.id,
                  habitName: habit.name,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  'COMPLETION HISTORY',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _CompletionCalendar(
                completedDates: habit.completedDates,
                accentColor: cat.color,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.42),
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color tint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: tint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, Habit habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddHabitModal(existingHabit: habit),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Habit habit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Habit',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(habitProvider.notifier).deleteHabit(habit.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text('Delete',
                style: TextStyle(
                    color: Colors.red.shade400, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _FocusTimer extends ConsumerStatefulWidget {
  final String habitId;
  final String habitName;

  const _FocusTimer({required this.habitId, required this.habitName});

  @override
  ConsumerState<_FocusTimer> createState() => _FocusTimerState();
}

class _FocusTimerState extends ConsumerState<_FocusTimer> {
  static const _presets = [5, 10, 15, 25];
  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        setState(() => _isRunning = false);
        _onTimerComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  void _selectPreset(int minutes) {
    _timer?.cancel();
    setState(() {
      _selectedMinutes = minutes;
      _remainingSeconds = minutes * 60;
      _isRunning = false;
    });
  }

  void _onTimerComplete() {
    ref.read(habitProvider.notifier).toggleHabit(widget.habitId);
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.habitName} completed! Great focus session.'),
        ),
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = 1.0 - (_remainingSeconds / (_selectedMinutes * 60));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(LucideIcons.timer,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'FOCUS TIMER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: theme.dividerColor,
                    valueColor:
                        AlwaysStoppedAnimation(theme.colorScheme.primary),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: _presets.map((m) {
              final isSelected = _selectedMinutes == m;
              return ChoiceChip(
                label: Text(
                  '${m}m',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: theme.colorScheme.primary,
                backgroundColor: theme.scaffoldBackgroundColor,
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: _isRunning ? null : (_) => _selectPreset(m),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _reset,
                icon: const Icon(LucideIcons.rotateCcw, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isRunning ? _pause : _start,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRunning ? LucideIcons.pause : LucideIcons.play,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletionCalendar extends StatefulWidget {
  final List<String> completedDates;
  final Color accentColor;

  const _CompletionCalendar({
    required this.completedDates,
    required this.accentColor,
  });

  @override
  State<_CompletionCalendar> createState() => _CompletionCalendarState();
}

class _CompletionCalendarState extends State<_CompletionCalendar> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final offset = firstWeekday - 1;
    final monthLabel = DateFormat('MMMM yyyy').format(_currentMonth);
    final completedSet = widget.completedDates.toSet();
    final today = DateTime.now();
    final isCurrentMonth =
        _currentMonth.year == today.year && _currentMonth.month == today.month;
    final canGoNext = !isCurrentMonth;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _previousMonth,
                  icon: const Icon(LucideIcons.chevronLeft, size: 20),
                ),
                Text(
                  monthLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: canGoNext ? _nextMonth : null,
                  icon: Icon(LucideIcons.chevronRight,
                      size: 20,
                      color: canGoNext
                          ? null
                          : theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .map((d) => SizedBox(
                        width: 36,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: offset + daysInMonth,
              itemBuilder: (context, index) {
                if (index < offset) return const SizedBox();

                final day = index - offset + 1;
                final dateStr = DateFormat('yyyy-MM-dd').format(
                  DateTime(_currentMonth.year, _currentMonth.month, day),
                );
                final isCompleted = completedSet.contains(dateStr);
                final isToday = isCurrentMonth && day == today.day;

                return Container(
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? widget.accentColor
                        : isToday
                            ? widget.accentColor.withValues(alpha: 0.08)
                            : theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(
                            color: widget.accentColor.withValues(alpha: 0.3),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCompleted || isToday
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isCompleted
                            ? Colors.white
                            : isToday
                                ? widget.accentColor
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
