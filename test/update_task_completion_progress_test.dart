import 'dart:async';
import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void main() async {
  late Executor executor;
  late StreamController controller;

  setUp(() async {
    executor = Executor();
    controller = StreamController.broadcast();

    await executor.warmUp(log: true);
  });

  tearDown(() {
    controller.close();
  });

  group('update_task_completion_progress test', () {
    test('onUpdateProgress should get value from sendPort', () async {
      var stream = controller.stream;
      final totalTitle = 'Total current: ';

      final result = await executor.execute(
          arg1: totalTitle,
          fun1: isolateTask,
          fake: true,
          notification: (int value) {
            print('onUpdateProgress: $value');
            controller.add(value);
          });

      stream.listen((event) {
        print('stream::listen:Event: $event');
        expect([1, 2, 3, 4, 5], containsValue(event));
      });

      expect(result, 15);
    });
  });
}

Future<int> isolateTask(String arguments, TypeSendPort<int> port) async {
  var count = 0;
  var sum = 0;

  while (count < 5) {
    count++;
    await Future.delayed(const Duration(milliseconds: 100));
    sum += count;
    port.send(count);
  }

  return sum;
}
