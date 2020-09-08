import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:worker_manager/src/executor.dart';
import 'package:worker_manager/worker_manager.dart';

Future<int> isolateTask(String name, int value) async {
  print('run isolateTask $name');
  await Future.delayed(Duration(seconds: 1));
  return value * 2;
}

void main() async {
  test('https://github.com/Renesanse/worker_manager/issues/14', () async {
    var results = 0;
    void increment(String name, int n) {
      Executor().execute(arg1: name, arg2: n, fun2: isolateTask).next((value) {
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
    final c = Executor().execute(arg1: 40, fun1: fib).next((value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next((value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next((value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next((value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next((value) async {
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
        h.toList().toString() ==
            [
              WorkPriority.immediately,
              WorkPriority.veryHigh,
              WorkPriority.high,
              WorkPriority.highRegular,
              WorkPriority.regular,
              WorkPriority.almostLow,
              WorkPriority.low
            ].toString(),
        true);
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
