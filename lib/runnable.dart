import 'dart:async';

typedef FutureOr<O> Fun1<A, O>(A arg1);
typedef FutureOr<O> Fun2<A, B, O>(A arg1, B arg2);
typedef FutureOr<O> Fun3<A, B, C, O>(A arg1, B arg2, C arg3);
typedef FutureOr<O> Fun4<A, B, C, D, O>(A arg1, B arg2, C arg3, D arg4);

class Runnable<A, B, C, D, O> {
  final A arg1;
  final B arg2;
  final C arg3;
  final D arg4;

  final Fun1<A, O> fun1;
  final Fun2<A, B, O> fun2;
  final Fun3<A, B, C, O> fun3;
  final Fun4<A, B, C, D, O> fun4;

  const Runnable({
    this.arg1,
    this.arg2,
    this.arg3,
    this.arg4,
    this.fun1,
    this.fun2,
    this.fun3,
    this.fun4,
  });

  call() {
    if (arg1 != null && fun1 != null) return fun1(arg1);
    if (arg1 != null && arg2 != null && fun2 != null) return fun2(arg1, arg2);
    if (arg1 != null && arg2 != null && arg3 != null && fun3 != null) return fun3(arg1, arg2, arg3);
    if (arg1 != null && arg2 != null && arg3 != null && arg4 != null && fun4 != null)
      return fun4(arg1, arg2, arg3, arg4);
  }
}
