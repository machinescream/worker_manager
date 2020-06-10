import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:worker_manager/src/runnable.dart';
import 'package:worker_manager/src/task.dart';

abstract class IsolateWrapper {
  int runnableNumber;

  Future<void> initialize();

  Future<void> kill();

  Future<O> work<A, B, C, D, O>(Task<A, B, C, D, O> task);

  factory IsolateWrapper() => _IsolateWrapper();
}

class _IsolateWrapper implements IsolateWrapper {
  @override
  int runnableNumber;

  Isolate _isolate;
  ReceivePort _receivePort;
  SendPort _sendPort;
  StreamSubscription<Object> _portSub;
  Completer<Object> _result;

  @override
  Future<void> initialize() async {
    final initCompleter = Completer<bool>();
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_anotherIsolate, _receivePort.sendPort);
    _portSub = _receivePort.listen((message) {
      if (message is ValueResult) {
        _result.complete(message.value);
      } else if (message is ErrorResult) {
        _result.completeError(message.error);
      } else {
        _sendPort = message;
        initCompleter.complete(true);
      }
      runnableNumber = null;
    });
    await initCompleter.future;
  }

  @override
  Future<O> work<A, B, C, D, O>(Task<A, B, C, D, O> task) {
    runnableNumber = task.number;
    _result = Completer<O>();
    _sendPort.send(_Message(_execute, task.runnable));
    return _result.future;
  }

  static _execute(Runnable runnable) => runnable();

  static void _anotherIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen((message) async {
      try {
        final currentMessage = message as _Message;
        final function = currentMessage.function;
        final argument = currentMessage.argument;
        final result = await function(argument);
        sendPort.send(Result.value(result));
      } catch (error) {
        try {
          sendPort.send(Result.error(error));
        } catch (error) {
          sendPort.send(Result.error('cant send error with too big stackTrace, error is : ${error.toString()}'));
        }
      }
    });
  }

  @override
  Future<void> kill() async {
    await _portSub?.cancel();
    _result = null;
    _sendPort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

class _Message {
  final Function function;
  final Object argument;

  _Message(this.function, this.argument);

  FutureOr<Object> call() async => await function(argument);
}
