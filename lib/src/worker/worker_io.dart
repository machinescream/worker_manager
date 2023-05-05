import 'dart:async';
import 'dart:isolate';
import 'package:worker_manager/src/worker/result.dart';
import 'package:worker_manager/src/worker/worker.dart';
import 'package:worker_manager/src/scheduling/task.dart';
import 'package:worker_manager/worker_manager.dart';

class WorkerImpl implements Worker {
  final void Function() onReviseAfterTimeout;

  WorkerImpl(this.onReviseAfterTimeout);

  late Isolate _isolate;
  late RawReceivePort _receivePort;
  late SendPort _sendPort;
  Completer? _result;

  late Completer<void> _sendPortReceived;

  @override
  var initialized = false;

  @override
  String? taskId;

  // Function? _onUpdateProgress;

  // Capability? _currentResumeCapability;
  // var _paused = false;

  // void _cleanOnNewMessage() {
  //   _runnableNumber = null;
  //   _onUpdateProgress = null;
  // }

  @override
  Future<void> initialize() async {
    _sendPortReceived = Completer<void>();
    _receivePort = RawReceivePort();
    _receivePort.handler = (Object result) {
      switch (result) {
        case SendPort port:
          _sendPort = port;
          _sendPortReceived.complete();
        case ResultSuccess _:
          _result!.complete(result.value);
          _result = null;
        case ResultError _:
          final error = result.error;
          _result!.completeError(result.error, result.stackTrace);
          _result = null;
          if (error is TimeoutException) {
            restart();
          }
      }
    };
    _isolate = await Isolate.spawn(
      _anotherIsolate,
      _receivePort.sendPort,
      errorsAreFatal: false,
      paused: false,
    );
    initialized = true;
  }

  @override
  Future<R> work<R>(Task<R> task) async {
    taskId = task.id;
    _result = Completer();
    _isolate.resume(_isolate.pauseCapability!);
    await _sendPortReceived.future;
    _sendPort.send(task.execution);
    // _onUpdateProgress = task.onUpdateProgress;
    // task.runnable.sendPort = TypeSendPort(sendPort: _receivePort.sendPort);
    final resultValue = await (_result!.future as Future<R>);
    _isolate.pause(_isolate.pauseCapability!);
    taskId = null;
    return resultValue;
  }

  @override
  Future<void> restart() async {
    kill();
    await initialize();
    onReviseAfterTimeout();
  }

  @override
  void kill() {
    _result?.completeError(CanceledError());
    initialized = false;
    _receivePort.close();
    taskId = null;
    // _cleanOnNewMessage();
    // _paused = false;
    // _currentResumeCapability = null;
    _isolate.kill(priority: Isolate.immediate);
  }

  static void _anotherIsolate(SendPort sendPort) {
    final receivePort = RawReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.handler = (message) async {
      try {
        final result = await message();
        sendPort.send(ResultSuccess(result));
      } catch (error, stackTrace) {
        sendPort.send(ResultError(error, stackTrace));
      }
    };
  }

// @override
  // void pause() {
  //   if (!_paused) {
  //     _paused = true;
  //     _currentResumeCapability ??= Capability();
  //     _isolate.pause(_currentResumeCapability);
  //   }
  // }
  //
  // @override
  // void resume() {
  //   if (_paused) {
  //     _paused = false;
  //     final checkedCapability = _currentResumeCapability;
  //     if (checkedCapability != null) {
  //       _isolate.resume(checkedCapability);
  //     }
  //   }
  // }
  //
  // @override
  // bool get paused => _paused;
}

// late TypeSendPort port;
// receivePort.listen(
//   (message) async {
//     if (message is Message) {
//       try {
//         final function = message.function;
//         final runnable = message.argument as Runnable;
//         port = runnable.sendPort;
//         final result = await function(runnable);
//         sendPort.send(Result.value(result));
//       } catch (error) {
//         try {
//           sendPort.send(Result.error(error));
//         } catch (error) {
//           sendPort.send(Result.error(
//               'cant send error with too big stackTrace, error is : ${error.toString()}'));
//         }
//       }
//       return;
//     }
//     port.onMessage?.call(message);
//   },
// );
