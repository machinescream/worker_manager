import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:worker_manager/isolate.dart';
import 'package:worker_manager/scheduler.dart';
import 'package:worker_manager/task.dart';

enum WorkPriority { high, low, regular }

abstract class Executor {
  factory Executor({int isolatePoolSize = 1}) => _WorkerManager(isolatePoolSize: isolatePoolSize);

  Future<void> warmUp();

  Stream<O> addTask<O>({@required Task<O> task, WorkPriority priority = WorkPriority.high});

  void removeTask({@required Task task});

  void stop();
}

class _WorkerManager implements Executor {
  int isolatePoolSize;
  final _scheduler = Scheduler.regular();

  static final _WorkerManager _manager = _WorkerManager._internal();

  factory _WorkerManager({isolatePoolSize = 1}) {
    if (_manager.isolatePoolSize == null) {
      _manager.isolatePoolSize = isolatePoolSize;
      for (int i = 0; i < _manager.isolatePoolSize; i++) {
        _manager._scheduler.isolates.add(WorkerIsolate.worker()..initPortConnection());
      }
    }
    return _manager;
  }

  _WorkerManager._internal();

  @override
  Stream<O> addTask<O>({Task task, WorkPriority priority = WorkPriority.high}) {
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
    if (_scheduler.queue.length == 1) _scheduler.manageQueue();
    return Stream.fromFuture(task.completer.future);
  }

  @override
  void removeTask({Task task}) {
    if (_scheduler.queue.contains(task)) _scheduler.queue.remove(task);
    final targetIsolate =
        _scheduler.isolates.firstWhere((isolate) => isolate.taskId == task.id, orElse: () => null);
    if (targetIsolate != null) targetIsolate.cancel();
  }

  @override
  void stop() {
    _scheduler.isolates.forEach((isolate) {
      isolate.cancel();
    });
    _scheduler.isolates.clear();
    _scheduler.queue.clear();
  }

  @override
  Future<void> warmUp() => _scheduler.warmUp();
}
