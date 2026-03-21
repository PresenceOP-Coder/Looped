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
    final initial = _deadlineTime != null
        ? TimeOfDay(
            hour: int.parse(_deadlineTime!.split(':')[0]),
            minute: int.parse(_deadlineTime!.split(':')[1]),
          )
        : const TimeOfDay(hour: 21, minute: 0);

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

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Habit' : 'New Habit',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(LucideIcons.x,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  )
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                autofocus: !_isEditing,
                decoration: InputDecoration(
                  hintText: 'e.g., Read 20 pages',
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      fontSize: 14),
                  border: InputBorder.none,
                ),
                style:
                    TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: AppConstants.categoryNames
                    .map((cat) => ChoiceChip(
                          label: Text(cat),
                          selected: _selectedCategory == cat,
                          onSelected: (val) =>
                              setState(() => _selectedCategory = cat),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'FREQUENCY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['daily', 'weekly', 'custom'].map((f) {
                  final isSelected = _frequency == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        f[0].toUpperCase() + f.substring(1),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() {
                          _frequency = f;
                          if (f == 'daily') _targetDays.clear();
                        });
                      },
                    ),
                  );
                }).toList(),
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
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
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
              const SizedBox(height: 20),
              Text(
                'DEADLINE ALARM',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isTimeLocked ? null : _pickDeadlineTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _deadlineTime != null
                                ? Colors.red.shade300
                                : theme.dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.alarmClock,
                                size: 18,
                                color: _deadlineTime != null
                                    ? Colors.red.shade400
                                    : theme.colorScheme.onSurface
                                        .withOpacity(0.3)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _deadlineTime != null
                                    ? 'Alarm at $_deadlineTime if not done'
                                    : 'Set deadline alarm (optional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _deadlineTime != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: _deadlineTime != null
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface
                                          .withOpacity(0.3),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_deadlineTime != null && !isTimeLocked) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => _deadlineTime = null),
                      icon: Icon(LucideIcons.x,
                          size: 18,
                          color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  ],
                ],
              ),
              if (isTimeLocked) ...[
                const SizedBox(height: 6),
                Text(
                  'Completed today. Unmark to change deadline time.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    _isEditing ? 'Save Changes' : 'Create Habit',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
