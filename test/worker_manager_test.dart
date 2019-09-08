import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

void main() {
  test('remove task', () async {
    final list = [];
    final task1 = Task(function: fib, bundle: 40);
    final task2 = Task(function: fib, bundle: 35);
    Executor().addTask(task: task1);
    Executor().resultOf(task: task1).listen((data) {
      list.add(data);
    });
    Executor().addTask(task: task2);
    Executor().resultOf(task: task2).listen((data) {
      list.add(data);
    });
    Executor().removeTask(task: task2);
    await Future.delayed(Duration(seconds: 10), () {
      expect(list.length, 1);
    });
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
