import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}

void workTests() {
  test("Fibonacci calculation ones", () async {
    final result = await workerManager.execute(() => fib(30));
    expect(result, 832040);
  });

  test("Fibonacci calculation twice sync", () async {
    final (result1, result2) = (await workerManager.execute(() => fib(30)), await workerManager.execute(() => fib(30)));
    expect(result1, result2);
  });

  test("Fibonacci calculation twice in parallel", () async {
    final (task1, task2) = (workerManager.execute(() => fib(30)), workerManager.execute(() => fib(30)));
    final result1 = await task1;
    final result2 = await task2;

    expect(result1, result2);
  });
}
