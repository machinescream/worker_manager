import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void main() {
  test("cancel task with regular catch", () async {
    final task = workerManager.execute(() => 0);
    task.cancel();
    final result = await task.catchError((_) => -1);
    expect(result, -1);
  });

  test("cancel task", () async {
    final task = workerManager.execute(() => 0).thenNext((value) {
      return value;
    }, (error) {
      return -1;
    });
    task.cancel();
    final result = await task;
    expect(result, -1);
  });

  test("cancel task with chaining", () async {
    final task = workerManager
        .execute(() => 0)
        .thenNext((value) => value, (error) => -1)
        .thenNext((value) => value);
    task.cancel();
    final result = await task;
    expect(result, -1);
  });
}
