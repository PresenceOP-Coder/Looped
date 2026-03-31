import 'package:shared_preferences/shared_preferences.dart';

class StreakFreezeService {
  static final StreakFreezeService _instance = StreakFreezeService._();
  factory StreakFreezeService() => _instance;
  StreakFreezeService._();

  static const int monthlyFreezeLimit = 3;

  String _monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _freezeUsedKey(String month) => 'freeze_used_$month';
  String _freezeEntriesKey(String month) => 'freeze_entries_$month';
  String _autoFreezeRanKey(String date) => 'auto_freeze_ran_$date';
  String _recoveryUntilKey(String habitId) => 'recovery_until_$habitId';

  Future<int> getUsedForMonth(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final month = _monthKey(date);
    return prefs.getInt(_freezeUsedKey(month)) ?? 0;
  }

  Future<int> getRemainingForCurrentMonth() async {
    final used = await getUsedForMonth(DateTime.now());
    final remaining = monthlyFreezeLimit - used;
    return remaining < 0 ? 0 : remaining;
  }

  Future<bool> canUseFreeze(DateTime date) async {
    final used = await getUsedForMonth(date);
    return used < monthlyFreezeLimit;
  }

  Future<bool> consumeFreezeForDate({
    required String habitId,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final month = _monthKey(date);
    final usedKey = _freezeUsedKey(month);
    final entriesKey = _freezeEntriesKey(month);
    final dateStr = _dateKey(date);
    final entry = '$habitId|$dateStr';

    // Check if recovery window is active
    if (await isRecoveryWindowActive(habitId)) {
      return false;
    }

    final entries = List<String>.from(prefs.getStringList(entriesKey) ?? []);
    if (entries.contains(entry)) {
      return false;
    }

    final used = prefs.getInt(usedKey) ?? 0;
    if (used >= monthlyFreezeLimit) {
      return false;
    }

    entries.add(entry);
    await prefs.setStringList(entriesKey, entries);
    await prefs.setInt(usedKey, used + 1);

    // Start recovery window: must achieve 7 consecutive completions before next freeze
    await startRecoveryWindow(
      habitId: habitId,
      duration: const Duration(days: 30),
    );

    return true;
  }

  Future<bool> shouldRunAutoFreezeForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = _dateKey(date);
    return !(prefs.getBool(_autoFreezeRanKey(dateStr)) ?? false);
  }

  Future<void> markAutoFreezeRunForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = _dateKey(date);
    await prefs.setBool(_autoFreezeRanKey(dateStr), true);
  }

  Future<void> startRecoveryWindow({
    required String habitId,
    Duration duration = const Duration(hours: 24),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(duration).millisecondsSinceEpoch;
    await prefs.setInt(_recoveryUntilKey(habitId), until);
  }

  Future<void> clearRecoveryWindow(String habitId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recoveryUntilKey(habitId));
  }

  Future<bool> isRecoveryWindowActive(String habitId) async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_recoveryUntilKey(habitId));
    if (until == null) {
      return false;
    }
    return DateTime.now().millisecondsSinceEpoch <= until;
  }
}
