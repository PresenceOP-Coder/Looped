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

  @HiveField(5)
  final String? description;

  /// 'daily', 'weekly', or 'custom'
  @HiveField(6)
  final String frequency;

  /// For custom frequency: list of weekday indices (1=Mon..7=Sun). Null for daily.
  @HiveField(7)
  final List<int>? targetDays;

  /// Manual sort position (lower = higher in list)
  @HiveField(8)
  final int sortOrder;

  /// Reminder time stored as 'HH:mm', null if no reminder
  @HiveField(9)
  final String? reminderTime;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.completedDates,
    required this.createdAt,
    this.description,
    this.frequency = 'daily',
    this.targetDays,
    this.sortOrder = 0,
    this.reminderTime,
  });

  factory Habit.create({
    required String name,
    required String category,
    String? description,
    String frequency = 'daily',
    List<int>? targetDays,
    int sortOrder = 0,
    String? reminderTime,
  }) {
    return Habit(
      id: const Uuid().v4(),
      name: name,
      category: category,
      completedDates: [],
      createdAt: DateTime.now(),
      description: description,
      frequency: frequency,
      targetDays: targetDays,
      sortOrder: sortOrder,
      reminderTime: reminderTime,
    );
  }

  bool isCompletedToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return completedDates.contains(today);
  }

  /// Whether this habit is scheduled for today based on its frequency
  bool isScheduledForToday() {
    if (frequency == 'daily') return true;
    final weekday = DateTime.now().weekday; // 1=Mon..7=Sun
    if (frequency == 'custom' && targetDays != null) {
      return targetDays!.contains(weekday);
    }
    // 'weekly' defaults to all days (treat as daily if no target days)
    if (frequency == 'weekly' && targetDays != null) {
      return targetDays!.contains(weekday);
    }
    return true;
  }

  Habit copyWith({
    String? name,
    String? category,
    List<String>? completedDates,
    String? description,
    String? frequency,
    List<int>? targetDays,
    int? sortOrder,
    String? reminderTime,
    bool clearReminderTime = false,
    bool clearTargetDays = false,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      targetDays: clearTargetDays ? null : (targetDays ?? this.targetDays),
      sortOrder: sortOrder ?? this.sortOrder,
      reminderTime:
          clearReminderTime ? null : (reminderTime ?? this.reminderTime),
    );
  }
}
