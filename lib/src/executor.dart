import 'dart:io';

import 'package:async/async.dart';
import 'package:worker_manager/src/task.dart';

import 'isolate_wrapper.dart';
import 'runnable.dart';

enum WorkPriority { high, low, regular }

abstract class Executor {
  factory Executor() => _Executor();

  Future<void> warmUp();

  CancelableOperation<O> execute<A, B, C, D, O>({
    A arg1,
    B arg2,
    C arg3,
    D arg4,
    Fun1<A, O> fun1,
    Fun2<A, B, O> fun2,
    Fun3<A, B, C, O> fun3,
    Fun4<A, B, C, D, O> fun4,
    WorkPriority priority = WorkPriority.high,
  });
}

class _Executor implements Executor {
  final _queue = <Task>[];
  final _pool = <IsolateWrapper>[];
  var _taskNumber = 0;

  _Executor._internal();

  static final _instance = _Executor._internal();

  factory _Executor() => _instance;

  @override
  Future<void> warmUp() async {
    var processorsNumber = Platform.numberOfProcessors;
    if (processorsNumber == 1) processorsNumber = 2;
    for (int i = 0; i < processorsNumber - 1; i++) {
      _pool.add(IsolateWrapper());
    }
    await Future.wait(_pool.map((iw) => iw.initialize()));
  }

  @override
  CancelableOperation<O> execute<A, B, C, D, O>({
    A arg1,
    B arg2,
    C arg3,
    D arg4,
    Fun1<A, O> fun1,
    Fun2<A, B, O> fun2,
    Fun3<A, B, C, O> fun3,
    Fun4<A, B, C, D, O> fun4,
    WorkPriority priority = WorkPriority.high,
  }) {
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
    if (_queue.length <= _pool.length) _schedule(_queue.first);
    return CancelableOperation<O>.fromFuture(task.resultCompleter.future, onCancel: () => _cancel(task));
  }

  void _schedule<A, B, C, D, O>(Task<A, B, C, D, O> task) {
    final availableIsolateWrapper = _pool.firstWhere((iw) => iw.runnableNumber == -1, orElse: () => null);
    if (availableIsolateWrapper != null) {
      _queue.remove(task);
      availableIsolateWrapper.runnableNumber = task.number;
      availableIsolateWrapper.work(task).then((result) {
        task.resultCompleter.complete(result);
        _scheduleNext();
      }).catchError((error) {
        task.resultCompleter.completeError(error);
        _scheduleNext();
      });
    }
  }

  void _scheduleNext<A, B, C, D, O>() {
    if (_queue.isNotEmpty) _schedule<A, B, C, D, O>(_queue.first);
  }

  void _cancel<A, B, C, D, O>(Task<A, B, C, D, O> task) {
    if (_queue.contains(task)) {
      _queue.remove(task);
    } else {
      final targetWrapper = _pool.firstWhere((iw) => iw.runnableNumber == task.number, orElse: () => null);
      if (targetWrapper != null) {
        targetWrapper.kill();
        targetWrapper.initialize().then((_) {
          _scheduleNext();
        });
      }
    }
  }
}
