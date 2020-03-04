import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:worker_manager/scheduler.dart';
import 'package:worker_manager/task.dart';

import 'isolate.dart';

abstract class Executor {
  factory Executor() => _WorkerManager(Scheduler.regular());

  Future<void> warmUp();

  Stream<O> addTask<A, B, C, D, O>(
      {@required Task<A, B, C, D, O> task, WorkPriority priority = WorkPriority.high});

  void removeTask<A, B, C, D, O>({@required Task<A, B, C, D, O> task});
}

class _WorkerManager implements Executor {
  Scheduler _scheduler;

  static final _WorkerManager _manager = _WorkerManager._internal();

  factory _WorkerManager(Scheduler scheduler) {
    _manager._scheduler ??= scheduler;
    if (_manager._scheduler.isolates.isEmpty) {
      final processors = Platform.numberOfProcessors;
      for (int i = 0; i < (processors < 2 ? 1 : processors - 1); i++) {
        _manager._scheduler.isolates.add(WorkerIsolate.worker()..initPortConnection());
      }
    }
    return _manager;
  }

  _WorkerManager._internal();

  @override
  Stream<O> addTask<A, B, C, D, O>(
      {Task<A, B, C, D, O> task, WorkPriority priority = WorkPriority.high}) {
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
    if (_scheduler.queue.length == 1) _scheduler.manageQueue<A, B, C, D, O>(_scheduler.queue.first);
    return Stream.fromFuture(task.completer.future);
  }

  @override
  void removeTask<A, B, C, D, O>({Task<A, B, C, D, O> task}) {
    if (_scheduler.queue.contains(task)) _scheduler.queue.remove(task);
    final targetIsolate =
        _scheduler.isolates.firstWhere((isolate) => isolate.taskId == task.id, orElse: () => null);
    if (targetIsolate != null) targetIsolate.cancel();
  }

  @override
  Future<void> warmUp() => _scheduler.warmUpCallback();
}
