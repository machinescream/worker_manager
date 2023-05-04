// import 'dart:async';
// import 'package:worker_manager/src/port/send_port.dart';
// import 'package:worker_manager/src/worker/worker.dart';
// import 'package:worker_manager/src/scheduling/task.dart';
//
// class WorkerImpl implements Worker {
//   int? _runnableNumber;
//
//   @override
//   int? get id => _runnableNumber;
//   Completer? _result;
//
//   @override
//   Future<void> initialize() async => Future.value();
//
//   @override
//   Future<O> work<A, B, C, D, O, T>(Task<A, B, C, D, O, T> task) async {
//     _runnableNumber = task.number;
//
//     // Dummy sendPort for web
//     task.runnable.sendPort = TypeSendPort();
//
//     _result = Completer<O>();
//     if (!_result!.isCompleted) {
//       try {
//         var r = await _execute(task.runnable);
//         _result?.complete(r);
//       } catch (error, stacktrace) {
//         _result?.completeError(error, stacktrace);
//       } finally {
//         _runnableNumber = null;
//       }
//     }
//     return _result!.future as Future<O>;
//   }
//
//   static FutureOr _execute(Runnable runnable) => runnable();
//
//   @override
//   Future<void> kill() async {
//     _result = null;
//   }
//
//   @override
//   void pause() {}
//
//   @override
//   void resume() {}
//
//   @override
//   bool get paused => true;
//
//   @override
//   bool get initialized => true;
// }
