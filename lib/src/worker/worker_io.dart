import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:worker_manager/src/cancelable/cancelable.dart';
import 'package:worker_manager/src/scheduling/task.dart';
import 'package:worker_manager/src/worker/cancel_request.dart';
import 'package:worker_manager/src/worker/result.dart';
import 'package:worker_manager/src/worker/worker.dart';

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

  void Function(Object value)? onMessage;

  @override
  Future<void> initialize() async {
    _sendPortReceived = Completer<void>();
    _receivePort = RawReceivePort();
    _receivePort.handler = (Object result) {
      final resultChecked = result;
      if (resultChecked is SendPort) {
        _sendPort = result as SendPort;
        _sendPortReceived.complete();
      } else if (resultChecked is ResultSuccess) {
        _result!.complete((result as ResultSuccess).value);
        _result = null;
      } else if (resultChecked is ResultError) {
        final error = (result as ResultError).error;
        _result!.completeError(result.error, result.stackTrace);
        _result = null;
        if (error is TimeoutException) {
          restart();
        }
      } else {
        onMessage?.call(result);
      }
    };
    _isolate = await Isolate.spawn(
      _anotherIsolate,
      _receivePort.sendPort,
      errorsAreFatal: false,
      paused: false,
    );
    await _sendPortReceived.future;
    initialized = true;
  }

  @override
  Future<R> work<R>(Task<R> task) async {
    taskId = task.id;
    _result = Completer();
    _isolate.resume(_isolate.pauseCapability!);
    await _sendPortReceived.future;
    _sendPort.send(task.execution);
    if (task is WithPort) {
      onMessage = (task as WithPort).onMessage;
    }
    final resultValue = await (_result!.future as Future<R>).whenComplete(() {
      _cleanUp();
      _isolate.pause(_isolate.pauseCapability!);
    });
    return resultValue;
  }

  @override
  Future<void> restart() async {
    kill();
    await initialize();
    onReviseAfterTimeout();
  }

  @override
  void cancelGentle() {
    _cleanUp();
    _result?.completeError(CanceledError());
    _sendPort.send(CancelRequest());
  }

  @override
  void kill() {
    _cleanUp();
    _result?.completeError(CanceledError());
    initialized = false;
    _receivePort.close();
    _isolate.kill(priority: Isolate.immediate);
  }

  void _cleanUp() {
    onMessage = null;
    taskId = null;
  }

  static void _anotherIsolate(SendPort sendPort) {
    final receivePort = RawReceivePort();
    sendPort.send(receivePort.sendPort);
    var canceled = false;
    receivePort.handler = (message) async {
      try {
        late final dynamic result;
        if (message is Execute) {
          result = await message();
        } else if (message is ExecuteWithPort) {
          result = await message(sendPort);
        } else if (message is ExecuteGentle) {
          result = await message(() => canceled);
          if (canceled) {
            return canceled = false;
          }
        } else if (message is ExecuteGentleWithPort) {
          result = await message(sendPort, () => canceled);
          if (canceled) {
            return canceled = false;
          }
        } else if (message is CancelRequest) {
          return canceled = true;
        }
        sendPort.send(ResultSuccess(result));
      } catch (error, stackTrace) {
        sendPort.send(ResultError(error, stackTrace));
      }
    };
  }
}
