import 'dart:async';
import 'package:worker_manager/src/scheduling/task.dart';
import 'worker_web.dart'
    if (dart.library.io) 'worker_io.dart';

abstract class Worker {
  int? get runnableNumber;

  Future<void> initialize();

  Future<void> kill();

  Future<O> work<A, B, C, D, O>(Task<A, B, C, D, O> task);

  factory Worker() => WorkerImpl();
}
