import 'dart:async';
import 'package:worker_manager/src/scheduling/work_priority.dart';
import 'package:worker_manager/src/port/send_port.dart';

typedef ExecuteWithPort<R> = FutureOr<R> Function(SendPort port);
typedef Execute<R> = FutureOr<R> Function();

abstract class Task<R> implements Comparable<TaskRegular<R>> {
  final String id;
  final Completer<R> completer;
  final WorkPriority workPriority;

  Task({
    required this.id,
    required this.completer,
    this.workPriority = WorkPriority.high,
  });

  @override
  int compareTo(TaskRegular other) {
    final index = WorkPriority.values.indexOf;
    return index(workPriority) - index(other.workPriority);
  }

  @override
  bool operator ==(covariant TaskRegular other) {
    return other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Function get execution;
}

class TaskRegular<R> extends Task<R> {
  @override
  final Execute<R> execution;

  TaskRegular({
    required super.id,
    required super.completer,
    required super.workPriority,
    required this.execution,
  });
}

class TaskWithPort<R> extends Task<R> {
  @override
  final ExecuteWithPort<R> execution;
  final void Function(Object value) onMessage;

  TaskWithPort({
    required super.id,
    required super.completer,
    required super.workPriority,
    required this.execution,
    required this.onMessage,
  });
}
