import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:worker_manager/task.dart';

import 'isolate_bundle.dart';

mixin ThreadFlags {
  bool isBusy = false;
  int taskCode = 0;
}

abstract class Thread with ThreadFlags {
  Future<void> initPortConnection();

  Stream<Result<O>> work<I, O>(
      {@required Task task}
      );

  void cancel();

  factory Thread() => _Worker();
}

class _Worker with ThreadFlags implements Thread {
  Isolate _isolate;
  final _receivePort = ReceivePort();
  SendPort _sendPort;

  @override
  Future<void> initPortConnection() async {
    _isolate = await Isolate.spawn(_handleWithPorts, IsolateBundle(port: _receivePort.sendPort));
    _sendPort = await _receivePort.first;
  }

  @override
  Stream<Result<O>> work<I, O>(
      {@required Task task}
      ) async* {
    isBusy = true;
    if (_isolate == null) await initPortConnection(
    );
    final receivePort = ReceivePort();
    _sendPort.send(
        IsolateBundle(
            port: receivePort.sendPort,
            function: task.function,
            bundle: task.bundle,
            timeout: task.timeout
            )
        );
    final Result<O> result = await receivePort.first;
    isBusy = false;
    yield result;
  }

  @override
  void cancel() {
    _receivePort.close();
    _sendPort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

void _handleWithPorts<I, O>(IsolateBundle isolateBundle) async {
  final receivePort = ReceivePort();
  isolateBundle.port.send(receivePort.sendPort);
  await for (IsolateBundle<I> isolateBundle in receivePort) {
    final function = isolateBundle.function;
    final bundle = isolateBundle.bundle;
    final sendPort = isolateBundle.port;
    final timeout = isolateBundle.timeout;
    Result result;
    Future execute(
        ) async =>
        Result.value(
            bundle == null ? await function(
            ) : await function(
                bundle
                )
            );
    try {
      result = await Future.microtask(
              (
              ) async {
            return await Future.delayed(
                Duration(
                    microseconds: 0
                    ), (
                ) async {
              return await execute(
              );
            }
                );
          }
              ).timeout(
          timeout, onTimeout: (
          ) {
        throw TimeoutException;
      }
          );
    } catch (error) {
      result = Result.error(
          error
          );
    }
    sendPort.send(result);
  }
}
