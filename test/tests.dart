import 'dart:async';
import 'package:test/test.dart';
import 'package:worker_manager/src/cancelable/cancel_token.dart';
import 'package:worker_manager/src/scheduling/executor.dart';
import 'package:worker_manager/src/cancelable/cancelable.dart';
import 'package:worker_manager/worker_manager.dart';

Cancelable<int?> doSomeMagicTrick() {
  return Cancelable.fromFuture(Future.delayed(const Duration(seconds: 1), () => 5)).next(onValue: (v) => v * 5);
}

Cancelable<void> nextTest() {

  return Executor().execute(arg1: 40, fun1: fib).next(onValue: (v) {
    print('returns nothing, but $v still');
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}

Future<int> isolateTask(String name, int value) async {
  print('run isolateTask $name');
  await Future.delayed(const Duration(milliseconds: 1));
  return value * 2;
}

Future<int> isolateTaskError(String name) {
  throw Exception('Exception: my custom test exception');
}

const oneSec = Duration(milliseconds: 1);

Future<void> main() async {
  await Executor().warmUp();

  test('thx to null safety...', () async {
    final c = Completer<int?>();
    c.complete();
  });

  test('magic', () async {
    final c = doSomeMagicTrick();
    final result = await c.next(onValue: (v) {
      return v;
    });
    expect(result, 25);
  });

  test('https://github.com/Renesanse/worker_manager/issues/14', () async {
    var results = 0;
    Future<void> increment(String name, int n) async {
      await Executor().execute(arg1: name, arg2: n, fun2: isolateTask).next(onValue: (value) {
        results++;
      });
    }

    await increment('fn1', 1);
    await increment('fn2', 2);
    await increment('fn3', 3);
    await increment('fn4', 4);
    await increment('fn5', 5);
    await increment('fn6', 6);
    await increment('fn7', 7);
    await increment('fn8', 8);
    await increment('fn9', 9);
    await increment('fn10', 10);
    await increment('fn11', 11);
    await increment('fn12', 12);
    await increment('fn13', 13);
    expect(results == 13, true);
  });

  test('chaining', () async {
    int? r;
    await Executor().execute(arg1: 40, fun1: fib).next(onValue: (value) async {
      return value + 1;
    }).next(onValue: (value) async {
      await Future.delayed(oneSec);
      return value + 1;
    }).next(onValue: (value) async {
      await Future.delayed(oneSec);
      return value + 1;
    }).next(onValue: (v) {
      r = v;
    });
    expect(r, 102334158);
  });

  test('onError', () async {
    Cancelable<int?>? c1;
    Future.delayed(oneSec * 0.01, () {
      c1!.cancel();
    });

    await (c1 = Executor().execute(arg1: 40, fun1: fib).next(onValue: (value) {
      print(value);
      return value;
    }, onError: (e) {
      print(e);
    }));
    print("finish");
  });

  test('onError chaining test', () async {
    int counter = 0;
    await Cancelable.fromFuture(Future.error(1)).next(onError: (value) {
      counter++;
      return Cancelable.fromFuture(Future.value(2));
    }).next(onValue: (value) {
      counter++;
      return Cancelable.fromFuture(Future.value(2));
    });
    expect(counter, 2);
  });

  test('stress adding', () async {
    final results = <int>[];
    for (var c = 0; c < 100; c++) {
     await Executor().execute(arg1: 38, fun1: fib).next(onValue: (value) {
        results.add(value);
      });
    }
    expect(results.length, 100);
  });

  test('stress adding, canceling', () async {
    final results = <int>[];
    final errors = <Object>[];
    Cancelable<void> lastTask;
    for (var c = 0; c < 100; c++) {
      lastTask = Executor().execute(arg1: 38, fun1: fib).next(onValue: (value) {
        results.add(value);
      }, onError: (Object e) {
        errors.add(e);
      });
      lastTask.cancel();
    }
    await Future.delayed(const Duration(seconds: 10));
    expect(errors.length, 100);
  });

  test('stress adding, canceling with token', () async {
    final results = <int>[];
    final errors = <Object>[];
    for (var c = 0; c < 100; c++) {
      final cancelationTokenSource = CancelTokenSource();
      Executor().execute(arg1: 38, fun1: fib).next(onValue: (value) {
        results.add(value);
      }, onError: (Object e) {
        errors.add(e);
      }).withToken(cancelationTokenSource.token);
      cancelationTokenSource.cancel();
    }
    await Future.delayed(const Duration(seconds: 10));
    expect(errors.length, 100);
  });

  test('callbacks', () async {
    await Executor().warmUp();
    final res = await Executor().execute(arg1: 10, fun1: fib, fake: true).next(onValue: (value) {
      return true;
    });
    print(res);
    await Future.delayed(const Duration(seconds: 1));
  });

  test('test fromFunction cancelationToken', () async {
    final results = <int>[];
    final errors = <Object>[];

    final cancelable = Cancelable.fromFunction((token) async {
      try {
        final res1 = await Executor().execute(arg1: '2x2', arg2: 2, fun2: isolateTask).withToken(token);
        results.add(res1);
        final res2 = await Executor().execute(arg1: '4x2', arg2: 4, fun2: isolateTask).withToken(token);
        results.add(res2);
        final res3 = await Executor().execute(arg1: '8x2', arg2: 8, fun2: isolateTask).withToken(token);
        results.add(res3);
        final res4 = await Executor().execute(arg1: '16x2', arg2: 16, fun2: isolateTask).withToken(token);
        results.add(res4);
      } catch (e) {
        errors.add(e);
      }
    });

    await Future.delayed(const Duration(milliseconds: 2100));
    expect(results.length, 2); // 2 computations should be compeleted after 2s
    cancelable.cancel();
    // wait to be sure that others computations were cancelled succesfully and results still the same
    await Future.delayed(const Duration(microseconds: 2500));
    expect(results.length, 2);
    expect(errors.length, 1);
    expect(errors[0], isA<CanceledError>());
  });

  test('isolatePool - should return the isolate back to pool on error', () async {
    var completedTasks = 0;
    for (int i = 0; i < 15; i++) {
      try {
        await Executor().execute(arg1: 'test', fun1: isolateTaskError);
      } catch (e) {
        // print(e);
      } finally {
        // print('completed task #$i');
        completedTasks++;
      }
    }
    expect(completedTasks, 15);
  });
}
