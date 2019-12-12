import 'package:async/async.dart';
import 'package:worker_manager/isolate.dart';
import 'package:worker_manager/task.dart';

abstract class Scheduler {
  Scheduler();

  final isolates = <WorkerIsolate>[];
  final queue = <Task>[];

  void manageQueue<I, O>(Task<I, O> task);

  Future<void> warmUp();

  bool get isAbleToWork;

  factory Scheduler.regular() => _RegularScheduler();
}

class _RegularScheduler extends Scheduler {
  @override
  void manageQueue<I, O>(Task<I, O> task) {
    // initialization flow for cold start
    if (isolates.where((isolate) => !isolate.isBusy && !isolate.isInitialized).length == isolates.length) {
      _warmUpFirst().then((_) => manageQueue<I, O>(task));
    } else {
      final availableWorker =
          isolates.firstWhere((worker) => !worker.isBusy && worker.isInitialized, orElse: () => null);
      if (availableWorker != null) {
        availableWorker.work<I, O>(task: task).listen((result) {
          result is ErrorResult
              ? task.completer.completeError(result.error)
              : task.completer.complete(result.asValue.value);
          if (queue.isNotEmpty) manageQueue<I, O>(queue.removeAt(0));
        });
      }else{
        queue.insert(0, task);
      }
    }
  }

  bool get isAbleToWork =>
      isolates.firstWhere((worker) => !worker.isBusy && worker.isInitialized, orElse: () => null) != null;

  Future<void> _warmUpFirst() => isolates[0].initializationCompleter.future;

  @override
  Future<void> warmUp() => Future.wait(isolates.map((isolate) => isolate.initializationCompleter.future).toList());
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
