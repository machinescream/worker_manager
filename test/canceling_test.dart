import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void main() {
  test("cancel task with regular catch", () async {
    final task = workerManager.execute(() => 0);

    final task2 = workerManager.execute(() => 0).thenNext((value) {
      return value;
    }, (error) {
      return -1;
    });

    final task3 = workerManager
        .execute(() => 0)
        .thenNext((value) => value, (error) => -1)
        .thenNext((value) => value);

    task.cancel();
    task2.cancel();
    task3.cancel();

    final result = await task.catchError((_) => -1);
    final result2 = await task2;
    final result3 = await task3;

    expect(result, -1);
    expect(result2, -1);
    expect(result3, -1);
  });
}
