import 'dart:async';
import 'package:worker_manager/worker_manager.dart';

typedef Fun1<A, O, T> = FutureOr<O> Function(
  A arg1,
  TypeSendPort<T> sendPort,
);
typedef Fun2<A, B, O, T> = FutureOr<O> Function(
  A arg1,
  B arg2,
  TypeSendPort<T> sendPort,
);
typedef Fun3<A, B, C, O, T> = FutureOr<O> Function(
  A arg1,
  B arg2,
  C arg3,
  TypeSendPort<T> sendPort,
);
typedef Fun4<A, B, C, D, O, T> = FutureOr<O> Function(
  A arg1,
  B arg2,
  C arg3,
  D arg4,
  TypeSendPort<T> sendPort,
);

class Runnable<A, B, C, D, O, T> {
  final A? arg1;
  final B? arg2;
  final C? arg3;
  final D? arg4;

  final Fun1<A, O, T>? fun1;
  final Fun2<A, B, O, T>? fun2;
  final Fun3<A, B, C, O, T>? fun3;
  final Fun4<A, B, C, D, O, T>? fun4;

  late final TypeSendPort<T> sendPort;

  Runnable({
    this.arg1,
    this.arg2,
    this.arg3,
    this.arg4,
    this.fun1,
    this.fun2,
    this.fun3,
    this.fun4,
  });

  FutureOr<O> call() {
    final arg1 = this.arg1;
    final arg2 = this.arg2;
    final arg3 = this.arg3;
    final arg4 = this.arg4;
    final fun1 = this.fun1;
    final fun2 = this.fun2;
    final fun3 = this.fun3;
    final fun4 = this.fun4;

    if (arg1 != null && fun1 != null) {
      return fun1(arg1, sendPort);
    }
    if (arg1 != null && arg2 != null && fun2 != null) {
      return fun2(arg1, arg2, sendPort);
    }
    if (arg1 != null && arg2 != null && arg3 != null && fun3 != null) {
      return fun3(arg1, arg2, arg3, sendPort);
    }
    if (arg1 != null &&
        arg2 != null &&
        arg3 != null &&
        arg4 != null &&
        fun4 != null) {
      return fun4(arg1, arg2, arg3, arg4, sendPort);
    }
    throw ArgumentError("execute method arguments of function miss match");
  }
}
