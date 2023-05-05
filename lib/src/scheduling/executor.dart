part of worker_manager;

final workerManager = _Executor();

final class _Executor extends Mixinable<_Executor> with _ExecutorLogger {
  final _queue = PriorityQueue<Task>();
  final _pool = <Worker>[];
  final _pausedTaskBuffer = <int, Task>{};

  @override
  late String _currentTaskId;

  @override
  Future<void> init({int? isolatesCount}) async {
    if (_pool.isNotEmpty) throw Exception("worker_manager already warmed up");
    final workers = <Worker>[];
    for (var i = 0; i < (isolatesCount ?? numberOfProcessors); i++) {
      workers.add(Worker(_schedule));
    }
    await Future.wait(workers.map((e) => e.initialize()));
    _pool.addAll(workers);
    super.init(isolatesCount: isolatesCount);
    _schedule();
  }

  @override
  Future<void> dispose() async {
    _pausedTaskBuffer.clear();
    _queue.clear();
    for (final worker in _pool) {
      worker.kill();
    }
    _pool.clear();
    super.dispose();
  }

  @override
  Cancelable<R> execute<R>(
    FutureOr<R> Function() execution, {
    WorkPriority priority = WorkPriority.immediately,
    // void Function(T value)? notification,
  }) {
    if (_pool.isEmpty) {
      init();
    }
    _currentTaskId = Uuid().v4();
    final completer = Completer<R>();
    final task = Task(
      id: _currentTaskId,
      workPriority: priority,
      execution: execution,
      completer: completer,
    );
    _queue.add(task);
    _schedule();
    super.execute(execution);
    return Cancelable(
      completer: task.completer,
      onCancel: () => _cancel(task),
      // onPause: () => _pause(task),
      // onResume: () => _resume(task),
    );
  }

  void _schedule() {
    final availableWorker = _pool.firstWhereOrNull(
      (iw) => iw.taskId == null && iw.initialized,
    );
    if (_pool.isEmpty || _queue.isEmpty || availableWorker == null) return;

    final task = _queue.removeFirst();
    final completer = task.completer;
    availableWorker.work(task).then((value) {
      completer.complete(value);
    }, onError: (error, st) {
      completer.completeError(error, st);
    }).whenComplete(() {
      _schedule();
    });
  }

  @override
  void _cancel(Task task) {
    if (_queue.remove(task)) {
      task.completer.completeError(CanceledError());
      return;
    }
    _pool.firstWhereOrNull((worker) => worker.taskId == task.id)?.restart();
    super._cancel(task);
    // _pausedTaskBuffer.remove(task.number);
  }
}

// void _pause(Task task) {
//   final targetWorker =
//       _pool.firstWhereOrNull((iw) => iw.runnableNumber == task.number);
//   if (targetWorker != null) {
//     _logInfo("${targetWorker.runnableNumber} paused");
//     targetWorker.pause();
//   } else {
//     _logInfo("${task.number} removed");
//     _pausedTaskBuffer[task.number] = task;
//     _queue.remove(task);
//   }
//   _schedule();
// }
//
// void _resume(Task task) {
//   final targetWorker =
//       _pool.firstWhereOrNull((iw) => iw.runnableNumber == task.number);
//   if (targetWorker != null) {
//     targetWorker.resume();
//     _logInfo("${targetWorker.runnableNumber} resumed");
//   } else {
//     final removedTask = _pausedTaskBuffer.remove(task.number);
//     if (removedTask != null) {
//       _queue.add(removedTask);
//       _logInfo("${removedTask.number} returned");
//     }
//   }
//   _schedule();
// }
//
// var _paused = false;
//
// @override
// void pausePool() {
//   _paused = true;
//   for (final worker in _pool) {
//     worker.pause();
//   }
//   _logInfo("pool paused");
// }
//
// @override
// void resumePool() {
//   _paused = false;
//   _schedule();
//   for (final worker in _pool) {
//     worker.resume();
//   }
//   _logInfo("pool resumed");
// }
