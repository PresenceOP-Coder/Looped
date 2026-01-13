import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../providers/habit_provider.dart';

class AddHabitModal extends ConsumerStatefulWidget {
  const AddHabitModal({super.key});

  @override
  ConsumerState<AddHabitModal> createState() => _AddHabitModalState();
}

class _AddHabitModalState extends ConsumerState<AddHabitModal> {
  final _controller = TextEditingController();
  String _selectedCategory = 'Growth';
  final List<String> _categories = ['Health', 'Growth', 'Mindset', 'Work'];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isEmpty) return;
    ref.read(habitProvider.notifier).addHabit(
          _controller.text.trim(),
          _selectedCategory,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Habit',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                )
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'e.g., Read 20 pages', border: InputBorder.none),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 24,
            ),
            Wrap(
              spacing: 8,
              children: _categories
                  .map((cat) => ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (val) =>
                            setState(() => _selectedCategory = cat),
                      ))
                  .toList(),
            ),
            const SizedBox(
              height: 32,
            ),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'Create Habit',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
