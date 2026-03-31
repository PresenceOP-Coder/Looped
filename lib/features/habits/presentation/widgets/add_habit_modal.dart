import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants.dart';
import '../../domain/habit_model.dart';
import '../../providers/habit_provider.dart';

class AddHabitModal extends ConsumerStatefulWidget {
  final Habit? existingHabit;

  const AddHabitModal({super.key, this.existingHabit});

  @override
  ConsumerState<AddHabitModal> createState() => _AddHabitModalState();
}

class _AddHabitModalState extends ConsumerState<AddHabitModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedCategory;
  late String _frequency;
  late List<int> _targetDays;
  String? _deadlineTime;

  bool get _isEditing => widget.existingHabit != null;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingHabit?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingHabit?.description ?? '');
    _selectedCategory = widget.existingHabit?.category ?? 'Growth';
    _frequency = widget.existingHabit?.frequency ?? 'daily';
    _targetDays = List<int>.from(widget.existingHabit?.targetDays ?? []);
    _deadlineTime = widget.existingHabit?.deadlineTime;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  TimeOfDay? _parseDeadlineTime(String? value) {
    if (value == null) {
      return null;
    }

    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) return;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final effectiveTargetDays =
        (_frequency == 'custom' || _frequency == 'weekly') &&
                _targetDays.isNotEmpty
            ? _targetDays
            : null;

    if (_isEditing) {
      ref.read(habitProvider.notifier).updateHabit(
            widget.existingHabit!.id,
            name: name,
            category: _selectedCategory,
            description: description,
            frequency: _frequency,
            targetDays: effectiveTargetDays,
            clearTargetDays: effectiveTargetDays == null,
            // Reminder feature removed from the UI: always clear stored reminderTime.
            clearReminderTime: true,
            deadlineTime: _deadlineTime,
            clearDeadlineTime: _deadlineTime == null,
          );
    } else {
      ref.read(habitProvider.notifier).addHabit(
            name,
            _selectedCategory,
            description: description,
            frequency: _frequency,
            targetDays: effectiveTargetDays,
            deadlineTime: _deadlineTime,
          );
    }
    Navigator.pop(context);
  }

  Future<void> _pickDeadlineTime() async {
    final initial = _parseDeadlineTime(_deadlineTime) ??
        const TimeOfDay(hour: 21, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        _deadlineTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTimeLocked =
        _isEditing && (widget.existingHabit?.isCompletedToday() ?? false);
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final dim = onSurface.withValues(alpha: 0.45);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 36,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Habit' : 'New Habit',
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.x, color: dim),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      autofocus: !_isEditing,
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g., Read 20 pages',
                        hintStyle: TextStyle(color: dim, fontSize: 24),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      style: TextStyle(color: dim, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Description (optional)',
                        hintStyle: TextStyle(color: dim.withValues(alpha: 0.9)),
                        border: InputBorder.none,
                      ),
                    ),
                    _sectionLabel(context, 'Category'),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: AppConstants.categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.45,
                      ),
                      itemBuilder: (context, index) {
                        final cat = AppConstants.categories[index];
                        final isActive = _selectedCategory == cat.name;
                        return _habitChip(
                          label: cat.name,
                          accent: cat.color,
                          isActive: isActive,
                          onTap: () =>
                              setState(() => _selectedCategory = cat.name),
                        );
                      },
                    ),
                    _sectionLabel(context, 'Frequency'),
                    Row(
                      children: List.generate(3, (index) {
                        final f = ['daily', 'weekly', 'custom'][index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: index < 2 ? 8 : 0),
                            child: _frequencyChip(
                              label: f[0].toUpperCase() + f.substring(1),
                              isActive: _frequency == f,
                              onTap: () {
                                setState(() {
                                  _frequency = f;
                                  if (f == 'daily') _targetDays.clear();
                                });
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    if (_frequency == 'weekly' || _frequency == 'custom') ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        children: List.generate(7, (i) {
                          final day = i + 1;
                          final isSelected = _targetDays.contains(day);
                          return FilterChip(
                            label: Text(
                              _dayLabels[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: primary.withValues(alpha: 0.14),
                            checkmarkColor: primary,
                            side: BorderSide(
                              color: isSelected
                                  ? primary.withValues(alpha: 0.45)
                                  : theme.dividerColor,
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _targetDays.add(day);
                                } else {
                                  _targetDays.remove(day);
                                }
                                _targetDays.sort();
                              });
                            },
                          );
                        }),
                      ),
                    ],
                    _sectionLabel(context, 'Deadline Alarm'),
                    GestureDetector(
                      onTap: isTimeLocked ? null : _pickDeadlineTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          border: Border.all(
                            color: _deadlineTime != null
                                ? Colors.red.shade300
                                : theme.dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.alarmClock,
                                color: _deadlineTime != null
                                    ? Colors.red.shade400
                                    : dim,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _deadlineTime != null
                                        ? 'Alarm at $_deadlineTime'
                                        : 'Set deadline alarm',
                                    style: TextStyle(
                                      color: _deadlineTime != null
                                          ? onSurface
                                          : dim,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    isTimeLocked
                                        ? 'Completed today. Unmark to change.'
                                        : 'Alarm rings if habit is not completed',
                                    style: TextStyle(
                                      color: dim.withValues(alpha: 0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_deadlineTime != null && !isTimeLocked)
                              IconButton(
                                onPressed: () =>
                                    setState(() => _deadlineTime = null),
                                icon: Icon(LucideIcons.x, color: dim, size: 18),
                              )
                            else
                              Icon(LucideIcons.chevronRight,
                                  color: dim, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      shadowColor: primary.withValues(alpha: 0.25),
                    ),
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Create Habit',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _habitChip({
    required String label,
    required Color accent,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? accent.withValues(alpha: 0.16)
              : theme.scaffoldBackgroundColor,
          border: Border.all(
            color: isActive ? accent : theme.dividerColor,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive) ...[
                Icon(LucideIcons.check, color: accent, size: 14),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? accent : theme.colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frequencyChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? accent.withValues(alpha: 0.18)
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isActive ? accent.withValues(alpha: 0.75) : theme.dividerColor,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isActive) ...[
                Icon(LucideIcons.check, size: 14, color: accent),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? accent : textColor.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
