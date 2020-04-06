import 'dart:async';

import 'package:async/async.dart';
import 'package:worker_manager/runnable.dart';
import 'package:worker_manager/scheduler.dart';
import 'package:worker_manager/task.dart';

import 'isolate.dart';

abstract class Executor {
  factory Executor() => _WorkerManager(Scheduler.regular());

  Future<void> warmUp();

  CancelableOperation<O> execute<A, B, C, D, O>({
    A arg1,
    B arg2,
    C arg3,
    D arg4,
    Fun1<A, O> fun1,
    Fun2<A, B, O> fun2,
    Fun3<A, B, C, O> fun3,
    Fun4<A, B, C, D, O> fun4,
    WorkPriority priority = WorkPriority.high,
    Duration timeout,
  });
}

class _WorkerManager implements Executor {
  Scheduler _scheduler;

  static final _WorkerManager _manager = _WorkerManager._internal();

  factory _WorkerManager(Scheduler scheduler) {
    _manager._scheduler ??= scheduler;
    if (_manager._scheduler.isolates.isEmpty) {
      final processors = 1;
      for (int i = 0; i < (processors < 2 ? 1 : processors - 1); i++) {
        _manager._scheduler.isolates.add(WorkerIsolate.worker()..initPortConnection());
      }
    }
    return _manager;
  }

  _WorkerManager._internal();

  @override
  CancelableOperation<O> execute<A, B, C, D, O>(
      {A arg1,
      B arg2,
      C arg3,
      D arg4,
      Fun1<A, O> fun1,
      Fun2<A, B, O> fun2,
      Fun3<A, B, C, O> fun3,
      Fun4<A, B, C, D, O> fun4,
      WorkPriority priority = WorkPriority.high,
      Duration timeout}) {
    final task = Task(
        runnable: Runnable(
          arg1: arg1,
          arg2: arg2,
          arg3: arg3,
          arg4: arg4,
          fun1: fun1,
          fun2: fun2,
          fun3: fun3,
          fun4: fun4,
        ),
        timeout: timeout);
    final queueLength = _scheduler.queue.length;
    switch (priority) {
      case WorkPriority.high:
        _scheduler.queue.insert(0, task);
        break;
      case WorkPriority.low:
        _scheduler.queue.insert(queueLength, task);
        break;
      case WorkPriority.regular:
        _scheduler.queue.insert((queueLength / 2).floor(), task);
        break;
    }
    if (_scheduler.queue.length == 1) _scheduler.manageQueue(_scheduler.queue.first);
    return CancelableOperation<O>.fromFuture(task.completer.future,
        onCancel: () => _removeTask(task: task));
  }

  void _removeTask<A, B, C, D, O>({Task<A, B, C, D, O> task}) {
    if (_scheduler.queue.contains(task)) _scheduler.queue.remove(task);
    final targetIsolate =
        _scheduler.isolates.firstWhere((isolate) => isolate.taskId == task.id, orElse: () => null);
    if (targetIsolate != null) targetIsolate.cancel();
  }

  @override
  Future<void> warmUp() => _scheduler.warmUpCallback();
}
