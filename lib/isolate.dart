import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:worker_manager/runnable.dart';

import 'executor.dart';

abstract class WorkerIsolate {
  factory WorkerIsolate.worker() => _Worker();

  bool get isInitialized;

  bool get isBusy;

  String get taskId;

  Completer<bool> get initializationCompleter;

  void initPortConnection();

  Stream<Result> work<O>({@required Task<Object, Object, Object, Object, Object, O> task});

  void cancel();
}

class _Worker implements WorkerIsolate {
  //data bridges
  Isolate _isolate;
  SendPort _sendPort;
  ReceivePort _receivePort;
  var _resultCompleter = Completer<Result>();

  //flags
  bool isBusy = false;
  bool isInitialized = false;
  String taskId = '';
  var initializationCompleter = Completer<bool>();

  @override
  void initPortConnection() {
    _receivePort = ReceivePort();
    Isolate.spawn(_handleWithPorts, _receivePort.sendPort).then((isolate) {
      _isolate = isolate;
      _receivePort.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          initializationCompleter.complete(true);
          isInitialized = true;
        } else {
          final resultFromIsolate = message as Result;
          resultFromIsolate is ErrorResult
              ? _resultCompleter.complete(Result.error(resultFromIsolate.asError.error))
              : _resultCompleter.complete(Result.value(resultFromIsolate.asValue.value));
          taskId = '';
          isBusy = false;
          _resultCompleter = null;
        }
      });
    });
  }

  static O run<A, B, C, D, E, O>(Runnable<A, B, C, D, E, O> run) => run();

  @override
  Stream<Result> work<O>({@required Task<Object, Object, Object, Object, Object, O> task}) {
    isBusy = true;
    taskId = task.id;
    _resultCompleter = Completer<Result>();
    _sendPort.send(_IsolateBundle(function: run, bundle: task.runnable, timeout: task.timeout));
    return Stream.fromFuture(_resultCompleter.future);
  }

  @override
  void cancel() {
    taskId = '';
    _receivePort = null;
    _sendPort = null;
    isInitialized ? _killIsolate(isInitialized) : initializationCompleter.future.then(_killIsolate);
    isInitialized = false;
  }

  void _killIsolate(bool isInitialized) {
    _isolate.kill(priority: Isolate.immediate);
    _isolate = null;
    isBusy = false;
    initializationCompleter = Completer<bool>();
    initPortConnection();
  }

  static void _handleWithPorts(SendPort sendPort) async {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    await for (_IsolateBundle isolateBundle in receivePort) {
      final function = isolateBundle.function;
      final bundle = isolateBundle.bundle;
      final timeout = isolateBundle.timeout;
      Result result;
      Future execute() async => Future.microtask(() async {
            return await Future.delayed(Duration.zero, () async {
              return Result.value(bundle == null ? await function() : await function(bundle));
            });
          });
      try {
        result = timeout != null
            ? await execute().timeout(timeout, onTimeout: () {
                throw TimeoutException('isolate finished work with timeout', timeout);
              })
            : await execute();
      } catch (error) {
        result = Result.error(error);
      }
      try {
        sendPort.send(result);
      } catch (_) {
        sendPort.send(Result.error('isolate error: ${(result as ErrorResult).error.toString()}'));
      }
    }
  }
}

class _IsolateBundle {
  final Function function;
  final Object bundle;
  final Duration timeout;

  _IsolateBundle({this.function, this.bundle, this.timeout});
}
