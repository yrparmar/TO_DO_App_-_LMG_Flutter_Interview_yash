import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/todo_controller.dart';
import '../models/todo.dart';
import '../utils/time_format.dart';
import '../widgets/todo_form_sheet.dart';
import 'todo_details_page.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  TodoStatus? _filter; // null = All
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoController>(
      builder: (context, ctrl, _) {
        final todos = ctrl.todos;
        final List<Todo> filteredByStatus = _filter == null
            ? todos
            : todos.where((t) => t.status == _filter).toList();
        final String normalizedQuery = _query.toLowerCase();
        final List<Todo> visible = normalizedQuery.isEmpty
            ? filteredByStatus
            : filteredByStatus
                .where((t) => t.title.toLowerCase().contains(normalizedQuery))
                .toList();
        return Scaffold(
          appBar: AppBar(
            title: const Text('My TODOs'),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5B7CFA), Color(0xFF6AD4DD)],
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                  } catch (_) {}
                },
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by title',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _query = ''),
                          ),
                  ),
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FilterChips(
                  current: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: visible.isEmpty
                    ? (todos.isEmpty
                        ? _EmptyState(onAdd: () => _openAddSheet(context))
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'No matching todos',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final todo = visible[index];
                          return _TodoListItem(todo: todo);
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add TODO'),
          ),
        );
      },
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const TodoFormSheet(),
    ).then((result) {
      if (!mounted) return;
      if (result == 'added') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo added successfully')),
        );
      } else if (result == 'updated') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo updated successfully')),
        );
      }
    });
  }
}

class _TodoListItem extends StatelessWidget {
  const _TodoListItem({required this.todo});
  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TodoController>();
    final Color chipColor;
    final String chipLabel;
    switch (todo.status) {
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

    final double progress = todo.totalSeconds == 0
        ? 0
        : (todo.elapsedSeconds / todo.totalSeconds).clamp(0.0, 1.0);

    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (d) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete TODO'),
                content: const Text('Are you sure you want to delete this TODO?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => controller.deleteTodo(todo.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TodoDetailsPage(todoId: todo.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todo.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (todo.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              todo.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: chipColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(chipLabel),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer, size: 16),
                                  const SizedBox(width: 4),
                                  Text(formatMmSs(todo.remainingSeconds)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _InlineActions(todo: todo),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      todo.status == TodoStatus.done
                          ? Colors.green
                          : const Color(0xFF5B7CFA),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineActions extends StatelessWidget {
  const _InlineActions({required this.todo});
  final Todo todo;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<TodoController>();
    final bool isPlaying = todo.status == TodoStatus.inProgress;
    final bool isDone = todo.status == TodoStatus.done;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: isPlaying ? 'Pause' : 'Start',
          onPressed: isDone
              ? null
              : () => isPlaying ? ctrl.pauseTimer(todo.id) : ctrl.startTimer(todo.id),
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'Edit',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => TodoFormSheet(existing: todo),
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Delete',
          onPressed: () async {
            final bool confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete TODO'),
                    content: const Text('Are you sure you want to delete this TODO?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                ) ??
                false;
            if (confirm) context.read<TodoController>().deleteTodo(todo.id);
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.current, required this.onChanged});
  final TodoStatus? current;
  final ValueChanged<TodoStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          selected: current == null,
          label: const Text('All'),
          onSelected: (_) => onChanged(null),
        ),
        ChoiceChip(
          selected: current == TodoStatus.todo,
          label: const Text('TODO'),
          onSelected: (_) => onChanged(TodoStatus.todo),
        ),
        ChoiceChip(
          selected: current == TodoStatus.inProgress,
          label: const Text('In-Progress'),
          onSelected: (_) => onChanged(TodoStatus.inProgress),
        ),
        ChoiceChip(
          selected: current == TodoStatus.done,
          label: const Text('Done'),
          onSelected: (_) => onChanged(TodoStatus.done),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B7CFA), Color(0xFF6AD4DD)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.checklist_rounded, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'No todos yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the button below to add your first task',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add TODO'),
            ),
          ],
        ),
      ),
    );
  }
}


