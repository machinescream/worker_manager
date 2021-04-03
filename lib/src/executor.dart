import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:worker_manager/src/cancelable.dart';
import 'package:worker_manager/src/task.dart';
import 'package:worker_manager/src/work_priority.dart';

import 'isolate_wrapper/isolate_wrapper.dart';
import 'number_of_processors/processors_web.dart'
    if (dart.library.io) 'number_of_processors/processors_io.dart';
import 'runnable.dart';

abstract class Executor {
  factory Executor() => _Executor();

  Future<void> warmUp({bool log = false, int? isolatesCount});

  Cancelable<O> fakeExecute<A, B, C, D, O>(
      {A? arg1,
      B? arg2,
      C? arg3,
      D? arg4,
      Fun1<A, O>? fun1,
      Fun2<A, B, O>? fun2,
      Fun3<A, B, C, O>? fun3,
      Fun4<A, B, C, D, O>? fun4,
      WorkPriority priority = WorkPriority.high});

  Cancelable<O> execute<A, B, C, D, O>(
      {A? arg1,
      B? arg2,
      C? arg3,
      D? arg4,
      Fun1<A, O>? fun1,
      Fun2<A, B, O>? fun2,
      Fun3<A, B, C, O>? fun3,
      Fun4<A, B, C, D, O>? fun4,
      WorkPriority priority = WorkPriority.high});
}

class _Executor implements Executor {
  final _queue = PriorityQueue<Task>();
  final _pool = <IsolateWrapper>[];
  var _taskNumber = pow(-2, 53);
  var _log = false;

  _Executor._internal();

  static final _instance = _Executor._internal();

  factory _Executor() => _instance;

  @override
  Future<void> warmUp({bool log = false, int? isolatesCount}) async {
    _log = log;
    final processors = numberOfProcessors;
    isolatesCount ??= processors;
    var processorsNumber =
        isolatesCount < processors ? isolatesCount : processors;
    if (processorsNumber == 1) processorsNumber = 2;
    for (var i = 0; i < processorsNumber - 1; i++) {
      _pool.add(IsolateWrapper());
    }
    logInfo('${_pool.length} has been spawned');
    await Future.wait(_pool.map((iw) => iw.initialize()));
    logInfo('initialized');
  }

  @override
  Cancelable<O> execute<A, B, C, D, O>(
      {A? arg1,
      B? arg2,
      C? arg3,
      D? arg4,
      Fun1<A, O>? fun1,
      Fun2<A, B, O>? fun2,
      Fun3<A, B, C, O>? fun3,
      Fun4<A, B, C, D, O>? fun4,
      WorkPriority priority = WorkPriority.high}) {
    final task = Task(_taskNumber as int,
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
        workPriority: priority);
    logInfo('inserted task with number $_taskNumber');
    _taskNumber++;
    _queue.add(task);
    _schedule();
    return Cancelable(task.resultCompleter, () => _cancel(task));
  }

  void _schedule() {
    final availableIsolate =
        _pool.firstWhereOrNull((iw) => iw.runnableNumber == null);
    if (availableIsolate != null) {
      final task = _queue.removeFirst();
      availableIsolate.runnableNumber = task.number;
      logInfo(
          'isolate with task number ${availableIsolate.runnableNumber} begins work');
      availableIsolate.work(task).then((result) {
        if (_log) {
          print('isolate with task number ${task.number} ends work');
        }
        task.resultCompleter.complete(result);
        _scheduleNext();
      }).catchError((error) {
        task.resultCompleter.completeError(error);
        _scheduleNext();
      });
    }
  }

  void _scheduleNext<A, B, C, D, O>() {
    if (_queue.isNotEmpty) _schedule();
  }

  void _cancel<A, B, C, D, O>(Task<A, B, C, D, O> task) {
    if (!task.resultCompleter.isCompleted) {
      task.resultCompleter.completeError(CanceledError());
    }
    if (_queue.contains(task)) {
      logInfo('task with number ${task.number} removed from queue');
      _queue.remove(task);
    } else {
      final targetWrapper = _pool.firstWhereOrNull(
          (iw) => iw.runnableNumber == task.number);
      if (targetWrapper != null) {
        logInfo('isolate with number ${targetWrapper.runnableNumber} killed');
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
      {A? arg1,
      B? arg2,
      C? arg3,
      D? arg4,
      Fun1<A, O>? fun1,
      Fun2<A, B, O>? fun2,
      Fun3<A, B, C, O>? fun3,
      Fun4<A, B, C, D, O>? fun4,
      WorkPriority priority = WorkPriority.high}) {
    final task = Task(
      _taskNumber as int,
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
    logInfo('inserted task with number $_taskNumber');
    _taskNumber++;

    if (task.runnable!() is Future<O>) {
      (task.runnable!() as Future<O>).then((data) {
        task.resultCompleter.complete(data);
      });
    } else {
      task.resultCompleter.complete(task.runnable!());
    }

    return Cancelable(
        task.resultCompleter, () => print('cant cancel fake task'));
  }

  void logInfo(String info) {
    if (_log) {
      print(info);
    }
  }
}
