import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

void main() {
  test('remove task', () async {
    final list = [];
    int i = 0;

    while (i < 5) {
      Executor().addTask<int, int>(task: Task<int, int>(function: fib, bundle: 40)).listen((data) {
        list.add(data);
      });
      i++;
    }

    await Future.delayed(Duration(seconds: 9), () {
      expect(list.isNotEmpty, true);
    });
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
