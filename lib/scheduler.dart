import 'dart:async';
import 'dart:collection';

import 'package:worker_manager/result.dart';
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
  void manageQueue<I, O>() async {
    if (queue.isNotEmpty) {
      final availableWorker = threads.firstWhere((worker) => !worker.isBusy, orElse: () => null);
      if (availableWorker != null) {
        availableWorker.isBusy = true;
        final task = queue.removeFirst();
        availableWorker.taskCode = task.hashCode;
        Result result;
        try {
          Future<Result> execute() async => await availableWorker.work<I, O>(
                function: task.function,
                bundle: task.bundle,
              );
          result = (task.timeout != null)
              ? await Future.microtask(() async {
                  return await execute();
                }).timeout(task.timeout, onTimeout: () {
                  throw TimeoutException;
                })
              : await execute();
        } catch (error) {
          result = Result(error: error);
        }
        if (result.error != null) {
          task.completer.completeError(result.error);
        } else {
          task.completer.complete(result.data);
        }
        manageQueue();
      }
    }
  }
}
