import 'dart:async';
import 'dart:isolate';
import 'package:async/async.dart';
import 'package:worker_manager/src/model/arguments_send_port.dart';
import 'package:worker_manager/src/model/value_update.dart';
import 'package:worker_manager/src/scheduling/runnable.dart';
import '../worker/worker.dart';
import '../scheduling/task.dart';

class WorkerImpl implements Worker {
  late Isolate _isolate;
  late ReceivePort _receivePort;
  late SendPort _sendPort;
  late StreamSubscription _portSub;
  late Completer<Object> _result;

  OnUpdateProgressCallback? _onUpdateProgress;
  int? _runnableNumber;
  Capability? _currentResumeCapability;
  var _paused = false;

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
        _onUpdateProgress = null;
      } else if (message is ErrorResult) {
        _result.completeError(message.error);
        _runnableNumber = null;
        _onUpdateProgress = null;
      } else if (message is SendPort) {
        _sendPort = message;
        initCompleter.complete(true);
        _runnableNumber = null;
        _onUpdateProgress = null;
      } else if (message is ValueUpdate) {
        if (_onUpdateProgress != null) {
          _onUpdateProgress!.call(message.value);
        }
      } else {
        throw ArgumentError("Unrecognized message");
      }
    });
    await initCompleter.future;
  }

  @override
  Future<O> work<A, B, C, D, O>(Task<A, B, C, D, O> task) async {
    _runnableNumber = task.number;
    _onUpdateProgress = task.onUpdateProgress;
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
        final argument = currentMessage.argument as Runnable;
        final firstArgument = argument.arg1;
        if (firstArgument is ArgumentsSendPort) {
          final newArgument = Runnable(
            arg1: firstArgument.copyWith(sendPort: sendPort),
            arg2: argument.arg2,
            arg3: argument.arg3,
            arg4: argument.arg4,
            fun1: argument.fun1,
            fun2: argument.fun2,
            fun3: argument.fun3,
            fun4: argument.fun4);
          final result = await function(newArgument);
          sendPort.send(Result.value(result));
        } else {
          final result = await function(argument);
          sendPort.send(Result.value(result));
        }
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
  Future<void> kill() {
    _paused = false;
    _currentResumeCapability = null;
    _isolate.kill(priority: Isolate.immediate);
    return _portSub.cancel();
  }

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
      _paused = false;
      final checkedCapability = _currentResumeCapability;
      if (checkedCapability != null) {
        _isolate.resume(checkedCapability);
      }
    }
  }

  @override
  bool get paused => _paused;
}

class Message {
  final Function function;
  final Object argument;

  Message(this.function, this.argument);

  FutureOr call() async => await function(argument);
}
