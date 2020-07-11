import 'package:test/test.dart';
import 'package:worker_manager/src/executor.dart';

void main() async {
  test('1', () async {
    await Executor().warmUp();
    final c = Executor().execute(arg1: 50, fun1: fib).next((value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next((value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next((value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next((value) async{
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next((value) async{
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    })..catchError((e) {
      print(e);
    });
    await Future.delayed(Duration(seconds: 3));
    c.cancel();
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
