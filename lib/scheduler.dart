import 'dart:collection';

import 'package:async/async.dart';
import 'package:worker_manager/task.dart';
import 'package:worker_manager/thread.dart';

mixin _SchedulerData {
  final threads = <Thread>[];
  final queue = Queue<Task>();
  final fifoQueue = Queue<Task>();
  final fifoResults = <Task, Result>{};
}

abstract class Scheduler with _SchedulerData {
  void manageQueue();

  void manageFifoQueue();

  factory Scheduler() => _SchedulerImpl();
}

class _SchedulerImpl with _SchedulerData implements Scheduler {
  @override
  void manageQueue() {
    if (queue.isNotEmpty) {
      final availableWorker = threads.firstWhere((worker) => !worker.isBusy, orElse: () => null);
      if (availableWorker != null) {
        final task = queue.removeFirst();
        availableWorker.isBusy = true;
        availableWorker.taskId = task.id;
        availableWorker.work(task: task).listen((result) {
          result is ErrorResult
              ? task.completer.completeError(result.error)
              : task.completer.complete(result.asValue.value);
          manageQueue();
        });
      }
    }
  }

  @override
  void manageFifoQueue() {
    if (fifoQueue.isNotEmpty) {
      final availableWorker = threads.firstWhere((worker) => !worker.isBusy, orElse: () => null);
      if (availableWorker != null) {
        final task = fifoQueue.removeFirst();
        fifoResults.addEntries([MapEntry(task, null)]);
        availableWorker.work(task: task).listen((result) {
          print(result);
//          fifoResults[task] = result;
//          if (fifoResults.values.isNotEmpty) {
//            final targetTask = fifoResults.keys.first;
//            fifoResults.removeWhere((k, v) => k == targetTask);
//            final result = fifoResults[targetTask];
//            result is ErrorResult
//                ? targetTask.completer.completeError(result.error)
//                : targetTask.completer.complete(result.asValue.value);
//            manageFifoQueue();
//          }
        });
      }
    }
  }
}
