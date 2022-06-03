import 'dart:async';
import 'dart:isolate';
import 'package:async/async.dart';
import '../worker/worker.dart';
import '../scheduling/task.dart';

class WorkerImpl implements Worker {
  late Isolate _isolate;
  late ReceivePort _receivePort;
  late SendPort _sendPort;
  late StreamSubscription _portSub;
  late Completer<Object> _result;

  int? _runnableNumber;
  Capability? _currentResumeCapability;

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
        _runnableNumber = null;
      } else if (message is ErrorResult) {
        _result.completeError(message.error);
        _runnableNumber = null;
      } else if (message is SendPort) {
        _sendPort = message;
        initCompleter.complete(true);
        _runnableNumber = null;
      } else {
        throw ArgumentError("Unrecognized message");
      }
    });
    await initCompleter.future;
  }

  @override
  Future<O> work<A, B, C, D, O>(Task<A, B, C, D, O> task) async {
    _runnableNumber = task.number;
    _result = Completer<Object>();
    _sendPort.send(Message(_execute, task.runnable));
    final resultValue = await (_result.future as Future<O>);
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
          sendPort.send(Result.error(
              'cant send error with too big stackTrace, error is : ${error.toString()}'));
        }
      }
    });
  }

  @override
  Future<void> kill() async {
    await _portSub.cancel();
    _currentResumeCapability = null;
    _isolate.kill(priority: Isolate.immediate);
  }

  var _paused = false;

  @override
  void pause() {
    if (!_paused) {
      _paused = true;
      _currentResumeCapability ??= Capability();
      _isolate.pause(_currentResumeCapability);
    }
  }

  @override
  void resume() {
    if (_paused) {
      final checkedCapability = _currentResumeCapability;
      if (checkedCapability != null) {
        _isolate.resume(checkedCapability);
      }
    }
  }
}

class Message {
  final Function function;
  final Object argument;

  Message(this.function, this.argument);

  FutureOr call() async => await function(argument);
}
