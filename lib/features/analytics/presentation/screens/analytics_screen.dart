import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/analytics_provider.dart';
import '../widgets/stats_cards.dart';
import '../widgets/weekly_bar_chart.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/heatmap_calendar.dart';
import '../widgets/streaks_leaderboard.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dayOfWeek = ref.watch(dayOfWeekStatsProvider);
    final stats = ref.watch(analyticsStatsProvider);
    final maxAvg = dayOfWeek.fold<double>(
        0, (max, d) => d.avgCompletions > max ? d.avgCompletions : max);
    final bestDayName = maxAvg > 0
        ? dayOfWeek
            .reduce((a, b) => a.avgCompletions > b.avgCompletions ? a : b)
            .day
        : '—';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // header
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analytics',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats.mostConsistentHabit != null
                          ? 'Most consistent: ${stats.mostConsistentHabit}'
                          : 'Track your progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // stats cards
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: StatsCardsRow(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // weakly bar chart
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: WeeklyBarChart(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // categorie donut + best day row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(child: CategoryDonutChart()),
                    const SizedBox(width: 12),
                    // best day mini card
                    SizedBox(
                      width: 100,
                      child: Container(
                        padding: const EdgeInsets.all(16),
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
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(LucideIcons.star,
                                  size: 20, color: Color(0xFFF59E0B)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              bestDayName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Best\nDay',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // heatmap
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: HeatmapCalendar(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // day of weak chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _DayOfWeekChart(data: dayOfWeek),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // streaks lederboard
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: StreaksLeaderboard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

class _DayOfWeekChart extends StatelessWidget {
  final List<DayOfWeekStat> data;
  const _DayOfWeekChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxAvg = data.fold<double>(
        0, (max, d) => d.avgCompletions > max ? d.avgCompletions : max);
    final maxY = (maxAvg + 0.5).clamp(1.0, double.infinity);

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
          Text(
            'Best Days',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Avg completions by weekday',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final isBest =
                            data[idx].avgCompletions == maxAvg && maxAvg > 0;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[idx].day,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  isBest ? FontWeight.w800 : FontWeight.w500,
                              color: isBest
                                  ? const Color(0xFF10B981)
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.4),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  final isBest = data[i].avgCompletions == maxAvg && maxAvg > 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[i].avgCompletions,
                        width: 22,
                        borderRadius: BorderRadius.circular(8),
                        color: isBest
                            ? const Color(0xFF10B981)
                            : const Color(0xFF10B981).withOpacity(0.2),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
