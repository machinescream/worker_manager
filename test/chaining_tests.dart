import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void chainingTests() {
  test("chaining", () async {
    final result = await workerManager
        .execute(() => 0)
        .thenNext((value) => value + 1)
        .thenNext((value) => value + 1)
        .thenNext((value) => value + 1);
    expect(result, 3);
  });
}
