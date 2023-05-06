import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void workTests() {
  test("get value", () async {
    final result = await workerManager.execute(() => 0);
    expect(result, 0);
  });

  test("get value twice sync", () async {
    final (result1, result2) = (
      await workerManager.execute(() => true),
      await workerManager.execute(() => true)
    );
    expect(result1, result2);
  });

  test("get value twice in parallel", () async {
    final (task1, task2) = (
      workerManager.execute(() => true),
      workerManager.execute(() => true)
    );
    final result1 = await task1;
    final result2 = await task2;

    expect(result1, result2);
  });
}
