part of worker_manager;

final workerManager = _Executor();

class _Executor extends Mixinable<_Executor> with _ExecutorLogger {
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

  Cancelable<R> executeWithPort<R, T>(
    ExecuteWithPort<R> execution, {
    WorkPriority priority = WorkPriority.immediately,
    required void Function(T value) onMessage,
  }) {
    if (_pool.isEmpty) {
      init();
    }
    _currentTaskId = Uuid().v4();
    final completer = Completer<R>();
    final task = TaskWithPort(
      id: _currentTaskId,
      workPriority: priority,
      execution: execution,
      completer: completer,
      onMessage: onMessage,
    );
    _queue.add(task);
    _schedule();
    return Cancelable(
      completer: task.completer,
      onCancel: () => _cancel(task),
    );
  }

  @override
  Cancelable<R> execute<R>(
    Execute<R> execution, {
    WorkPriority priority = WorkPriority.immediately,
  }) {
    if (_pool.isEmpty) {
      init();
    }
    _currentTaskId = Uuid().v4();
    final completer = Completer<R>();
    final task = TaskRegular(
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
  }
}
