import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:worker_manager/result.dart';

import 'isolate_bundle.dart';

mixin ThreadFlags {
  bool isBusy = false;
  int taskCode = 0;
}

abstract class Thread with ThreadFlags {
  Future<void> initPortConnection();

  Future<Result<O>> work<I, O>({@required Function function, I bundle});

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
  Future<Result<O>> work<I, O>({@required Function function, I bundle}) async {
    if (_isolate == null) await initPortConnection();
    isBusy = true;
    final receivePort = ReceivePort();
    _sendPort.send(IsolateBundle(port: receivePort.sendPort, function: function, bundle: bundle));
    final Result<O> result = await receivePort.first;
    isBusy = false;
    return result;
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
    Result<O> result;
    try {
      final data = bundle == null ? await function() : await function(bundle);
      result = Result(data: data);
    } catch (error) {
      result = Result(error: error);
    }
    sendPort.send(result);
  }
}
