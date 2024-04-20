import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void main() {
  test("cancel task with regular catch", () async {
    final task = workerManager.execute(() => 0);

    final task3 = workerManager
        .execute(() => 0)
        .thenNext((value) => value, (error) => -1)
        .thenNext((value) => value);

    task.cancel();
    task3.cancel();

    final result = await task.catchError((_) => -1);
    final result3 = await task3;

    expect(result, -1);
    expect(result3, -1);
  });

  test("2", () async {
    final task2 = workerManager.execute(() => 0).thenNext((value) {
      return value;
    }, (error) {
      return -1;
    });
    task2.cancel();
    final result2 = await task2;
    expect(result2, -1);
  });
}
