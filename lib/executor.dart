import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:worker_manager/scheduler.dart';
import 'package:worker_manager/task.dart';
import 'package:worker_manager/thread.dart';

enum WorkPriority { high, low }
enum Policy { fifo } //todo: add _scheduler

abstract class Executor {
  Future<void> initExecutor();

  void addTask<I, O>({@required Task<I, O> task, WorkPriority priority = WorkPriority.high});

  void addTasks<I, O>({
    @required List<Task<I, O>> tasks,
  });

  void removeTask<I, O>({@required Task<I, O> task});

  Stream<O> resultOf<I, O>({@required Task<I, O> task});

  void stop();

  factory Executor({int threadPoolSize}) => _WorkerManager(threadPoolSize: threadPoolSize);

  factory Executor.fake() => _FakeWorker();

  factory Executor.fifo() => _WorkerManager(threadPoolSize: 1)..threadPoolSize = 1;
}

class _WorkerManager implements Executor {
  int threadPoolSize;
  final _scheduler = Scheduler();
  final cash = <int, Object>{};

  static final _WorkerManager _manager = _WorkerManager._internal();

  factory _WorkerManager({threadPoolSize = 1}) {
    if (_manager.threadPoolSize == null) {
      _manager.threadPoolSize = threadPoolSize;
    }
    return _manager;
  }

  _WorkerManager._internal({this.threadPoolSize = 1}) {
    for (int i = 0; i < threadPoolSize; i++) {
      _scheduler.threads.add(Thread());
    }
  }

  @override
  Future<void> initExecutor() async =>
      await Future.wait(_scheduler.threads.map((thread) => thread.initPortConnection()));

  @override
  void addTask<I, O>({Task<I, O> task, WorkPriority priority = WorkPriority.high}) {
    priority == WorkPriority.high
        ? _scheduler.queue.addFirst(task)
        : _scheduler.queue.addLast(task);
  }

  @override
  void addTasks<I, O>({List<Task<I, O>> tasks}) {
    _scheduler.queue.addAll(tasks);
  }

  @override
  void removeTask<I, O>({Task<I, O> task}) {
    if (_scheduler.queue.contains(task)) _scheduler.queue.remove(task);
    _scheduler.threads.forEach((thread) {
      if (thread.taskCode == task.hashCode) {
        thread.cancel();
      }
    });
    while (_scheduler.threads.length < threadPoolSize) {
      _scheduler.threads.add(Thread());
    }
  }

  @override
  Stream<O> resultOf<I, O>({Task<I, O> task}) async* {
    if (cash.containsKey(
        task.hashCode
        )) {
      yield cash[task.hashCode];
    } else {
      _scheduler.manageQueue(
      );
      final O result = await task.completer.future;
      yield result;
      if (task.cash) cash.putIfAbsent(
          task.hashCode, (
          ) => result
          );
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
  void addTask<I, O>(
      {Task<I, O> task, WorkPriority priority = WorkPriority.high, bool cashResult}
      ) {
    priority == WorkPriority.high
        ? _scheduler.queue.addFirst(task)
        : _scheduler.queue.addLast(task);
  }

  @override
  void addTasks<I, O>({List<Task<I, O>> tasks}) {}

  @override
  Future<void> initExecutor() {
    return null;
  }

  @override
  void removeTask<I, O>({Task<I, O> task}) {
    if (_scheduler.queue.contains(task)) _scheduler.queue.remove(task);
  }

  @override
  Stream<O> resultOf<I, O>({Task<I, O> task}) async* {
    yield await task.function(task.bundle);
  }

  @override
  void stop() {}
}
