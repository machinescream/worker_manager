import 'package:async/async.dart';
import 'package:worker_manager/isolate.dart';
import 'package:worker_manager/task.dart';

abstract class Scheduler {
  Scheduler();

  final isolates = <WorkerIsolate>[];
  final queue = <Task>[];

  void manageQueue<I, O>(Task<I, O> task);

  Future<void> warmUp();

  factory Scheduler.regular() => _RegularScheduler();
}

class _RegularScheduler extends Scheduler {
  @override
  void manageQueue<I, O>(Task<I, O> task) {
    // initialization flow for cold start
    if (isolates.where((isolate) => !isolate.isBusy && !isolate.isInitialized).length ==
        isolates.length) {
      _warmUpFirst().then((_) {
        if (queue.contains(task)) manageQueue<I, O>(task);
      });
    } else {
      final availableWorker = isolates
          .firstWhere((worker) => !worker.isBusy && worker.isInitialized, orElse: () => null);
      if (availableWorker != null) {
        queue.remove(task);
        availableWorker.work<I, O>(task: task).listen((result) {
          result is ErrorResult
              ? task.completer.completeError(result.error)
              : task.completer.complete(result.asValue.value);
          if (queue.isNotEmpty) manageQueue<I, O>(queue.first);
        });
      }
    }
  }

  Future<void> _warmUpFirst() => isolates[0].initializationCompleter.future;

  @override
  Future<void> warmUp() =>
      Future.wait(isolates.map((isolate) => isolate.initializationCompleter.future).toList());
}
//
//class _FifoScheduler extends Scheduler {
//  @override
//  void manageQueue() {
//    st.RateLimit(Stream).buffer(trigger);
//    if (queue.isNotEmpty) {
//      final availableWorker = isolates
//          .firstWhere((worker) => !worker.isBusy && worker.isInitialized, orElse: () => null);
//      if (availableWorker != null) {
//        final task = queue.removeAt(0);
//        availableWorker.work(task: task).listen((result) {
//          result is ErrorResult
//              ? task.completer.completeError(result.error)
//              : task.completer.complete(result.asValue.value);
//          manageQueue();
//        });
//      }
//    }
//  }
//}
