import 'dart:async';
import 'dart:isolate';
import 'package:async/async.dart';
import 'package:worker_manager/src/scheduling/task.dart';
import 'package:worker_manager/src/worker/worker.dart';

class WorkerImpl implements Worker {
  late Isolate _isolate;
  late ReceivePort _receivePort;
  late SendPort _sendPort;
  late StreamSubscription _portSub;
  late Completer<Object> _result;

  int? _runnableNumber;

  @override
  int? get runnableNumber => _runnableNumber;

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
      } else if (message is SendPort) {
        _sendPort = message;
        initCompleter.complete(true);
      } else {
        throw ArgumentError("Unrecognized message");
      }
    });
    await initCompleter.future;
  }

  @override
  Future<O> work<A, B, C, D, O>(Task<A, B, C, D, O> task) async{
    _runnableNumber = task.number;
    _result = Completer<Object>();
    _sendPort.send(Message(_execute, task.runnable));
    final resultValue = await (_result.future as Future<O>);
    _runnableNumber = null;
    return resultValue;
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
          sendPort.send(Result.error('cant send error with too big stackTrace, error is : ${error.toString()}'));
        }
      }
    });
  }

  @override
  Future<void> kill() async {
    await _portSub.cancel();
    _isolate.kill(priority: Isolate.immediate);
    _runnableNumber = null;
  }

}

class Message {
  final Function function;
  final Object argument;

  Message(this.function, this.argument);

  FutureOr call() async => await function(argument);
}
