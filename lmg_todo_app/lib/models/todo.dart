import 'package:hive/hive.dart';

enum TodoStatus { todo, inProgress, done }

class TodoStatusAdapter extends TypeAdapter<TodoStatus> {
  @override
  final int typeId = 1;

  @override
  TodoStatus read(BinaryReader reader) {
    final int index = reader.readByte();
    return TodoStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, TodoStatus obj) {
    writer.writeByte(obj.index);
  }
}

class Todo {
  final int id;
  String title;
  String description;
  int totalSeconds;
  int elapsedSeconds;
  TodoStatus status;
  DateTime createdAt;
  DateTime updatedAt;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.totalSeconds,
    required this.elapsedSeconds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isDone => status == TodoStatus.done;

  bool get isInProgress => status == TodoStatus.inProgress && !isDone;

  int get remainingSeconds {
    final int remaining = totalSeconds - elapsedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  Todo copyWith({
    String? title,
    String? description,
    int? totalSeconds,
    int? elapsedSeconds,
    TodoStatus? status,
    DateTime? updatedAt,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TodoAdapter extends TypeAdapter<Todo> {
  @override
  final int typeId = 0;

  @override
  Todo read(BinaryReader reader) {
    final int id = reader.readInt();
    final String title = reader.readString();
    final String description = reader.readString();
    final int totalSeconds = reader.readInt();
    final int elapsedSeconds = reader.readInt();
    final TodoStatus status = reader.read() as TodoStatus;
    final int createdMs = reader.readInt();
    final int updatedMs = reader.readInt();
    return Todo(
      id: id,
      title: title,
      description: description,
      totalSeconds: totalSeconds,
      elapsedSeconds: elapsedSeconds,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdMs),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedMs),
    );
  }

  @override
  void write(BinaryWriter writer, Todo obj) {
    writer
      ..writeInt(obj.id)
      ..writeString(obj.title)
      ..writeString(obj.description)
      ..writeInt(obj.totalSeconds)
      ..writeInt(obj.elapsedSeconds)
      ..write(obj.status)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}


