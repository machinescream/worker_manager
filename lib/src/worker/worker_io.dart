import 'dart:async';
import 'dart:isolate';
import 'package:worker_manager/src/cancelable/cancelable.dart';
import 'package:worker_manager/src/scheduling/task.dart';
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
        case Object message:
          onMessage?.call(message);
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
    if (task is TaskWithPort) {
      onMessage = (task as TaskWithPort).onMessage;
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
    receivePort.handler = (message) async {
      try {
        final result =
            message is Execute ? await message() : await message(sendPort);
        sendPort.send(ResultSuccess(result));
      } catch (error, stackTrace) {
        sendPort.send(ResultError(error, stackTrace));
      }
    };
  }
}
