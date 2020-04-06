import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/runnable.dart';
import 'package:worker_manager/task.dart';

import 'secondary_tests.dart';

void main() {
  test('adding stress test', () async {
    final list = [];
    final tasks = List.generate(
        3, (index) => Task2(runnable: Runnable(arg1: Counter(), arg2: 40, fun2: Counter.fun21)));
    tasks.forEach((task) {
      Executor().addTask(task: task).then((data) {
        list.add(data);
      }).catchError((e) {
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
    final task1 = Task2(runnable: Runnable(arg1: Counter(), arg2: 6, fun2: Counter.fun21));
    Executor().addTask(task: task1).then((data) {
      result.add(data);
    });
    task1.cancel();
    final task2 = Task2(runnable: Runnable(arg1: Counter(), arg2: 6, fun2: Counter.fun21));
    Executor().addTask(task: task2).then((data) {
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
