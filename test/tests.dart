import 'package:test/test.dart';
import 'package:worker_manager/src/executor.dart';
import 'package:collection/collection.dart';
import 'package:worker_manager/worker_manager.dart';

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
    }).next((value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    }).next((value) async {
      await Future.delayed(Duration(seconds: 1));
      print(value);
      return value++;
    })
      ..catchError((e) {
        print(e);
      });
    await Future.delayed(Duration(seconds: 3));
    c.cancel();
  });

  test('HeapPriorityQueue', () async {

    final h = PriorityQueue<Task>();
    h.add(Task(0, workPriority: WorkPriority.immediately));
    h.add(Task(0, workPriority: WorkPriority.low));
    h.add(Task(0, workPriority: WorkPriority.veryHigh));
    h.add(Task(0, workPriority: WorkPriority.almostLow));
    h.add(Task(0, workPriority: WorkPriority.highRegular));
    h.add(Task(0, workPriority: WorkPriority.high));
    h.add(Task(0, workPriority: WorkPriority.regular));

    expect(
        h.toList().toString() ==
            [
              WorkPriority.immediately,
              WorkPriority.veryHigh,
              WorkPriority.high,
              WorkPriority.highRegular,
              WorkPriority.regular,
              WorkPriority.almostLow,
              WorkPriority.low
            ].toString(),
        true);
  });
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
