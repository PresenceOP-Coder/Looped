import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HabitCategory {
  final String name;
  final Color color;
  final IconData icon;

  const HabitCategory({
    required this.name,
    required this.color,
    required this.icon,
  });
}

class AppConstants {
  static const String habitBoxName = 'habits_box';

  static const List<HabitCategory> categories = [
    HabitCategory(
        name: 'Health', color: Color(0xFF10B981), icon: LucideIcons.heartPulse),
    HabitCategory(
        name: 'Growth', color: Color(0xFFF59E0B), icon: LucideIcons.trendingUp),
    HabitCategory(
        name: 'Mindset', color: Color(0xFF8B5CF6), icon: LucideIcons.brain),
    HabitCategory(
        name: 'Work', color: Color(0xFF3B82F6), icon: LucideIcons.briefcase),
    HabitCategory(
        name: 'Art', color: Color(0xFFEC4899), icon: LucideIcons.palette),
    HabitCategory(
        name: 'Social', color: Color(0xFF06B6D4), icon: LucideIcons.users),
  ];

  static const HabitCategory _defaultCategory = HabitCategory(
    name: 'Other',
    color: Color(0xFF6366F1),
    icon: LucideIcons.star,
  );

  static HabitCategory getCategory(String name) {
    return categories.cast<HabitCategory?>().firstWhere(
              (c) => c!.name == name,
              orElse: () => null,
            ) ??
        _defaultCategory;
  }

  static List<String> get categoryNames =>
      categories.map((c) => c.name).toList();
}
