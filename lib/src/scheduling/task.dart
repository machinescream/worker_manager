import 'dart:async';
import 'package:worker_manager/src/scheduling/work_priority.dart';
import 'package:worker_manager/src/port/send_port.dart';

typedef Execute<R> = FutureOr<R> Function();
typedef ExecuteWithPort<R> = FutureOr<R> Function(SendPort port);
typedef ExecuteGentle<R> = FutureOr<R> Function(bool Function());
typedef ExecuteGentleWithPort<R> = FutureOr<R> Function(
  SendPort port,
  bool Function(),
);

abstract class Task<R> implements Comparable<Task<R>> {
  final String id;
  final Completer<R> completer;
  final WorkPriority workPriority;

  Task({
    required this.id,
    required this.completer,
    this.workPriority = WorkPriority.high,
  });

  @override
  int compareTo(covariant Task other) {
    final index = WorkPriority.values.indexOf;
    return index(workPriority) - index(other.workPriority);
  }

  @override
  bool operator ==(covariant Task other) {
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

abstract class WithPort {
  Function(Object value) get onMessage;
}

class TaskWithPort<R> extends Task<R> implements WithPort {
  @override
  final ExecuteWithPort<R> execution;
  @override
  final void Function(Object value) onMessage;

  TaskWithPort({
    required super.id,
    required super.completer,
    required super.workPriority,
    required this.execution,
    required this.onMessage,
  });
}

abstract class Gentle {}

class TaskGentle<R> extends Task<R> implements Gentle {
  @override
  final ExecuteGentle<R> execution;

  TaskGentle({
    required super.id,
    required super.completer,
    required super.workPriority,
    required this.execution,
  });
}

class TaskGentleWithPort<R> extends Task<R> implements WithPort, Gentle {
  @override
  final ExecuteGentleWithPort<R> execution;
  @override
  final void Function(Object value) onMessage;

  TaskGentleWithPort({
    required super.id,
    required super.completer,
    required super.workPriority,
    required this.execution,
    required this.onMessage,
  });
}
