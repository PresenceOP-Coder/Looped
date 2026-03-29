import 'package:flutter/material.dart';

import 'alarm_service.dart';

class AlarmPromptScreen extends StatelessWidget {
  final String title;
  final String description;

  const AlarmPromptScreen({
    super.key,
    this.title = 'Stop Alarm?',
    this.description =
        'Current timer is complete.\nTap anywhere to stop the alarm.',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.primaryContainer.withOpacity(0.95);
    final accent = theme.colorScheme.primary;
    final onBg = theme.colorScheme.onPrimaryContainer;
    final onAccent = theme.colorScheme.onPrimary;

    return Material(
      color: bgColor,
      child: SizedBox.expand(
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await AlarmService().stopAlarm();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_active_rounded,
                  size: 64,
                  color: accent,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: onBg.withOpacity(0.9),
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: SizedBox(
                      width: 170,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          await AlarmService().stopAlarm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: onAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Stop alarm',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
