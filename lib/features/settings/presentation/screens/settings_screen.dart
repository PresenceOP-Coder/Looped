import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants.dart';
import '../../../../core/notification_service.dart';
import '../../../../core/theme_provider.dart';
import '../../../habits/domain/habit_model.dart';
import '../../../habits/providers/habit_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final borderColor = theme.dividerColor;
    final subtitleColor = theme.colorScheme.onSurface.withOpacity(0.5);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Appearance ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('APPEARANCE', subtitleColor),
                    const SizedBox(height: 12),
                    _settingsCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      children: [
                        _themeTile(
                          context: context,
                          label: 'Light',
                          icon: LucideIcons.sun,
                          isSelected: themeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeProvider.notifier)
                              .setThemeMode(ThemeMode.light),
                        ),
                        Divider(height: 1, color: borderColor),
                        _themeTile(
                          context: context,
                          label: 'Dark',
                          icon: LucideIcons.moon,
                          isSelected: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeProvider.notifier)
                              .setThemeMode(ThemeMode.dark),
                        ),
                        Divider(height: 1, color: borderColor),
                        _themeTile(
                          context: context,
                          label: 'System',
                          icon: LucideIcons.monitor,
                          isSelected: themeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeProvider.notifier)
                              .setThemeMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Data ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('DATA', subtitleColor),
                    const SizedBox(height: 12),
                    _settingsCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      children: [
                        _actionTile(
                          context: context,
                          icon: LucideIcons.download,
                          label: 'Export Data',
                          subtitle: 'Save your habits as JSON',
                          onTap: () => _exportData(context, ref),
                        ),
                        Divider(height: 1, color: borderColor),
                        _actionTile(
                          context: context,
                          icon: LucideIcons.trash2,
                          label: 'Reset All Data',
                          subtitle: 'Delete all habits permanently',
                          isDestructive: true,
                          onTap: () => _confirmReset(context, ref),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Notifications ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('NOTIFICATIONS', subtitleColor),
                    const SizedBox(height: 12),
                    _settingsCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      children: [
                        _actionTile(
                          context: context,
                          icon: LucideIcons.bellOff,
                          label: 'Cancel All Reminders',
                          subtitle: 'Remove all scheduled notifications',
                          onTap: () => _cancelAllReminders(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── About ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('ABOUT', subtitleColor),
                    const SizedBox(height: 12),
                    _settingsCard(
                      cardColor: cardColor,
                      borderColor: borderColor,
                      children: [
                        _infoTile(
                          context: context,
                          icon: LucideIcons.info,
                          label: 'Version',
                          value: '1.0.0',
                        ),
                        Divider(height: 1, color: borderColor),
                        _infoTile(
                          context: context,
                          icon: LucideIcons.code2,
                          label: 'Built with',
                          value: 'Flutter & Riverpod',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _settingsCard({
    required Color cardColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _themeTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.4)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(LucideIcons.check, color: theme.colorScheme.primary, size: 20)
          : null,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
          color: isDestructive
              ? Colors.red.shade400
              : theme.colorScheme.onSurface.withOpacity(0.6)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color:
              isDestructive ? Colors.red.shade400 : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight,
          size: 18, color: theme.colorScheme.onSurface.withOpacity(0.3)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _infoTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  void _exportData(BuildContext context, WidgetRef ref) {
    final habits = ref.read(habitProvider);
    final buffer = StringBuffer();
    buffer.writeln('[');
    for (int i = 0; i < habits.length; i++) {
      final h = habits[i];
      buffer.writeln('  {');
      buffer.writeln('    "name": "${h.name}",');
      buffer.writeln('    "category": "${h.category}",');
      buffer.writeln(
          '    "description": ${h.description != null ? '"${h.description}"' : 'null'},');
      buffer.writeln('    "frequency": "${h.frequency}",');
      buffer.writeln('    "targetDays": ${h.targetDays ?? '[]'},');
      buffer.writeln(
          '    "completedDates": [${h.completedDates.map((d) => '"$d"').join(', ')}],');
      buffer.writeln('    "createdAt": "${h.createdAt.toIso8601String()}",');
      buffer.writeln(
          '    "reminderTime": ${h.reminderTime != null ? '"${h.reminderTime}"' : 'null'}');
      buffer.writeln('  }${i < habits.length - 1 ? ',' : ''}');
    }
    buffer.writeln(']');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Export Data',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              buffer.toString(),
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset All Data',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'This will permanently delete all your habits and data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final box = Hive.box<Habit>(AppConstants.habitBoxName);
              await box.clear();
              await NotificationService().cancelAll();
              ref.invalidate(habitProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('All data has been reset'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: Text('Reset',
                style: TextStyle(
                    color: Colors.red.shade400, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _cancelAllReminders(BuildContext context) async {
    await NotificationService().cancelAll();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All reminders cancelled'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}
