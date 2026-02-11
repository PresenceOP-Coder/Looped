import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/analytics_provider.dart';
import '../../../habits/providers/habit_provider.dart';

class HeatmapCalendar extends ConsumerWidget {
  const HeatmapCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final heatmap = ref.watch(heatmapDataProvider);
    final habits = ref.watch(habitProvider);
    final totalHabits = habits.length.clamp(1, 999);
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                'Last 90 days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Month labels
          _buildMonthLabels(now, theme),
          const SizedBox(height: 6),
          // Heatmap grid
          SizedBox(
            height: 7 * 14.0, // 7 rows × (10 cell + 4 gap)
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 7 * 14.0),
                  painter: _HeatmapPainter(
                    heatmap: heatmap,
                    now: now,
                    totalHabits: totalHabits,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                final opacity = i == 0 ? 0.06 : (i / 4);
                return Container(
                  margin: const EdgeInsets.only(left: 2),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(opacity),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthLabels(DateTime now, ThemeData theme) {
    final months = <_MonthLabel>[];
    final startDate = now.subtract(const Duration(days: 89));

    String? lastMonth;
    for (int i = 0; i < 90; i++) {
      final date = startDate.add(Duration(days: i));
      final monthStr = DateFormat('MMM').format(date);
      if (monthStr != lastMonth) {
        // Approximate column position
        final weekCol = i ~/ 7;
        months.add(_MonthLabel(label: monthStr, col: weekCol));
        lastMonth = monthStr;
      }
    }

    return SizedBox(
      height: 16,
      child: Stack(
        children: months.map((m) {
          return Positioned(
            left: m.col * 14.0,
            child: Text(
              m.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthLabel {
  final String label;
  final int col;
  _MonthLabel({required this.label, required this.col});
}

class _HeatmapPainter extends CustomPainter {
  final Map<String, int> heatmap;
  final DateTime now;
  final int totalHabits;

  _HeatmapPainter({
    required this.heatmap,
    required this.now,
    required this.totalHabits,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 10.0;
    const gap = 4.0;

    final startDate = now.subtract(const Duration(days: 89));
    // Align to start of the week (Monday)
    final startWeekday = startDate.weekday; // 1=Mon..7=Sun

    for (int i = 0; i < 90; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final count = heatmap[dateStr] ?? 0;

      final col = (i + startWeekday - 1) ~/ 7;
      final row = (date.weekday - 1); // 0=Mon..6=Sun

      final ratio = (count / totalHabits).clamp(0.0, 1.0);
      final color = count == 0
          ? const Color(0xFF6366F1).withOpacity(0.06)
          : Color.lerp(
              const Color(0xFF6366F1).withOpacity(0.15),
              const Color(0xFF6366F1),
              ratio,
            )!;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          col * (cellSize + gap),
          row * (cellSize + gap),
          cellSize,
          cellSize,
        ),
        const Radius.circular(2.5),
      );

      canvas.drawRRect(rect, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
