part of '../../worker_manager.dart';

abstract class Executor {
  factory Executor() => _Executor();

  Future<void> warmUp({bool log = false, int isolatesCount});

  Cancelable<O> execute<A, B, C, D, O, T>({
    A arg1,
    B arg2,
    C arg3,
    D arg4,
    Fun1<A, O, T> fun1,
    Fun2<A, B, O, T> fun2,
    Fun3<A, B, C, O, T> fun3,
    Fun4<A, B, C, D, O, T> fun4,
    WorkPriority priority = WorkPriority.high,
    bool fake = false,
    void Function(T value)? notification,
  });

  void pausePool();

  void resumePool();

  Future<void> dispose();
}

class _Executor implements Executor {
  final _queue = PriorityQueue<Task>();
  final _pool = <Worker>[];

  var _taskNumber = pow(-2, 53);
  var _log = false;
  var _warmingUp = false;

  _Executor._internal();

  static final _instance = _Executor._internal();

  factory _Executor() => _instance;

  @override
  Future<void> warmUp({
    bool log = false,
    int? isolatesCount,
  }) {
    _log = log;
    if (_pool.isEmpty) {
      final processors = numberOfProcessors;
      isolatesCount ??= processors;
      var processorsNumber =
          isolatesCount < processors ? isolatesCount : processors;
      if (processorsNumber == 1) processorsNumber = 2;
      for (var i = 0; i < processorsNumber - 1; i++) {
        _pool.add(Worker());
      }
      _logInfo('${_pool.length} has been spawned');
      return Future.wait(_pool.map((iw) => iw.initialize())).then((_) {
        _warmingUp = false;
        _logInfo('initialized');
      });
    } else {
      _logInfo('all workers already initialized');
      throw Error();
    }
  }

  @override
  Cancelable<O> execute<A, B, C, D, O, T>({
    A? arg1,
    B? arg2,
    C? arg3,
    D? arg4,
    Fun1<A, O, T>? fun1,
    Fun2<A, B, O, T>? fun2,
    Fun3<A, B, C, O, T>? fun3,
    Fun4<A, B, C, D, O, T>? fun4,
    WorkPriority priority = WorkPriority.high,
    bool fake = false,
    void Function(T value)? notification,
  }) {
    final task = Task(
      _taskNumber.toInt(),
      runnable: Runnable<A, B, C, D, O, T>(
        arg1: arg1,
        arg2: arg2,
        arg3: arg3,
        arg4: arg4,
        fun1: fun1,
        fun2: fun2,
        fun3: fun3,
        fun4: fun4,
      ),
      workPriority: priority,
      onUpdateProgress: notification,
    );

    Cancelable<O> executing() {
      _logInfo('added task with number $_taskNumber');
      if (fake) {
        try {
          task.runnable.sendPort = TypeSendPort(null);
          final runnable = task.runnable();
          if (runnable is Future<O>) {
            runnable
                .then((data) => task.resultCompleter.complete(data))
                .onError((Object error, stackTrace) =>
                    task.resultCompleter.completeError(error, stackTrace));
          } else {
            task.resultCompleter.complete(runnable);
          }
        } catch (error) {
          task.resultCompleter.completeError(error);
        }
        return Cancelable(task.resultCompleter);
      } else {
        _taskNumber++;
        _queue.add(task);
        final cancelable = Cancelable(
          task.resultCompleter,
          onCancel: () => _cancel(task),
          onPause: () => _pause(task),
          onResume: () => _resume(task),
        );
        _schedule();
        return cancelable;
      }
    }
    if(_pool.isEmpty){
      _logInfo("Executor: cold start");
      _warmingUp = true;
      warmUp(log: _log).then((value) => _schedule());
    }

    if (_warmingUp) {
      _taskNumber++;
      _queue.add(task);
      final cancelable = Cancelable(
        task.resultCompleter,
        onCancel: () => _cancel(task),
        onPause: () => _pause(task),
        onResume: () => _resume(task),
      );
      return cancelable;
    }
    return executing();
  }

  @override
  Future<void> dispose() async {
    _queue.clear();
    await Future.wait(_pool.map((e) => e.kill()));
    _pool.clear();
    _taskNumber = pow(-2, 53);
  }

  void _schedule() {
    if (_queue.isNotEmpty && !_paused) {
      final availableIsolate =
          _pool.firstWhereOrNull((iw) => iw.runnableNumber == null);
      if (availableIsolate != null) {
        final task = _queue.removeFirst();
        _logInfo('isolate with task number ${task.number} begins work');
        availableIsolate.work(task).then((result) {
          task.resultCompleter.complete(result);
        }).catchError((Object error) {
          task.resultCompleter.completeError(error);
        }).whenComplete(() {
          _logInfo('isolate with task number ${task.number} ends work');
          _schedule();
        });
      }
    }
  }

  void _cancel(Task task) {
    _pausedTaskBuffer.remove(task.number);
    if (!task.resultCompleter.isCompleted) {
      task.resultCompleter.completeError(CanceledError());
    }
    if (_queue.contains(task)) {
      _logInfo('task with number ${task.number} removed from queue');
      _queue.remove(task);
    } else {
      final targetWorker =
          _pool.firstWhereOrNull((iw) => iw.runnableNumber == task.number);
      if (targetWorker != null) {
        _logInfo('isolate with number ${targetWorker.runnableNumber} killed');
        targetWorker
            .kill()
            .then((_) => targetWorker.initialize().then((_) => _schedule()));
      }
    }
  }

  final _pausedTaskBuffer = <int, Task>{};

  void _pause(Task task) {
    final targetWorker =
        _pool.firstWhereOrNull((iw) => iw.runnableNumber == task.number);
    if (targetWorker != null) {
      _logInfo("${targetWorker.runnableNumber} paused");
      targetWorker.pause();
    } else {
      _logInfo("${task.number} removed");
      _pausedTaskBuffer[task.number] = task;
      _queue.remove(task);
    }
    _schedule();
  }

  void _resume(Task task) {
    final targetWorker =
        _pool.firstWhereOrNull((iw) => iw.runnableNumber == task.number);
    if (targetWorker != null) {
      targetWorker.resume();
      _logInfo("${targetWorker.runnableNumber} resumed");
    } else {
      final removedTask = _pausedTaskBuffer.remove(task.number);
      if (removedTask != null) {
        _queue.add(removedTask);
        _logInfo("${removedTask.number} returned");
      }
    }
    _schedule();
  }

  var _paused = false;

  @override
  void pausePool() {
    _paused = true;
    for (final worker in _pool) {
      worker.pause();
    }
    _logInfo("pool paused");
  }

  @override
  void resumePool() {
    _paused = false;
    _schedule();
    for (final worker in _pool) {
      worker.resume();
    }
    _logInfo("pool resumed");
  }

  void _logInfo(String info) {
    if (_log) {
      print(info);
    }
  }
}
