import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';

void main() async {
  test('adding stress test', () async {
    await Executor().warmUp();
    final list = [];
    final v1 = await Executor().execute(arg1: Counter(), arg2: 10, fun2: Counter.fun21).value;
    final v2 =
        await Executor().execute(arg1: Counter(), arg2: 10, arg3: 3, fun3: Counter.fun12).value;
    list.add(v1);
    list.add(v2);
    print(list);
    await Future.delayed(Duration(seconds: 5), () {
      print(list.length);
      expect(list.length, 2);
    });
  });

//  test('scoped test', () async {
//    final list = [];
//    final tasks = List.generate(10, (i) {
//      return Task<int>(function: fib, bundle: 30, timeout: Duration(seconds: 1));
//    });
//    Executor().addScopedTask<int>(tasks: tasks).listen((data) {
//      list.addAll(data);
//    });
//    await Future.delayed(Duration(seconds: 10), () {
//      expect(list.length, 10);
//    });
//  });
}

class Counter {
  int fib(int n) {
    if (n < 2) {
      return n;
    }
    return fib(n - 2) + fib(n - 1);
  }

  int incr(int arg, int arg2) => arg + arg2;

  static int fun21(Counter counter, int arg) => counter.fib(arg);

  static String fun12(Counter counter, int arg, int arg2) => counter.incr(arg, arg2).toString();
}
