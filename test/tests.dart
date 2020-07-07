import 'package:test/test.dart';
import 'package:worker_manager/src/executor.dart';

void main() async {
  test('1', () async {
    await Executor().warmUp();
    final result = await Executor().execute(arg1: 20, fun1: fib).next((value) {
      return -value;
    }).catchError((e) {
//      return -1;
    });
    print(result);
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
