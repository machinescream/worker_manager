import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

import 'worker_manager_test.dart';

void main() {
  test('adding stress test', () async {
    await Executor(threadPoolSize: 3).warmUp();

    final list = [];
    final tasks = [
      Task<int, int>(function: fib, bundle: 40),
      Task<String, String>(function: puk, bundle: '41'),
      Task<int, int>(function: fib, bundle: 42),
      Task(function: puk, bundle: '1'),
      Task<int, int>(function: fib, bundle: 40),
    ];
    tasks.forEach((task) {
      Executor().addTask(task: task).listen((data) {
        list.add(data);
      });
    });

    Executor().removeTask(task: tasks.first);
    Future.delayed(Duration(milliseconds: 100), () {
      Executor().removeTask(task: tasks.last);
    });

    await Future.delayed(Duration(seconds: 15), () {
      print(list);
      expect(list.length, 3);
    });
  });
}

String puk(String text) => text + '13';
