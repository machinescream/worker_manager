import 'package:worker_manager/src/scheduling/task.dart';
import 'package:worker_manager/src/worker/worker_web.dart'
    if (dart.library.io) 'package:worker_manager/src/worker/worker_io.dart';

abstract class Worker {
  String? get taskId;
  bool get initialized;
  bool get initializing;
  Future<void> initialize();
  void kill();

  Future<R> work<R>(Task<R> task);

  void cancelGentle();

  factory Worker() => WorkerImpl();
}
