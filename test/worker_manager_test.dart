import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/src/executor.dart';
import 'package:worker_manager/src/task.dart';

void main() {
  test('adding stress test', () async {
    final list = [];
    final tasks = List.generate(3, (index) => Task(function: fib, arg: 40, timeout: Duration.zero));
    tasks.forEach((task) {
      Executor().addTask(task: task).listen((data) {
        list.add(data);
      }).onError((e) {
        print(e);
      });
    });

    await Future.delayed(Duration(seconds: 2), () {
      print(list);
      expect(list.length, 0);
    });
  });

  test('fifo test', () async {
    final result = <int>[];
    final task1 = Task(function: fib, arg: 10);
    Executor().addTask(task: task1).listen((data) {
      result.add(data);
    });
//    Executor().removeTask(task: task1);
//    final task2 = Task(function: fib, arg: 30);
//    Executor().addTask(task: task2).listen((data) {
//      result.add(task2);
//    });
    await Future.delayed(Duration(seconds: 1), () {
      expect(result.length, 1);
    });
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
