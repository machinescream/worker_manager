import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:worker_manager/task.dart';

import 'isolate_bundle.dart';

mixin ThreadFlags {
  bool isBusy = false;
  final isInitialized = Completer<bool>();
  String taskId = '';
}

abstract class Thread with ThreadFlags {
  Future<void> initPortConnection();

  Stream<Result> work({@required Task task});

  void cancel();

  factory Thread() => _Worker();
}

class _Worker with ThreadFlags implements Thread {
  Isolate _isolate;
  SendPort _sendPort;
  final receivePort = ReceivePort();

  @override
  Future<void> initPortConnection() async {
    _isolate = await Isolate.spawn(_handleWithPorts, receivePort.sendPort);
  }

  @override
  Stream<Result> work({@required Task task}){
    if (taskId == null) {
      isInitialized.complete(true);
      return Stream.value(Result.error('isolate closed'));
    } else {
      if(_isolate == null){
        return Stream.fromFuture(initPortConnection())..listen((_){
          isInitialized.complete(true);
          return null;
        });
      }else{
        return (receivePort as Stream)..listen((message){
          if(message is SendPort) {
            _sendPort = message as SendPort;
        _sendPort.send(IsolateBundle(function: task.function, bundle: task.bundle, timeout: task.timeout));
          }else{

          }
        });






      }
    }



    final resultFromIsolate = await receivePort.first.catchError((error, stackTrace) {
      return Result.error('isolate closed');
    }) as Result;
    taskId = '';
    isBusy = false;
    yield resultFromIsolate is ErrorResult
        ? Result.error(resultFromIsolate.asError.error)
        : Result.value(resultFromIsolate.asValue.value);
  }

  @override
  void cancel() {
    _sendPort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

void _handleWithPorts(SendPort port) async {
  final receivePort = ReceivePort();
  port.send(receivePort.sendPort);
  await for (IsolateBundle isolateBundle in receivePort) {
    SendPort sendPort = port;
    final function = isolateBundle.function;
    final bundle = isolateBundle.bundle;
    final timeout = isolateBundle.timeout;
    Result result;
    Future execute() async => Future.microtask(() async {
          return await Future.delayed(Duration(microseconds: 0), () async {
            return Result.value(bundle == null ? await function() : await function(bundle));
          });
        });
    try {
      result = timeout != null
          ? await execute().timeout(timeout, onTimeout: () {
              throw TimeoutException;
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
