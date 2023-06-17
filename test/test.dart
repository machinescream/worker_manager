import 'package:worker_manager/worker_manager.dart';

import 'tests/cancel_gentle.dart';
import 'tests/canceling_tests.dart';
import 'tests/chaining_tests.dart';
import 'tests/error_handling_tests.dart';
import 'tests/performance_tests.dart';
import 'tests/port_communication_tests.dart';
import 'tests/timeout_tests.dart';
import 'tests/work_tests.dart';

void main() {
  workerManager.log = true;
  workTests();
  performanceTests();
  cancelingTests();
  chainingTests();
  errorHandlingTests();
  portCommunicationTests();
  timeoutTests();
  cancelGentleTest();
}
