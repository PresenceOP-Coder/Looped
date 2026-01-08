import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 0)
class Habit extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final List<String> completedDates;

  @HiveField(4)
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.completedDates,
    required this.createdAt,
  });
  factory Habit.create({required String name, required String category}) {
    return Habit(
      id: const Uuid().v4(),
      name: name,
      category: category,
      completedDates: [],
      createdAt: DateTime.now(),
    );
  }

  bool isCompletedToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return completedDates.contains(today);
  }

  Habit copyWith({
    String? name,
    String? category,
    List<String>? completedDates,
  }) {
    return Habit(
        id: id,
        name: name ?? this.name,
        category: category ?? this.category,
        completedDates: completedDates ?? this.completedDates,
        createdAt: createdAt
        );
  }
}
