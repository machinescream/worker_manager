import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

import 'worker_manager_test.dart';

void main() {
  test('adding stress test', () async {
    final list = [];
    final task1 = Task<int, int>(function: fib, bundle: 40);
    final task2 = Task<int, int>(function: fib, bundle: 40);
    final task3 = Task<int, int>(function: fib, bundle: 40);
    final task4 = Task<int, int>(function: fib, bundle: 40);
    final task5 = Task<int, int>(function: fib, bundle: 40);

    final tasks = [task1, task2, task3, task4, task5];

    tasks.forEach((task) {
      Executor(threadPoolSize: 5).addTask<int, int>(task: task).listen((data) {
        list.add(data);
      });
    });

    Executor().removeTask(task: task3);
    Executor().removeTask(task: task5);

    await Future.delayed(Duration(seconds: 20), () {
      print(list);
      expect(list.length, 3);
    });
  });
}
