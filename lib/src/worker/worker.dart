import '../scheduling/task.dart';
import 'package:worker_manager/src/worker/worker_web.dart'
    if (dart.library.io) 'package:worker_manager/src/worker/worker_io.dart';

abstract class Worker {
  int? get runnableNumber;

  bool get paused;

  Future<void> initialize();

  Future<void> kill();

  Future<O> work<A, B, C, D, O, T>(Task<A, B, C, D, O, T> task);

  void pause();

  void resume();

  factory Worker() => WorkerImpl();
}
