import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:worker_manager/scheduler.dart';
import 'package:worker_manager/task.dart';
import 'package:worker_manager/thread.dart';

enum WorkPriority { high, low }
enum Policy { fifo }

abstract class Executor {
  Future<void> initExecutor();

  void addTask<I, O>({@required Task<I, O> task, WorkPriority priority = WorkPriority.high});

  void addTasks<I, O>({
    @required List<Task<I, O>> tasks,
  });

  void removeTask<I, O>({@required Task<I, O> task});

  Stream<O> resultOf<I, O>({@required Task<I, O> task});

  void stop();

  factory Executor() => _WorkerManager();
}

class _WorkerManager implements Executor {
  final int threadPoolSize;
  final _scheduler = Scheduler();
  static final _WorkerManager _manager = _WorkerManager._internal();

  factory _WorkerManager() => _manager;

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
    _scheduler.manageQueue();
    yield await task.completer.future;
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
