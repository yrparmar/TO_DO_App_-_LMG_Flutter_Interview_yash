import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/todo_controller.dart';
import '../models/todo.dart';

class TodoFormSheet extends StatefulWidget {
  const TodoFormSheet({super.key, this.existing});

  final Todo? existing;

  @override
  State<TodoFormSheet> createState() => _TodoFormSheetState();
}

class _TodoFormSheetState extends State<TodoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  int _minutes = 0;
  int _seconds = 30;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _descController = TextEditingController(text: widget.existing?.description ?? '');
    if (widget.existing != null) {
      final total = widget.existing!.totalSeconds;
      _minutes = total ~/ 60;
      _seconds = total % 60;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [Color(0xFF5B7CFA), Color(0xFF6AD4DD)]),
                      ),
                      child: const Icon(Icons.edit_note, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(widget.existing == null ? 'Add TODO' : 'Edit TODO',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text('Time (max 5:00)'),
                        ),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _QuickChip(label: '0:30', onTap: () => setState(() { _minutes = 0; _seconds = 30; })),
                              _QuickChip(label: '1:00', onTap: () => setState(() { _minutes = 1; _seconds = 0; })),
                              _QuickChip(label: '2:00', onTap: () => setState(() { _minutes = 2; _seconds = 0; })),
                              _QuickChip(label: '5:00', onTap: () => setState(() { _minutes = 5; _seconds = 0; })),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _NumberPicker(
                      label: 'min',
                      value: _minutes,
                      min: 0,
                      max: 5,
                      onChanged: (v) => setState(() => _minutes = v),
                    ),
                    const SizedBox(width: 12),
                    _NumberPicker(
                      label: 'sec',
                      value: _seconds,
                      min: 0,
                      max: 59,
                      onChanged: (v) => setState(() => _seconds = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      FilledButton.icon(
                        onPressed: _onSave,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final total = (_minutes * 60) + _seconds;
    if (total <= 0 || total > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time must be between 0:01 and 5:00')),
      );
      return;
    }
    final ctrl = context.read<TodoController>();
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (widget.existing == null) {
      await ctrl.addTodo(title: title, description: desc, totalSeconds: total);
    } else {
      await ctrl.updateTodo(widget.existing!.id, title: title, description: desc, totalSeconds: total);
    }
    if (mounted) Navigator.pop(context);
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _NumberPicker extends StatelessWidget {
  const _NumberPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              SizedBox(
                width: 42,
                child: Center(
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


