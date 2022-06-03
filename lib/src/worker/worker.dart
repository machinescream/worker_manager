import '../scheduling/task.dart';
import 'package:worker_manager/src/worker/worker_web.dart'
    if (dart.library.io) 'package:worker_manager/src/worker/worker_io.dart';

abstract class Worker {
  int? get runnableNumber;

  Future<void> initialize();

  Future<void> kill();

  Future<O> work<A, B, C, D, O>(Task<A, B, C, D, O> task);

  void pause();

  void resume();

  factory Worker() => WorkerImpl();
}
