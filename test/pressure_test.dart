import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

Future<void> main() async {
  test("_fibonacci calculation 100 times", () async {
    final time1 = DateTime.now();
    await Future.wait(List.generate(100, (_) {
      return workerManager.execute(() => _fib(40));
    }));
    final timeSpend1 = DateTime.now().difference(time1).inMilliseconds;
    print(timeSpend1);
    expect(true, true);
  });
}

int _fib(int n) {
  if (n < 2) {
    return n;
  }
  return _fib(n - 2) + _fib(n - 1);
}
