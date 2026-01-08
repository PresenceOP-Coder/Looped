import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/constants.dart';
import 'features/habits/domain/habit_model.dart';

void main() async {
  // 1. Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Hive for Flutter
  await Hive.initFlutter();

  // 3. Register the Type Adapter (This tells Hive how to read your Habit model)
  // Note: HabitAdapter is generated automatically in the next step
  Hive.registerAdapter(HabitAdapter());

  // 4. Open the Box (The actual storage file)
  await Hive.openBox<Habit>(AppConstants.habitBoxName);

  // 5. Run the app wrapped in ProviderScope for Riverpod
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
      home: const Scaffold(
        body: Center(child: Text('Step 2 Complete: Hive Initialized!')),
      ),
    );
  }
}