import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_flow/features/habits/presentation/screens/home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants.dart';
import 'features/habits/domain/habit_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(HabitAdapter());

  await Hive.openBox<Habit>(AppConstants.habitBoxName);

  runApp(
    const ProviderScope(
      child: HabitFlowApp(),
    ),
  );
}

class HabitFlowApp extends StatelessWidget {
  const HabitFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}