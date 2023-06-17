import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void cancelGentleTest() {
  test("cancel task gentle", () async {
    var canceledCaught = false;
    final task =
        workerManager.executeGentle((isCanceled) => forTest(isCanceled));
    await Future.delayed(Duration(milliseconds: 50));
    task.cancel();
    await task.catchError((_) {
      canceledCaught = true;
      return null;
    });
    expect(canceledCaught, true);
  });
}

Future<bool?> forTest(bool Function() isCancelled) async {
  await Future.delayed(Duration(milliseconds: 100));
  if (isCancelled()) {
    return null;
  }
  return false;
}
