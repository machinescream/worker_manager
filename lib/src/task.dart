import 'dart:async';

import 'package:worker_manager/src/runnable.dart';
import 'package:worker_manager/src/work_priority.dart';

class Task<A, B, C, D, O> implements Comparable<Task> {
  final Runnable<A, B, C, D, O> runnable;
  final resultCompleter = Completer<O>();
  final int number;
  final WorkPriority workPriority;

  Task(
    this.number, {
    required this.runnable,
    this.workPriority = WorkPriority.high,
  });

  @override
  int compareTo(Task other) {
    final index = WorkPriority.values.indexOf;
    return index(workPriority) - index(other.workPriority);
  }
}
