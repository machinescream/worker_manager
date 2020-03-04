import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:worker_manager/runnable.dart';

import 'executor.dart';

enum WorkPriority { high, low, regular }

class Task1<A, O> extends Task<A, Object, Object, Object, O> {
  Task1({Runnable<A, Object, Object, Object, O> runnable, Duration timeout})
      : super(runnable: runnable, timeout: timeout);
}

class Task2<A, B, O> extends Task<A, B, Object, Object, O> {
  Task2({Runnable<A, B, Object, Object, O> runnable, Duration timeout})
      : super(runnable: runnable, timeout: timeout);
}

class Task3<A, B, C, O> extends Task<A, B, C, Object, O> {
  Task3({Runnable<A, B, C, Object, O> runnable, Duration timeout})
      : super(runnable: runnable, timeout: timeout);
}

class Task<A, B, C, D, O> {
  final Runnable<A, B, C, D, O> runnable;
  final Duration timeout;
  final completer = Completer<O>();
  final id = Uuid().v4();

  void cancel() => Executor().removeTask(task: this);

  Task({this.runnable, this.timeout});
}
