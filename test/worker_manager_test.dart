import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';

void main() {
  test('adding stress test', () async {
    final list = [];
    final tasks = List.generate(3, (index) => Task(function: fib, arg: 6));
    tasks.forEach((task) {
      Executor().addTask(task: task).listen((data) {
        list.add(data);
      }).onError((e) {
        print(e);
      });
    });

    await Future.delayed(Duration(seconds: 5), () {
      print(list);
      expect(list.length, 3);
    });
  });

  test('fifo test', () async {
    final result = <int>[];
    final task1 = Task(function: fib, arg: 6);
    Executor().addTask(task: task1).listen((data) {
      result.add(data);
    });
    task1.cancel();
    final task2 = Task(function: fib, arg: 6);
    Executor().addTask(task: task2).listen((data) {
      result.add(data);
    });
    await Future.delayed(Duration(seconds: 1), () {
      expect(result.length, 1);
    });
  });
}

int fib(number) {
  if (number < 2) {
    return number;
  }
  return fib(number - 2) + fib(number - 1);
}
