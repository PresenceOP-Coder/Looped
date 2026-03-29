import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looped/core/notification_service.dart';
import 'package:looped/core/alarm_service.dart';
import 'package:looped/core/alarm_prompt_screen.dart';
import 'package:looped/core/theme.dart';
import 'package:looped/core/theme_provider.dart';
import 'package:looped/features/habits/presentation/screens/app_shell.dart';
import 'package:looped/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants.dart';
import 'features/habits/domain/habit_model.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  await NotificationService().init();
  await AlarmService().init();
  await AlarmService().requestExactAlarmPermission();
  await AlarmService().requestBatteryOptimizationExemption();

  final habitBox = Hive.box<Habit>(AppConstants.habitBoxName);
  await AlarmService().rescheduleAllDeadlineAlarms(habitBox.values.toList());

  final prefs = await SharedPreferences.getInstance();
  final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
  final alarmRinging = prefs.getBool('alarm_ringing') ?? false;

  runApp(
    ProviderScope(
      child: HabitFlowApp(
        showOnboarding: !onboardingSeen,
        showStopAlarmPrompt: alarmRinging,
      ),
    ),
  );
}

class HabitFlowApp extends ConsumerStatefulWidget {
  final bool showOnboarding;
  final bool showStopAlarmPrompt;

  const HabitFlowApp({
    super.key,
    required this.showOnboarding,
    required this.showStopAlarmPrompt,
  });

  @override
  ConsumerState<HabitFlowApp> createState() => _HabitFlowAppState();
}

class _HabitFlowAppState extends ConsumerState<HabitFlowApp> {
  StreamSubscription<bool>? _alarmPromptSub;
  bool _dialogOpen = false;

  void _showStopAlarmPrompt() {
    if (_dialogOpen) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    _dialogOpen = true;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (ctx) => const AlarmPromptScreen(),
    ).then((_) {
      _dialogOpen = false;
    });
  }

  void _hideStopAlarmPrompt() {
    if (!_dialogOpen) return;
    _dialogOpen = false;
    if (navigatorKey.currentState?.canPop() ?? false) {
      navigatorKey.currentState!.pop();
    }
  }

  @override
  void initState() {
    super.initState();

    _alarmPromptSub = AlarmService().alarmPromptStream.listen((visible) {
      if (!mounted) return;
      if (visible) {
        _showStopAlarmPrompt();
      } else {
        _hideStopAlarmPrompt();
      }
    });

    if (widget.showStopAlarmPrompt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showStopAlarmPrompt();
      });
    }
  }

  @override
  void dispose() {
    _alarmPromptSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Looped',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      navigatorKey: navigatorKey,
      home: widget.showOnboarding ? const OnboardingScreen() : const AppShell(),
    );
  }
}
