import 'dart:async';

import 'package:worker_manager/src/executor.dart';
import 'package:worker_manager/src/runnable.dart';

class Task<A, B, C, D, O> implements Comparable<Task> {
  final Runnable<A, B, C, D, O> runnable;
  final resultCompleter = Completer<O>();
  final int number;
  final WorkPriority workPriority;

  Task(this.number, {this.runnable, this.workPriority});

//todo: remove
  @override
  String toString() {
    return workPriority.toString();
  }

  @override
  int compareTo(Task other) {
    final index = WorkPriority.values.indexOf;
    return index(workPriority) - index(other.workPriority);
  }
}
