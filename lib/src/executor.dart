import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:worker_manager/src/cancelable.dart';
import 'package:worker_manager/src/task.dart';
import 'isolate_wrapper.dart';
import 'runnable.dart';

enum WorkPriority { high, low, regular }

abstract class Executor {
  factory Executor() => _Executor();

  Future<void> warmUp({bool log = false});

  Cancelable<O> fakeExecute<A, B, C, D, O>(
      {A arg1,
      B arg2,
      C arg3,
      D arg4,
      Fun1<A, O> fun1,
      Fun2<A, B, O> fun2,
      Fun3<A, B, C, O> fun3,
      Fun4<A, B, C, D, O> fun4,
      WorkPriority priority = WorkPriority.high});

  Cancelable<O> execute<A, B, C, D, O>(
      {A arg1,
      B arg2,
      C arg3,
      D arg4,
      Fun1<A, O> fun1,
      Fun2<A, B, O> fun2,
      Fun3<A, B, C, O> fun3,
      Fun4<A, B, C, D, O> fun4,
      WorkPriority priority = WorkPriority.high});
}

class _Executor implements Executor {
  final _queue = <Task>[];
  final _pool = <IsolateWrapper>[];
  var _taskNumber = pow(-2, 53);
  var _log = false;

  _Executor._internal();

  static final _instance = _Executor._internal();

  factory _Executor() => _instance;

  @override
  Future<void> warmUp({bool log = false}) async {
    _log = log;
    var processorsNumber = Platform.numberOfProcessors;
    if (processorsNumber == 1) processorsNumber = 2;
    for (int i = 0; i < processorsNumber - 1; i++) {
      _pool.add(IsolateWrapper());
    }
    if (_log) print('${_pool.length} has been spawned');
    await Future.wait(_pool.map((iw) => iw.initialize()));
    if (_log) print('initialized');
  }

  @override
  Cancelable<O> execute<A, B, C, D, O>(
      {A arg1,
      B arg2,
      C arg3,
      D arg4,
      Fun1<A, O> fun1,
      Fun2<A, B, O> fun2,
      Fun3<A, B, C, O> fun3,
      Fun4<A, B, C, D, O> fun4,
      WorkPriority priority = WorkPriority.high}) {
    final task = Task(
      _taskNumber,
      runnable: Runnable(
        arg1: arg1,
        arg2: arg2,
        arg3: arg3,
        arg4: arg4,
        fun1: fun1,
        fun2: fun2,
        fun3: fun3,
        fun4: fun4,
      ),
    );
    if (_log) print('inserted task with number $_taskNumber');
    _taskNumber++;
    switch (priority) {
      case WorkPriority.high:
        _queue.insert(0, task);
        break;
      case WorkPriority.low:
        _queue.insert(_queue.length, task);
        break;
      case WorkPriority.regular:
        _queue.insert(_queue.length.floor(), task);
        break;
    }
    if (_queue.length <= _pool.length) _schedule(_queue.removeAt(0));
    return Cancelable(task.resultCompleter, () => _cancel(task));
  }

  void _schedule<A, B, C, D, O>(Task<A, B, C, D, O> task) {
    final availableIsolateWrapper =
        _pool.firstWhere((iw) => iw.runnableNumber == null, orElse: () => null);
    if (availableIsolateWrapper != null) {
      availableIsolateWrapper.runnableNumber = task.number;
      if (_log)
        print(
            'isolate with task number ${availableIsolateWrapper.runnableNumber} begins work');
      availableIsolateWrapper.work(task).then((result) {
        if (_log) print('isolate with task number ${task.number} ends work');
        task.resultCompleter.complete(result);
        _scheduleNext();
      }).catchError((error) {
        task.resultCompleter.completeError(error);
        _scheduleNext();
      });
    }
  }

  void _scheduleNext<A, B, C, D, O>() {
    if (_queue.isNotEmpty) _schedule<A, B, C, D, O>(_queue.removeAt(0));
  }

  void _cancel<A, B, C, D, O>(Task<A, B, C, D, O> task) {
    if (!task.resultCompleter.isCompleted) {
      task.resultCompleter.completeError(CanceledError());
    }
    if (_queue.contains(task)) {
      if (_log) print('task with number ${task.number} removed from queue');
      _queue.remove(task);
    } else {
      final targetWrapper = _pool.firstWhere(
          (iw) => iw.runnableNumber == task.number,
          orElse: () => null);
      if (targetWrapper != null) {
        if (_log)
          print('isolate with number ${targetWrapper.runnableNumber} killed');
        targetWrapper.kill().then((_) {
          targetWrapper.initialize().then((_) {
            _scheduleNext();
          });
        });
      }
    }
  }

  @override
  Cancelable<O> fakeExecute<A, B, C, D, O>(
      {A arg1,
      B arg2,
      C arg3,
      D arg4,
      fun1,
      fun2,
      fun3,
      fun4,
      WorkPriority priority = WorkPriority.high}) {
    final task = Task(
      _taskNumber,
      runnable: Runnable(
        arg1: arg1,
        arg2: arg2,
        arg3: arg3,
        arg4: arg4,
        fun1: fun1,
        fun2: fun2,
        fun3: fun3,
        fun4: fun4,
      ),
    );
    if (_log) print('inserted task with number $_taskNumber');
    _taskNumber++;
    task.runnable().then((data) {
      task.resultCompleter.complete(data);
    });
    return Cancelable(
        task.resultCompleter, () => print('cant cancel fake task'));
  }
}
