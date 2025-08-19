import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/todo_controller.dart';
import '../models/todo.dart';
import '../utils/time_format.dart';
import '../widgets/todo_form_sheet.dart';

class TodoDetailsPage extends StatelessWidget {
  const TodoDetailsPage({super.key, required this.todoId});
  final int todoId;

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoController>(
      builder: (context, ctrl, _) {
        final todo = ctrl.todos.firstWhere((t) => t.id == todoId);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Todo Details'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _openEditSheet(context, todo),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _ProgressRing(todo: todo),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(todo.title, style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(height: 8),
                if (todo.description.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      todo.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black87),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined),
                    const SizedBox(width: 8),
                    Text('Remaining: ${formatMmSs(todo.remainingSeconds)}'),
                  ],
                ),
                const SizedBox(height: 12),
                _StatusChip(status: todo.status),
                const Spacer(),
                _Controls(todo: todo),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openEditSheet(BuildContext context, Todo todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TodoFormSheet(existing: todo),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final TodoStatus status;

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    String chipLabel;
    switch (status) {
      case TodoStatus.todo:
        chipColor = Colors.grey.shade300;
        chipLabel = 'TODO';
        break;
      case TodoStatus.inProgress:
        chipColor = Colors.blue.shade100;
        chipLabel = 'In-Progress';
        break;
      case TodoStatus.done:
        chipColor = Colors.green.shade200;
        chipLabel = 'Done';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(chipLabel),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.todo});
  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<TodoController>();
    final bool isDone = todo.status == TodoStatus.done;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton.icon(
          onPressed: isDone ? null : () => ctrl.startTimer(todo.id),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play'),
        ),
        OutlinedButton.icon(
          onPressed: todo.status == TodoStatus.inProgress ? () => ctrl.pauseTimer(todo.id) : null,
          icon: const Icon(Icons.pause),
          label: const Text('Pause'),
        ),
        FilledButton.tonalIcon(
          onPressed: isDone ? null : () => ctrl.stopTimer(todo.id),
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.todo});
  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final double progress = todo.totalSeconds == 0
        ? 0
        : (todo.elapsedSeconds / todo.totalSeconds).clamp(0.0, 1.0);
    return SizedBox(
      height: 180,
      width: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatMmSs(todo.remainingSeconds),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text('${(progress * 100).round()}% completed'),
            ],
          )
        ],
      ),
    );
  }
}


