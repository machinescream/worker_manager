import 'dart:async';

import 'package:worker_manager/src/runnable.dart';
import 'package:worker_manager/src/work_priority.dart';

class Task<A, B, C, D, O> implements Comparable<Task> {
  final Runnable<A, B, C, D, O>? runnable;
  final resultCompleter = Completer<O>();
  final int number;
  final WorkPriority? workPriority;

  Task(this.number, {this.runnable, this.workPriority});

  @override
  int compareTo(Task other) {
    final index = WorkPriority.values.indexOf as int Function(WorkPriority?, [int]);
    return index(workPriority) - index(other.workPriority);
  }
}
