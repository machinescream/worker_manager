import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

void main() {
  test('adding stress test', () async {
    final list = [];
    int i = 0;

    while (i < 2000) {
      Executor(threadPoolSize: 10)
          .addTask<int, int>(task: Task<int, int>(function: fib, bundle: 40))
          .listen((data) {
        list.add(data);
      });
      i++;
    }

    await Future.delayed(Duration(seconds: 29), () {
      expect(list.length, 2000);
    });
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
