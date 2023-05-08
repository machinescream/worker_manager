import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void portCommunicationTests() {
  test("port communication", () async {
    late int message;
    await workerManager.executeWithPort(
      (port) => port.send(1),
      onMessage: (m) => message = m as int,
    );
    expect(message, 1);
  });
}
