import 'dart:async';
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

  Completer<void>? _sendPortReceived;

  @override
  var initialized = false;

  @override
  String? taskId;

  void Function(Object value)? onMessage;

  @override
  bool get initializing {
    final sendPortReceived = _sendPortReceived;
    if (sendPortReceived != null) {
      return !sendPortReceived.isCompleted;
    }
    return false;
  }

  @override
  Future<void> initialize() async {
    _sendPortReceived = Completer<void>();
    _receivePort = RawReceivePort();
    _receivePort.handler = (Object result) {
      if (result is SendPort) {
        _sendPort = result;
        _sendPortReceived?.complete();
      } else if (result is ResultSuccess) {
        _result!.complete(result.value);
        _cleanUp();
      } else if (result is ResultError) {
        _result!.completeError(result.error, result.stackTrace);
        _cleanUp();
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
    await _sendPortReceived?.future;
    initialized = true;
  }

  @override
  Future<R> work<R>(Task<R> task) async {
    taskId = task.id;
    _result = Completer();
    _sendPort.send(task.execution);
    if (task is WithPort) {
      onMessage = (task as WithPort).onMessage;
    }
    final resultValue = await (_result!.future as Future<R>);
    return resultValue;
  }

  @override
  void cancelGentle() {
    _sendPort.send(CancelRequest());
  }

  @override
  void kill() {
    _result?.completeError(CanceledError());
    _cleanUp();
    initialized = false;
    _receivePort.close();
    _isolate.kill(priority: Isolate.immediate);
  }

  void _cleanUp() {
    _sendPortReceived = null;
    onMessage = null;
    taskId = null;
    _result = null;
  }

  static void _anotherIsolate(SendPort sendPort) {
    final receivePort = RawReceivePort();
    sendPort.send(receivePort.sendPort);
    var canceled = false;
    receivePort.handler = (message) async {
      try {
        late final dynamic result;
        canceled = false;
        if (message is Execute) {
          result = await message();
        } else if (message is ExecuteWithPort) {
          result = await message(sendPort);
        } else if (message is ExecuteGentle) {
          result = await message(() => canceled);
        } else if (message is ExecuteGentleWithPort) {
          result = await message(sendPort, () => canceled);
        } else if (message is CancelRequest) {
          canceled = true;
          throw CanceledError();
        }
        sendPort.send(ResultSuccess(result));
      } catch (error, stackTrace) {
        sendPort.send(ResultError(error, stackTrace));
      }
    };
  }
}
