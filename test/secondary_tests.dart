import 'package:flutter_test/flutter_test.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

import 'worker_manager_test.dart';

void main() async {
  test('adding stress test', () async {
    await Executor(isolatePoolSize: 2).warmUp();
    final list = [];
    final tasks = List.generate(2000, (i) {
      return Task<int>(function: fib, bundle: 30, timeout: Duration(seconds: 1));
    });
    tasks.forEach((task) {
      Executor().addTask<int>(task: task).listen((data) {
        list.add(data);
      }).onError((error, stack) {});
    });
    await Future.delayed(Duration(seconds: 10), () {
      expect(list.length, 2000);
    });
  });

//  test('scoped test', () async {
//    final list = [];
//    final tasks = List.generate(10, (i) {
//      return Task<int>(function: fib, bundle: 30, timeout: Duration(seconds: 1));
//    });
//    Executor().addScopedTask<int>(tasks: tasks).listen((data) {
//      list.addAll(data);
//    });
//    await Future.delayed(Duration(seconds: 10), () {
//      expect(list.length, 10);
//    });
//  });
}

String puk(String text) => text + '13';
