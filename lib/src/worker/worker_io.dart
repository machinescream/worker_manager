import 'dart:async';
import 'dart:isolate';
import 'package:async/async.dart';
import 'package:worker_manager/src/scheduling/runnable.dart';
import 'package:worker_manager/worker_manager.dart';
import '../worker/worker.dart';
import '../scheduling/task.dart';

class WorkerImpl implements Worker {
  late Isolate _isolate;
  late ReceivePort _receivePort;
  late SendPort _sendPort;
  late StreamSubscription _portSub;
  late Completer<Object?> _result;

  Function? _onUpdateProgress;
  int? _runnableNumber;
  Capability? _currentResumeCapability;
  var _paused = false;

  @override
  int? get runnableNumber => _runnableNumber;

  var _initialized = false;

  @override
  bool get initialized => _initialized;

  void _cleanOnNewMessage() {
    _runnableNumber = null;
    _onUpdateProgress = null;
  }

  @override
  Future<void> initialize() async {
    final initCompleter = Completer<bool>();
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_anotherIsolate, _receivePort.sendPort);
    _portSub = _receivePort.listen((message) {
      if (message is ValueResult) {
        _result.complete(message.value);
        _cleanOnNewMessage();
      } else if (message is ErrorResult) {
        _result.completeError(message.error);
        _cleanOnNewMessage();
      } else if (message is SendPort) {
        _sendPort = message;
        initCompleter.complete(true);
        _initialized = true;
      } else {
        _onUpdateProgress?.call(message);
      }
    });
    await initCompleter.future;
  }

  // dart --enable-experiment=variance
  // need invariant support to apply onUpdateProgress generic type
  // inout T
  @override
  Future<O> work<A, B, C, D, O, T>(Task<A, B, C, D, O, T> task) async {
    _runnableNumber = task.number;
    _onUpdateProgress = task.onUpdateProgress;
    _result = Completer<Object?>();
    task.runnable.sendPort = TypeSendPort(sendPort: _sendPort)..firePendingMessages();
    _sendPort.send(Message(_execute, task.runnable));
    final resultValue = await (_result.future as Future<O>);
    return resultValue;
  }

  static FutureOr _execute(runnable) => runnable();

  static void _anotherIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    late final TypeSendPort porto;
    receivePort.listen(
      (message) async {
        if (message is Message) {
          try {
            final function = message.function;
            final runnable = message.argument as Runnable;
            porto = runnable.sendPort;
            // runnable.sendPort = TypeSendPort(sendPort: sendPort);
            final result = await function(runnable);
            sendPort.send(Result.value(result));
          } catch (error) {
            try {
              sendPort.send(Result.error(error));
            } catch (error) {
              sendPort.send(Result.error(
                  'cant send error with too big stackTrace, error is : ${error.toString()}'));
            }
          }
          return;
        }
        porto.onMessage(message);
      },
    );
  }

  @override
  Future<void> kill() {
    _initialized = false;
    _cleanOnNewMessage();
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