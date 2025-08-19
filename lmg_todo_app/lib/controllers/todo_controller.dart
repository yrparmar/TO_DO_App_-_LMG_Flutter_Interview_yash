import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/todo_repository.dart';
import '../models/todo.dart';

class TodoController extends ChangeNotifier {
  TodoController(this._repository);

  final TodoRepository _repository;

  final List<Todo> _todos = <Todo>[];
  Timer? _ticker;
  bool _isTicking = false;
  final Set<int> _playingTodoIds = <int>{};

  List<Todo> get todos => List.unmodifiable(_todos);

  Future<void> init() async {
    await _repository.init();
    _todos
      ..clear()
      ..addAll(_repository.getAll());
    _ensureTicker();
    notifyListeners();
  }

  void _ensureTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!_isTicking) return;
    bool changed = false;
    for (int i = 0; i < _todos.length; i++) {
      final todo = _todos[i];
      if (_playingTodoIds.contains(todo.id) &&
          todo.status == TodoStatus.inProgress &&
          todo.elapsedSeconds < todo.totalSeconds) {
        final int newElapsed = todo.elapsedSeconds + 1;
        if (newElapsed >= todo.totalSeconds) {
          _todos[i] = todo.copyWith(
            elapsedSeconds: todo.totalSeconds,
            status: TodoStatus.done,
            updatedAt: DateTime.now(),
          );
          _playingTodoIds.remove(todo.id);
        } else {
          _todos[i] = todo.copyWith(
            elapsedSeconds: newElapsed,
            updatedAt: DateTime.now(),
          );
        }
        changed = true;
      }
    }
    if (changed) {
      _persistAllDebounced();
      notifyListeners();
    }
  }

  Timer? _debounce;
  void _persistAllDebounced() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      for (final t in _todos) {
        await _repository.update(t);
      }
    });
  }

  int _nextId() {
    if (_todos.isEmpty) return 1;
    return (_todos.map((e) => e.id).reduce((a, b) => a > b ? a : b)) + 1;
  }

  Future<void> addTodo({
    required String title,
    String description = '',
    required int totalSeconds,
  }) async {
    final now = DateTime.now();
    final todo = Todo(
      id: _nextId(),
      title: title,
      description: description,
      totalSeconds: totalSeconds,
      elapsedSeconds: 0,
      status: TodoStatus.todo,
      createdAt: now,
      updatedAt: now,
    );
    _todos.insert(0, todo);
    await _repository.add(todo);
    notifyListeners();
  }

  Future<void> updateTodo(int id, {
    String? title,
    String? description,
    int? totalSeconds,
  }) async {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;
    var todo = _todos[index];
    final int newTotal = totalSeconds ?? todo.totalSeconds;
    final int clampedElapsed = todo.elapsedSeconds.clamp(0, newTotal);
    todo = todo.copyWith(
      title: title,
      description: description,
      totalSeconds: newTotal,
      elapsedSeconds: clampedElapsed,
      updatedAt: DateTime.now(),
    );
    _todos[index] = todo;
    await _repository.update(todo);
    notifyListeners();
  }

  Future<void> deleteTodo(int id) async {
    _todos.removeWhere((t) => t.id == id);
    await _repository.delete(id);
    notifyListeners();
  }

  void startTimer(int id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final todo = _todos[index];
    if (todo.status == TodoStatus.done) return;
    if (todo.elapsedSeconds >= todo.totalSeconds) return;
    _todos[index] = todo.copyWith(status: TodoStatus.inProgress, updatedAt: DateTime.now());
    _playingTodoIds.add(id);
    _isTicking = _playingTodoIds.isNotEmpty;
    notifyListeners();
  }

  void pauseTimer(int id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final todo = _todos[index];
    if (todo.status != TodoStatus.inProgress) return;
    _todos[index] = todo.copyWith(updatedAt: DateTime.now());
    _playingTodoIds.remove(id);
    _isTicking = _playingTodoIds.isNotEmpty;
    notifyListeners();
  }

  void stopTimer(int id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index == -1) return;
    final todo = _todos[index];
    _todos[index] = todo.copyWith(
      elapsedSeconds: todo.totalSeconds,
      status: TodoStatus.done,
      updatedAt: DateTime.now(),
    );
    _playingTodoIds.remove(id);
    _isTicking = _playingTodoIds.isNotEmpty;
    _repository.update(_todos[index]);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}


