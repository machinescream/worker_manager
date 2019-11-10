import 'package:async/async.dart';
import 'package:worker_manager/isolate.dart';
import 'package:worker_manager/task.dart';

abstract class Scheduler {
  Scheduler();

  final isolates = <WorkerIsolate>[];
  final queue = <Task>[];

  void manageQueue();
  factory Scheduler.regular() => _RegularScheduler();
}

class _RegularScheduler extends Scheduler {
  @override
  void manageQueue() {
    if (queue.isNotEmpty) {
      final availableWorker = isolates
          .firstWhere((worker) => !worker.isBusy && worker.isInitialized, orElse: () => null);
      if (availableWorker != null) {
        final task = queue.removeAt(0);
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
