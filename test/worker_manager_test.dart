import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

void main() {
  test('adding stress test', () async {
    final list = [];
    final tasks = List.generate(10, (index) => Task<int>(function: fib, bundle: index));
    tasks.forEach((task) {
      Executor().addTask<int>(task: task).listen((data) {
        list.add(data);
      });
    });

    tasks.forEach((task) {
      Executor().removeTask(task: task);
    });

    await Future.delayed(Duration(seconds: 2), () {
      expect(list.length, 0);
    });
  });

  Task task1;

  test('fifo test', () async {
    task1 = Task(function: fib, bundle: 30);
    Executor().addTask(task: task1);
    Executor().removeTask(task: task1);
    task1 = Task(function: fib, bundle: 30);
    Executor().addTask(task: task1).listen((data) {
      print(data);
    });
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
