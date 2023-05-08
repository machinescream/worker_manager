import 'dart:async';

import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void timeoutTests() {
  group("timeout tests", () {
    setUp(() async {
      workerManager.dispose();
      await workerManager.init(isolatesCount: 1);
    });

    test("revise and schedule after timeout", () async {
      final result = await workerManager
          .execute(() => _timeouted().timeout(Duration(milliseconds: 500)))
          .thenNext(
            (value) => value,
            (error) => error,
          );
      expect(result is TimeoutException, true);
      final result2 = await workerManager.execute(() => _timeouted());
      expect(result2, true);
    });

    tearDown(() {
      workerManager.dispose();
    });
  });
}

Future<bool> _timeouted() async {
  await Future.delayed(Duration(seconds: 1));
  return true;
}
