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
    // dbl protection
    // Executor().removeTask(task: tasks.first);

    Future.delayed(Duration(milliseconds: 100), () {
      Executor().removeTask(task: tasks.first);
    });
    await Future.delayed(Duration(seconds: 2), () {
      expect(list.length, 0);
    });
  });

  test('fifo test', () async {
    final tasks = [
      Task<int>(function: fib, bundle: 10),
//      Task<int>(function: fib, bundle: 30),
//      Task<int>(function: fib, bundle: 20),
//      Task<int>(function: fib, bundle: 10)
    ];
    final list = [];
    Executor()
        .addTask<int>(task: Task<int>(function: fib, bundle: 10), isFifo: true)
        .listen((data) {
      list.add(data);
    });
    await Future.delayed(Duration(seconds: 7), () {
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
