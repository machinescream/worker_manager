import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

void main() {
  test('remove task', () async {
    final list = [];
    final task1 = Task(
        function: fib, bundle: 40, timeout: Duration(
        seconds: 5
        )
        );
    final task2 = Task(
        function: fib, bundle: 35, timeout: Duration(
        seconds: 5
        )
        );
    Executor(
    ).addTask(
        task: task1
        ).listen(
            (
            data
            ) {
      list.add(data);
    });
    Executor(
    ).addTask(
        task: task2
        ).listen(
            (
            data
            ) {
      list.add(data);
    });
//    Executor().addTask(task: task2).listen((data) {
//      //   list.add(data);
//    });
    //  Executor().removeTask(task: task2);
    await Future.delayed(
        Duration(
            seconds: 5
            ), (
        ) {
      expect(
          list.length, 2
          );
    });
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
