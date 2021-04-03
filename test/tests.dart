import 'dart:async';

import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:worker_manager/src/executor.dart';
import 'package:worker_manager/worker_manager.dart';

Cancelable<int> doSomeMagicTrick(){
  return Cancelable.fromFuture(Future.delayed(Duration(seconds: 1), () => 5))
      .next(onValue: (v) => v * 5);
}

Future<int> isolateTask(String name, int value) async {
  print('run isolateTask $name');
  await Future.delayed(Duration(seconds: 1));
  return value * 2;
}

Map<String, dynamic> from(Map<dynamic, dynamic> map) {
  print(map['1'].runtimeType.toString());
  return Map<String, dynamic>.from(map['1']);
}

void main() async {
  await Executor().warmUp();

  test('magic', () async{
    final c = doSomeMagicTrick();
    // Future.delayed(Duration(milliseconds: 100), (){
    //   c.cancel();
    // });
    final result = await c.next(onValue: (v) {
      print(v);
      return v;
    }, onError: (e){
      print(e);
    });


    print(result);
    expect(result, 25);
  });

  test('map canonization', () async {
    final newMap = await Executor().execute(arg1: <dynamic, dynamic>{
      '1': <dynamic, dynamic>{'1': 321}
    }, fun1: from);
    print(newMap);
  });

  test('https://github.com/Renesanse/worker_manager/issues/14', () async {
    var results = 0;
    void increment(String name, int n) {
      Executor().execute(arg1: name, arg2: n, fun2: isolateTask).next(
          onValue: (value) {
        results++;
        print('task $name, value $value');
      });
    }

    await Executor().warmUp();
    increment('fn1', 1);
    increment('fn2', 2);
    increment('fn3', 3);
    increment('fn4', 4);
    increment('fn5', 5);
    increment('fn6', 6);
    increment('fn7', 7);
    increment('fn8', 8);
    increment('fn9', 9);
    increment('fn10', 10);
    increment('fn11', 11);
    increment('fn12', 12);
    increment('fn13', 13);

    await Future.delayed(Duration(seconds: 3));
    expect(results == 13, true);
    print('test finished');
  });

  test('1', () async {
    await Executor().warmUp();
    final c =
        Executor().execute(arg1: 40, fun1: fib).next(onValue: (value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next(onValue: (value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next(onValue: (value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next(onValue: (value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next(onValue: (value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    });
//      ..catchError((e) {
//        print(e);
//      });
    await Future.delayed(Duration(seconds: 5));
    c.cancel();
  });

  test('HeapPriorityQueue', () async {
    final h = PriorityQueue<Task>();
    h.add(Task(0, workPriority: WorkPriority.immediately));
    h.add(Task(0, workPriority: WorkPriority.low));
    h.add(Task(0, workPriority: WorkPriority.veryHigh));
    h.add(Task(0, workPriority: WorkPriority.almostLow));
    h.add(Task(0, workPriority: WorkPriority.highRegular));
    h.add(Task(0, workPriority: WorkPriority.high));
    h.add(Task(0, workPriority: WorkPriority.regular));

    expect(
      h.toList().map((e) => e.workPriority),
      equals([
        WorkPriority.immediately,
        WorkPriority.veryHigh,
        WorkPriority.high,
        WorkPriority.highRegular,
        WorkPriority.regular,
        WorkPriority.almostLow,
        WorkPriority.low,
      ]),
    );
  });

  test('stress adding, canceling', () async {
    final r = await Executor().execute(arg1: 10, fun1: fib);
    print(r);
    await Executor().warmUp();
    final results = <int>[];
    final errors = <Object>[];
    Cancelable<void> lastTask;
    for (var c = 0; c < 100; c++) {
      lastTask = Executor().execute(arg1: 38, fun1: fib).next(onValue: (value) {
        results.add(value);
      })
        ..catchError((e) {
          errors.add(e);
        });
      lastTask.cancel();
    }
    await Future.delayed(Duration(seconds: 10));
    print(results.length);
    expect(errors.length, 100);
    print('test finished');
  });

  test('onError', () async {
    await Executor().warmUp();
    Cancelable<void> c1;
    c1 = Executor().execute(arg1: 40, fun1: fib).next(onValue: (value) {
      fib(value);
      // return value;
    }, onError: (e) {
      print('error');
    });
    await Future.delayed(Duration(seconds: 5));
  });

  test('callbacks', () async {
    await Executor().warmUp();
    Cancelable<bool> c1;
    final res = await (c1 =
        Executor().fakeExecute(arg1: 10, fun1: fib).next(onValue: (value) {
      return true;
    }));
    print(res);
    await Future.delayed(Duration(seconds: 1));
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
