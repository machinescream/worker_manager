import 'package:async/async.dart';

import 'isolate.dart';
import 'task.dart';

abstract class Scheduler {
  void manageQueue<A, B, C, D, O>(Task<A, B, C, D, O> task);

  Future<void> warmUp();

  factory Scheduler.regular() => RegularScheduler();
}

class RegularScheduler implements Scheduler {
  final isolates = <WorkerIsolate>[];
  final queue = <Task>[];

  @override
  void manageQueue<A, B, C, D, O>(Task<A, B, C, D, O> task) {
    if (isolates.where((isolate) => !isolate.isBusy && !isolate.isInitialized).length ==
        isolates.length) {
      _warmUpFirst().then((_) {
        if (queue.contains(task)) manageQueue<A, B, C, D, O>(task);
      });
    } else {
      final availableWorker = isolates
          .firstWhere((worker) => !worker.isBusy && worker.isInitialized, orElse: () => null);
      if (availableWorker != null) {
        queue.remove(task);
        availableWorker.work<A, B, C, D, O>(task: task).listen((result) {
          result is ErrorResult
              ? task.completer.completeError(result.error)
              : task.completer.complete(result.asValue.value);
          if (queue.isNotEmpty) manageQueue<A, B, C, D, O>(queue.first);
        });
      }
    }
  }

  Future<void> _warmUpFirst() => isolates[0].initializationCompleter.future;

  @override
  Future<void> warmUp() =>
      Future.wait(isolates.map((isolate) => isolate.initializationCompleter.future).toList());
}
