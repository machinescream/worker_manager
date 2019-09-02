// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.
library worker_manager;

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

enum WorkPriority { high, low }

class WorkerManager {
  final int threadPoolSize;
  final _workers = <Worker>[];
  final _queue = Queue<_QueueMember>();

  static final WorkerManager _manager = WorkerManager._internal();

  factory WorkerManager() {
    return _manager;
  }

  WorkerManager._internal({this.threadPoolSize = 4}) {
    for (int i = 0; i < threadPoolSize; i++) {
      _workers.add(Worker()
                   );
    }
  }

  Stream<O> manageWork<I, O>(
      {@required Function function, I bundle, Duration timeout, WorkPriority priority}) async* {
    final queueMember = _QueueMember(function: function, bundle: bundle, timeout: timeout
                                     );
    _queue.add(queueMember
               );
    manageQueue();
    yield await queueMember.completer.future;
  }

  void endWork() {
    _workers.forEach((worker) {
      worker.kill();
    }
                     );
    _workers.clear();
    _queue.clear();
  }

  void manageQueue<I, O>() async {
    if (_queue.isNotEmpty) {
      final availableWorker = _workers.firstWhere((worker) => !worker.isBusy, orElse: () => null
                                                  );
      if (availableWorker != null) {
        availableWorker.isBusy = true;
        final queueMember = _queue.removeFirst();
        Result result;
        try {
          result = await Future.microtask(() async {
            return await availableWorker.work<I, O>(
              function: queueMember.function, bundle: queueMember.bundle,
              );
          }
                                          ).timeout(queueMember.timeout, onTimeout: () {
            throw TimeoutException;
          }
                                                    );
        } catch (error) {
          result = Result(error: error
                          );
        }
        if (result.error != null) {
          queueMember.completer.completeError(result.error
                                              );
        } else {
          queueMember.completer.complete(result.data
                                         );
        }
        manageQueue();
      }
    }
  }
}

class _QueueMember<I, O> {
  final Function function;
  final I bundle;
  final Duration timeout;
  final completer = Completer();
  _QueueMember({this.function, this.bundle, this.timeout});
}

class Result<O> {
  final O data;
  final error;
  Result({this.data, this.error});
}

class Worker {
  Isolate _isolate;
  final _receivePort = ReceivePort();
  SendPort _sendPort;

  bool isBusy = false;

  Future<void> initPortConnection() async {
    _isolate = await Isolate.spawn(_handleWithPorts, _IsolateBundle(port: _receivePort.sendPort));
    _sendPort = await _receivePort.first;
  }

  Future<Result<O>> work<I, O>({@required Function function, I bundle}) async {
    if (_isolate == null) await initPortConnection();
    isBusy = true;
    final receivePort = ReceivePort();
    _sendPort.send(_IsolateBundle(port: receivePort.sendPort, function: function, bundle: bundle
                                  )
                   );
    final Result<O> result = await receivePort.first;
    isBusy = false;
    return result;
  }

  void kill() {
    _receivePort.close();
    _sendPort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }
}

class _IsolateBundle<I> {
  final SendPort port;
  final Function function;
  final I bundle;
  _IsolateBundle({this.port, this.function, this.bundle});
}

void _handleWithPorts<I, O>(_IsolateBundle isolateBundle) async {
  final receivePort = ReceivePort();
  isolateBundle.port.send(receivePort.sendPort);
  await for (_IsolateBundle<I> isolateBundle in receivePort) {
    final function = isolateBundle.function;
    final bundle = isolateBundle.bundle;
    final sendPort = isolateBundle.port;
    Result<O> result;
    try {
      final data = bundle == null ? await function() : await function(bundle
                                                                      );
      result = Result(data: data
                      );
    } catch (error) {
      result = Result(error: error);
    }
    sendPort.send(result);
  }
}
