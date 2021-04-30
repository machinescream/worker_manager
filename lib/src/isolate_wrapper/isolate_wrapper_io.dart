import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:worker_manager/src/task.dart';

import '../../worker_manager.dart';

class IsolateWrapperImpl implements IsolateWrapper {
  @override
  int? runnableNumber;

  late Isolate _isolate;
  late ReceivePort _receivePort;
  late StreamSubscription _portSub;
  late Completer _result;
  late SendPort _sendPort;

  @override
  Future<void> initialize() async {
    final initCompleter = Completer<bool>();
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _anotherIsolate,
      _receivePort.sendPort,
    );
    _portSub = _receivePort.listen((message) {
      if (message is ValueResult) {
        _result.complete(message.value);
      } else if (message is ErrorResult) {
        _result.completeError(message.error);
      } else {
        _sendPort = message as SendPort;
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
    _sendPort.send(Message(_execute, task.runnable));
    return _result.future as Future<O>;
  }

  static FutureOr _execute(runnable) => runnable();

  static void _anotherIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    receivePort.listen((message) async {
      try {
        final currentMessage = message as Message;
        final function = currentMessage.function;
        final argument = currentMessage.argument;
        final result = await function(argument);
        sendPort.send(Result.value(result));
      } catch (error) {
        try {
          sendPort.send(Result.error(error));
        } catch (error) {
          sendPort.send(Result.error(
              'cant send error with too big stackTrace, error is : ${error.toString()}'));
        }
      }
    });
  }

  @override
  Future<void> kill() async {
    await _portSub.cancel();
    _isolate.kill(priority: Isolate.immediate);
  }
}
