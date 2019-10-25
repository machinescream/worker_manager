import 'dart:collection';

import 'package:async/async.dart';
import 'package:worker_manager/isolate.dart';
import 'package:worker_manager/task.dart';

mixin _SchedulerData {
  final isolates = <WorkerIsolate>[];
  final queue = Queue<Task>();
}

abstract class Scheduler with _SchedulerData {
  void manageQueue();
  factory Scheduler() => _SchedulerImpl();
}

class _SchedulerImpl with _SchedulerData implements Scheduler {
  @override
  void manageQueue() {
    if (queue.isNotEmpty) {
      final availableWorker = isolates.firstWhere((worker) =>
      !worker.isBusy && worker.isInitialized, orElse: () => null);
      if (availableWorker != null) {
        availableWorker.isBusy = true;
        final task = queue.removeFirst();
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
}
