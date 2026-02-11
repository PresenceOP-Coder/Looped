import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_flow/core/notification_service.dart';
import 'package:habit_flow/core/theme.dart';
import 'package:habit_flow/core/theme_provider.dart';
import 'package:habit_flow/features/habits/presentation/screens/app_shell.dart';
import 'package:habit_flow/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'features/habits/domain/habit_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(HabitAdapter());
  }

  try {
    await Hive.openBox<Habit>(AppConstants.habitBoxName);
  } catch (e) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final boxFile = File('${dir.path}/${AppConstants.habitBoxName}.hive');
      final lockFile = File('${dir.path}/${AppConstants.habitBoxName}.lock');
      if (await boxFile.exists()) await boxFile.delete();
      if (await lockFile.exists()) await lockFile.delete();
    } catch (_) {}
    await Hive.openBox<Habit>(AppConstants.habitBoxName);
  }

  // Initialize notification service
  await NotificationService().init();

  // Check if onboarding has been completed
  final prefs = await SharedPreferences.getInstance();
  final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;

  runApp(
    ProviderScope(
      child: HabitFlowApp(showOnboarding: !onboardingSeen),
    ),
  );
}

class HabitFlowApp extends ConsumerWidget {
  final bool showOnboarding;

  const HabitFlowApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'HabitFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: showOnboarding ? const OnboardingScreen() : const AppShell(),
    );
  }
}
