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
  final _workers = <_Worker>[];
  final _queue = Queue<Task>();

  static final WorkerManager _manager = WorkerManager._internal();

  factory WorkerManager() => _manager;

  WorkerManager._internal({this.threadPoolSize = 3}) {
    for (int i = 0; i < threadPoolSize; i++) {
      _workers.add(_Worker()
                   );
    }
  }

  Future<void> initManager() async =>
      await Future.wait(_workers.map((worker) => worker.initPortConnection()
                                     )
                        );

  Stream<O> manageWork<I, O>(
      {@required Task task, WorkPriority priority = WorkPriority.high}) async* {
    priority == WorkPriority.high ? _queue.addFirst(task
                                                    ) : _queue.addLast(task
                                                                       );
    manageQueue();
    yield await task.completer.future;
  }

  void killTask({@required Task task}) {
    if (_queue.contains(task
                        )) _queue.remove(task
                                         );
    _workers.forEach((worker) {
      if (worker.taskCode == task.hashCode) {
        worker.kill();
      }
      while (_workers.length < 3) {
        _workers.add(_Worker()
                     );
      }
    }
                     );
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
      ///semafor ???
      final availableWorker = _workers.firstWhere((worker) => !worker.isBusy, orElse: () => null
                                                  );
      if (availableWorker != null) {
        availableWorker.isBusy = true;
        final task = _queue.removeFirst();
        availableWorker.taskCode = task.hashCode;
        Result result;
        try {
          Future<Result> execute() async =>
              await availableWorker.work<I, O>(function: task.function, bundle: task.bundle,
              );
          result = (task.timeout != null) ? await Future.microtask(() async {
            return await execute();
          }
                                                                   ).timeout(
              task.timeout, onTimeout: () {
            throw TimeoutException;
          }
              ) : await execute();
        } catch (error) {
          result = Result(error: error
                          );
        }
        if (result.error != null) {
          task.completer.completeError(result.error
                                       );
        } else {
          task.completer.complete(result.data
                                  );
        }
        manageQueue();
      }
    }
  }
}

class Task<I, O> {
  final Function function;
  final I bundle;
  final Duration timeout;
  final completer = Completer();
  Task({this.function, this.bundle, this.timeout});

  @override
  bool operator ==(Object other) =>
      identical(this, other
                ) ||
      other is Task && runtimeType == other.runtimeType && function == other.function &&
      bundle == other.bundle;

  @override
  int get hashCode => function.hashCode ^ bundle.hashCode;
}

class Result<O> {
  final O data;
  final error;
  Result({this.data, this.error});
}

class _Worker {
  Isolate _isolate;
  final _receivePort = ReceivePort();
  SendPort _sendPort;

  bool isBusy = false;
  int taskCode = 0;

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
