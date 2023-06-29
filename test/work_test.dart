import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void main() {
  test("get value", () async {
    final result = await workerManager.execute(() => 0);
    expect(result, 0);
  });

  test("get value twice sync", () async {
    final results = [
      await workerManager.execute(() => true),
      await workerManager.execute(() => true)
    ];
    expect(results.first, results.last);
  });

  test("get value twice in parallel", () async {
    final results = [
      workerManager.execute(() => true),
      workerManager.execute(() => true)
    ];
    final result1 = await results.first;
    final result2 = await results.last;

    expect(result1, result2);
  });
}
