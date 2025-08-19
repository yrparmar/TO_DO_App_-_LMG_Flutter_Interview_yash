import 'package:hive_flutter/hive_flutter.dart';
import '../models/todo.dart';

class TodoRepository {
  static const String todosBoxName = 'todos';

  Box<Todo>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TodoStatusAdapter());
    Hive.registerAdapter(TodoAdapter());
    _box = await Hive.openBox<Todo>(todosBoxName);
  }

  Box<Todo> get _todosBox {
    final box = _box;
    if (box == null) {
      throw StateError('TodoRepository not initialized. Call init() first.');
    }
    return box;
  }

  List<Todo> getAll() {
    return _todosBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> add(Todo todo) async {
    await _todosBox.put(todo.id, todo);
  }

  Future<void> update(Todo todo) async {
    await _todosBox.put(todo.id, todo);
  }

  Future<void> delete(int id) async {
    await _todosBox.delete(id);
  }

  Future<void> clear() async {
    await _todosBox.clear();
  }
}


