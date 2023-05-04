import 'dart:async';

import 'package:worker_manager/src/scheduling/work_priority.dart';

final class Task<R> implements Comparable<Task<R>> {
  final String id;
  final FutureOr<R> Function() execution;
  final Completer<R> completer;
  final WorkPriority workPriority;
  // final Function? onUpdateProgress;

  Task({
    required this.id,
    required this.execution,
    required this.completer,
    this.workPriority = WorkPriority.high,
    // this.onUpdateProgress,
  });

  @override
  int compareTo(Task other) {
    final index = WorkPriority.values.indexOf;
    return index(workPriority) - index(other.workPriority);
  }

  @override
  bool operator ==(covariant Task other) {
    return other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
