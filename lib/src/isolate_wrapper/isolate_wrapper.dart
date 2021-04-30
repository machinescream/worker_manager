import 'dart:async';
import 'package:worker_manager/src/task.dart';
import 'isolate_wrapper_web.dart'
    if (dart.library.io) 'isolate_wrapper_io.dart';

abstract class IsolateWrapper {
  int? runnableNumber;

  Future<void> initialize();

  Future<void> kill();

  Future<O> work<A, B, C, D, O>(Task<A, B, C, D, O> task);

  factory IsolateWrapper() => IsolateWrapperImpl();
}

class Message {
  final Function function;
  final Object argument;

  Message(this.function, this.argument);

  FutureOr call() async => await function(argument);
}
