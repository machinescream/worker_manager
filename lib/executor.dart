import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:worker_manager/runnable.dart';
import 'package:worker_manager/scheduler.dart';

import 'isolate.dart';

enum WorkPriority { high, low, regular }

class Task1<A, O> extends Task<A, Object, Object, Object, O> {
  final Runnable<A, Object, Object, Object, O> runnable;
  final Duration timeout;

  Task1({this.runnable, this.timeout}) : super(runnable: runnable, timeout: timeout);
}

class Task2<A, B, O> extends Task<A, B, Object, Object, O> {
  final Runnable<A, B, Object, Object, O> runnable;
  final Duration timeout;

  Task2({this.runnable, this.timeout}) : super(runnable: runnable, timeout: timeout);
}

class Task3<A, B, C, O> extends Task<A, B, C, Object, O> {
  final Runnable<A, B, C, Object, O> runnable;
  final Duration timeout;

  Task3({this.runnable, this.timeout}) : super(runnable: runnable, timeout: timeout);
}

class Task<A, B, C, D, O> {
  final Runnable<A, B, C, D, O> runnable;
  final Duration timeout;
  final completer = Completer<O>();
  final id = Uuid().v4();

  void cancel() => Executor()._removeTask(task: this);

  Task({this.runnable, this.timeout});
}

abstract class Executor {
  factory Executor() => _WorkerManager(Scheduler.regular());

  Future<void> warmUp();

  Stream<O> addTask<O>(
      {@required Task<Object, Object, Object, Object, O> task,
      WorkPriority priority = WorkPriority.high});

  void _removeTask<O>({@required Task<Object, Object, Object, Object, O> task});
}

class _WorkerManager implements Executor {
  RegularScheduler _scheduler;

  static final _WorkerManager _manager = _WorkerManager._internal();

  factory _WorkerManager(RegularScheduler scheduler) {
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
  Stream<O> addTask<O>(
      {Task<Object, Object, Object, Object, O> task, WorkPriority priority = WorkPriority.high}) {
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
    if (_scheduler.queue.length == 1) _scheduler.manageQueue<O>(_scheduler.queue.first);
    return Stream.fromFuture(task.completer.future);
  }

  @override
  void _removeTask<O>({Task<Object, Object, Object, Object, O> task}) {
    if (_scheduler.queue.contains(task)) _scheduler.queue.remove(task);
    final targetIsolate =
        _scheduler.isolates.firstWhere((isolate) => isolate.taskId == task.id, orElse: () => null);
    if (targetIsolate != null) targetIsolate.cancel();
  }

  @override
  Future<void> warmUp() => _scheduler.warmUp();
}
