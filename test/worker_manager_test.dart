import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

void main() {
  test('adding stress test', () async {
    await Executor(threadPoolSize: 5).warmUp();
    final tasks = [Task<int>(function: fib, bundle: 40), Task<int>(function: fib, bundle: 30)];
    final list = [];
    Executor().addTask<int>(task: tasks.first).listen((data) {
      list.add(data);
    });
    Executor().addTask<int>(task: tasks.last).listen((data) {
      list.add(data);
    });

    Executor().removeTask(task: tasks.last);

    Future.delayed(Duration(milliseconds: 100), () {
      Executor().removeTask(task: tasks.first);
    });
    await Future.delayed(Duration(seconds: 2), () {
      expect(list.length, 0);
    });
  });

  Task task1;

  test('fifo test', () async {
    await Executor(threadPoolSize: 2).warmUp();
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
