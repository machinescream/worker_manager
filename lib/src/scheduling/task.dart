import 'dart:async';
import 'package:worker_manager/worker_manager.dart';

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

  var _canceled = false;

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
  //todo: could be Execute<R> ?
  Function get execution;

  bool get canceled => _canceled;

  void cancel() {
    if(!completer.isCompleted){
      _canceled = true;
      completer.completeError(CanceledError());
    }
  }

  void complete(R? value, Object? error, StackTrace? st){
    if(completer.isCompleted) return;
    if(error != null){
      completer.completeError(error, st);
      return;
    }
    completer.complete(value);
  }
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
