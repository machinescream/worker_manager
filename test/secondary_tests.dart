import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:worker_manager/src/executor.dart';

void main() async {
  test('adding stress test', () async {
    await Executor().warmUp();
    final list = [];
    final v1 = await Executor().execute(arg1: Counter(), arg2: 10, fun2: Counter.fun21).value;
    final v2 = await Executor().execute(arg1: Counter(), arg2: 10, arg3: 3, fun3: Counter.fun12).value;
    list.add(v1);
    list.add(v2);
    await Future.delayed(Duration(seconds: 5), () {
      expect(list.length, 2);
    });
  });

  test('adding stress test 2', () async {
    await Executor().warmUp();
    final list = [];
    for (int i = 0; i < 100; i++) {
      Executor().execute(arg1: Counter(), arg2: 10, fun2: Counter.fun21).value.then((value) {
        list.add(value);
      });
    }
    await Future.delayed(Duration(seconds: 5), () {
      expect(list.length, 100);
    });
  });

  test('removing', () async {
    await Executor().warmUp();
    final list = [];
    Executor().execute(arg1: Counter(), arg2: 30, fun2: Counter.fun21).value.then((_) {
      list.add(_);
    });
    final v2 = Executor().execute(arg1: Counter(), arg2: 50, fun2: Counter.fun21)
      ..value.then((_) {
        list.add(_);
      });
    Executor().execute(arg1: Counter(), arg2: 40, fun2: Counter.fun21).value.then((_) {
      list.add(_);
    });
    v2.cancel();
    await Future.delayed(Duration(seconds: 10), () {
      expect(list.length, 2);
    });
  });

  test('removing all and continue', () async {
    await Executor().warmUp();
    final list = [];
    final tasks = <CancelableOperation>[];

    for (int i = 0; i < 8; i++) {
      tasks.add(Executor().execute(arg1: Counter(), arg2: 40, fun2: Counter.fun21)
        ..value.then((_) {
          list.add(_);
        }));
    }
    tasks.forEach((t) => t.cancel());
    Executor().execute(arg1: Counter(), arg2: 39, fun2: Counter.fun21)
      ..value.then((_) {
        list.add(_);
      });
    Executor().execute(arg1: Counter(), arg2: 40, fun2: Counter.fun21)
      ..value.then((_) {
        list.add(_);
      });
    await Future.delayed(Duration(seconds: 10), () {
      print(list);
      expect(list.length, 2);
    });
  });
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
