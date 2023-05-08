import 'package:worker_manager/src/scheduling/task.dart';
import 'package:worker_manager/src/worker/worker_web.dart'
    if (dart.library.io) 'package:worker_manager/src/worker/worker_io.dart';

abstract class Worker {
  String? get taskId;
  bool get initialized;
  Future<void> initialize();
  void kill();

  Future<R> work<R>(Task<R> task);

  Future<void> restart();

  factory Worker(void Function() onReviseAfterTimeout) =>
      WorkerImpl(onReviseAfterTimeout);
}
