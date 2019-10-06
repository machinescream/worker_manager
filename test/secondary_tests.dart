import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

import 'worker_manager_test.dart';

void main() async {
  await Executor(threadPoolSize: 3).warmUp();
  test('adding stress test', () async {
    final list = [];
    final tasks = [
      Task<int>(function: fib, bundle: 40),
      Task<String>(function: puk, bundle: '41'),
      Task<int>(function: fib, bundle: 42, timeout: Duration(microseconds: 0)),
      Task(function: puk, bundle: '1'),
      Task<int>(function: fib, bundle: 40),
    ];
    tasks.forEach((task) {
      Executor().addTask(task: task).listen((data) {
        list.add(data);
      }).onError((error, stack) {});
    });

    Executor().removeTask(task: tasks.first);
    Future.delayed(Duration(milliseconds: 100), () {
      Executor().removeTask(task: tasks.last);
    });

    await Future.delayed(Duration(seconds: 5), () {
      print(list);
      expect(list.length, 2);
    });
  });
}

String puk(String text) => text + '13';
