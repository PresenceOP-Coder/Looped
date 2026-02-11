import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../widgets/add_habit_modal.dart';
import '../widgets/custom_bottom_bar.dart';
import 'home_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  static const _pages = [
    HomeScreen(),
    SettingsScreen(),
    AnalyticsScreen(),
  ];

  void _showAddHabitModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddHabitModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomBar(
        selectedIndex: _selectedIndex,
        onTabTap: (index) => setState(() => _selectedIndex = index),
        onAddHabitTap: _showAddHabitModal,
        onAnalyticsTap: () => setState(() => _selectedIndex = 2),
        items: const [
          CustomBottomBarItem(index: 0, icon: LucideIcons.home, label: 'Home'),
          CustomBottomBarItem(
              index: 1, icon: LucideIcons.settings, label: 'Settings'),
        ],
      ),
    );
  }
}
