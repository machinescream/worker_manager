part of '../../worker_manager.dart';

final workerManager = _Executor();

// [-2^54; 2^53] is compatible with dart2js, see core.int doc
const _minId = -9007199254740992;
const _maxId = 9007199254740992;

class _Executor extends Mixinable<_Executor> with _ExecutorLogger {
  final _queue = PriorityQueue<Task>();
  final _pool = <Worker>[];
  var _nextTaskId = _minId;

  @override
  Future<void> init({int? isolatesCount}) async {
    if (_pool.isNotEmpty) {
      print(
        "worker_manager already warmed up, init is ignored. Dispose before init",
      );
      return;
    }
    _createWorkers(isolatesCount ?? numberOfProcessors);
    await _initializeWorkers();
    super.init(isolatesCount: isolatesCount);
    _schedule();
  }

  @override
  Future<void> dispose() async {
    _queue.clear();
    for (final worker in _pool) {
      worker.kill();
    }
    _pool.clear();
    super.dispose();
  }

  Cancelable<R> execute<R>(
    Execute<R> execution, {
    WorkPriority priority = WorkPriority.immediately,
  }) {
    return _createCancelable<R>(execution: execution, priority: priority);
  }

  Cancelable<R> executeWithPort<R, T>(
    ExecuteWithPort<R> execution, {
    WorkPriority priority = WorkPriority.immediately,
    required void Function(T value) onMessage,
  }) {
    return _createCancelable<R>(
      execution: execution,
      priority: priority,
      onMessage: (message) => onMessage(message as T),
    );
  }

  Cancelable<R> executeGentle<R>(
    ExecuteGentle<R> execution, {
    WorkPriority priority = WorkPriority.immediately,
  }) {
    return _createCancelable<R>(execution: execution, priority: priority);
  }

  Cancelable<R> executeGentleWithPort<R, T>(
    ExecuteGentleWithPort<R> execution, {
    WorkPriority priority = WorkPriority.immediately,
    required void Function(T value) onMessage,
  }) {
    return _createCancelable<R>(
      execution: execution,
      priority: priority,
      onMessage: (message) => onMessage(message as T),
    );
  }

  void _createWorkers(int count) {
    for (var i = 0; i < count; i++) {
      _pool.add(Worker(_schedule));
    }
  }

  Future<void> _initializeWorkers() async {
    await Future.wait(_pool.map((e) => e.initialize()));
  }

  Cancelable<R> _createCancelable<R>({
    required Function execution,
    WorkPriority priority = WorkPriority.immediately,
    void Function(Object value)? onMessage,
  }) {
    if (_nextTaskId + 1 == _maxId) {
      _nextTaskId = _minId;
    }
    final id = _nextTaskId.toString();
    _nextTaskId++;
    late final Task<R> task;
    if (execution is Execute<R>) {
      task = TaskRegular<R>(
        id: id,
        workPriority: priority,
        execution: execution,
        completer: Completer<R>(),
      );
    } else if (execution is ExecuteWithPort<R>) {
      task = TaskWithPort<R>(
        id: id,
        workPriority: priority,
        execution: execution,
        completer: Completer<R>(),
        onMessage: onMessage!,
      );
    } else if (execution is ExecuteGentle<R>) {
      task = TaskGentle<R>(
        id: id,
        workPriority: priority,
        execution: execution,
        completer: Completer<R>(),
      );
    } else if (execution is ExecuteGentleWithPort<R>) {
      task = TaskGentleWithPort<R>(
        id: id,
        workPriority: priority,
        execution: execution,
        completer: Completer<R>(),
        onMessage: onMessage!,
      );
    }
    _queue.add(task);
    _schedule();
    logTaskAdded(task.id);
    return Cancelable(
      completer: task.completer,
      onCancel: () => _cancel(task),
    );
  }

  void _ensureWorkersInitialized() {
    if (_pool.isEmpty) {
      init();
    }
  }

  void _schedule() {
    _ensureWorkersInitialized();
    final availableWorker = _pool.firstWhereOrNull(
      (worker) => worker.taskId == null && worker.initialized,
    );
    if (_queue.isEmpty || availableWorker == null) return;
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

  void _tryRemoveFromQueue(Task task) {
    if (_queue.remove(task)) {
      task.completer.completeError(CanceledError());
      return;
    }
  }

  Worker? _targetWorker(String taskId) {
    return _pool.firstWhereOrNull((worker) => worker.taskId == taskId);
  }

  @override
  void _cancel(Task task) {
    _tryRemoveFromQueue(task);
    if (task is Gentle) {
      _targetWorker(task.id)?.cancelGentle();
    } else {
      _targetWorker(task.id)?.restart();
    }
    super._cancel(task);
  }
}
