import 'dart:collection';

import 'package:async/async.dart';
import 'package:worker_manager/task.dart';
import 'package:worker_manager/thread.dart';

mixin _SchedulerData {
  final threads = <Thread>[];
  final queue = Queue<Task>();
}

abstract class Scheduler with _SchedulerData {
  void manageQueue<I, O>();

  factory Scheduler() => _SchedulerImpl();
}

class _SchedulerImpl with _SchedulerData implements Scheduler {
  @override
  void manageQueue<I, O>() {
    if (queue.isNotEmpty) {
      final availableWorker = threads.firstWhere((worker) => !worker.isBusy, orElse: () => null);
      if (availableWorker != null) {
        final task = queue.removeFirst() as Task<I, O>;
        availableWorker.isBusy = true;
        availableWorker.taskCode = task.hashCode;
        availableWorker.work<I, O>(task: task).listen((result) {
          if (result is ErrorResult) {
            task.completer.completeError(result.error);
            manageQueue<I, O>();
          } else {
            task.completer.complete(result.asValue.value);
            manageQueue<I, O>();
          }
        });
      }
    }
  }
}
