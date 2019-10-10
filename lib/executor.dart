import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:worker_manager/scheduler.dart';
import 'package:worker_manager/task.dart';
import 'package:worker_manager/thread.dart';

enum WorkPriority { high, low, normal }
enum Policy { fifo } //todo: add _scheduler

abstract class Executor {
  factory Executor({int threadPoolSize = 1}) => _WorkerManager(threadPoolSize: threadPoolSize);

  factory Executor.fake() => _FakeWorker();

  Future<void> warmUp();

  Stream<O> addTask<O>(
      {@required Task<O> task, bool isFifo = false, WorkPriority priority = WorkPriority.high});

  Stream<List<O>> addScopedTask<O>({@required List<Task> tasks});

  void removeTask({@required Task task});

  void stop();
}

class _WorkerManager implements Executor {
  int threadPoolSize;
  final _scheduler = Scheduler();

  static final _WorkerManager _manager = _WorkerManager._internal();

  factory _WorkerManager({threadPoolSize = 1}) {
    if (_manager.threadPoolSize == null) {
      _manager.threadPoolSize = threadPoolSize;
      for (int i = 0; i < _manager.threadPoolSize; i++) {
        _manager._scheduler.threads.add(Thread());
      }
    }
    return _manager;
  }

  _WorkerManager._internal();

  @override
  Future<void> warmUp() async =>
      await Future.wait(_scheduler.threads.map((thread) => thread.initPortConnection()));

  @override
  Stream<O> addTask<O>(
      {Task task, bool isFifo = false, WorkPriority priority = WorkPriority.high}) {
    final queue = isFifo ? _scheduler.fifoQueue : _scheduler.queue;
    priority == WorkPriority.high ? queue.addFirst(task) : queue.addLast(task);
    if (queue.length == 1) {
      isFifo ? _scheduler.manageFifoQueue() : _scheduler.manageQueue();
    }
    return Stream.fromFuture(task.completer.future);
  }

  @override
  Stream<List<O>> addScopedTask<O>({List<Task> tasks}) {
    _scheduler.queue.addAll(tasks);
    _scheduler.manageQueue();
    return Stream.fromFuture(Future.wait<O>(tasks.map((task) {
      final resultFuture = task.completer.future;
      final typedResultFuture = resultFuture as Future<O>;
      return typedResultFuture;
    })));
  }

  @override
  void removeTask({Task task}) {
    if (_scheduler.queue.contains(task)) _scheduler.queue.remove(task);
    final targetIsolate =
        _scheduler.threads.firstWhere((thread) => thread.taskId == task.id, orElse: () => null);
    if (targetIsolate != null) {
      targetIsolate.taskId = null;
      targetIsolate.isInitialized.future.then((_) {
        targetIsolate.cancel();
        _scheduler.threads.remove(targetIsolate);
        _scheduler.threads.add(Thread());
      });
    }
  }

  @override
  void stop() {
    _scheduler.threads.forEach((thread) {
      thread.cancel();
    });
    _scheduler.threads.clear();
    _scheduler.queue.clear();
  }
}

class _FakeWorker implements Executor {
  final _scheduler = Scheduler();

  @override
  Future<void> warmUp() {
    return null;
  }

  @override
  void removeTask({Task task}) {
    if (_scheduler.queue.contains(task)) _scheduler.queue.remove(task);
  }

  @override
  void stop() {}

  @override
  Stream<O> addTask<O>(
      {Task<O> task, bool isFifo = false, WorkPriority priority = WorkPriority.high}) {
    return Stream.empty();
  }

  @override
  Stream<List<O>> addScopedTask<O>({List<Task> tasks}) {
    // TODO: implement addScopedTask
    return null;
  }
}
