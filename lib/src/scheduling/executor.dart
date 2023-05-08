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
    _createWorkers(isolatesCount ?? numberOfProcessors);
    await _initializeWorkers();
    super.init(isolatesCount: isolatesCount);
    _schedule();
  }

  void _createWorkers(int count) {
    for (var i = 0; i < count; i++) {
      _pool.add(Worker(_schedule));
    }
  }

  Future<void> _initializeWorkers() async {
    await Future.wait(_pool.map((e) => e.initialize()));
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
    _ensureWorkersInitialized();
    _currentTaskId = Uuid().v4();
    final task = _createTaskWithPort<R, T>(execution, priority, onMessage);
    _queue.add(task);
    _schedule();
    return _createCancelable(task);
  }

  @override
  Cancelable<R> execute<R>(
      Execute<R> execution, {
        WorkPriority priority = WorkPriority.immediately,
      }) {
    _ensureWorkersInitialized();
    _currentTaskId = Uuid().v4();
    final task = _createTaskRegular<R>(execution, priority);
    _queue.add(task);
    _schedule();
    super.execute(execution);
    return _createCancelable(task);
  }

  void _ensureWorkersInitialized() {
    if (_pool.isEmpty) {
      init();
    }
  }

  TaskWithPort<R,T> _createTaskWithPort<R, T>(ExecuteWithPort<R> execution, WorkPriority priority, void Function(T value) onMessage) {
    final completer = Completer<R>();
    return TaskWithPort(
      id: _currentTaskId,
      workPriority: priority,
      execution: execution,
      completer: completer,
      onMessage: onMessage,
    );
  }

  TaskRegular<R> _createTaskRegular<R>(Execute<R> execution, WorkPriority priority) {
    final completer = Completer<R>();
    return TaskRegular(
      id: _currentTaskId,
      workPriority: priority,
      execution: execution,
      completer: completer,
    );
  }

  Cancelable<R> _createCancelable<R>(Task<R> task) {
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
