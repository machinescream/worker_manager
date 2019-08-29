// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.
library worker_manager;

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

enum WorkPriority { high, low }

class WorkerManager<I, O> {
  /// TODO (Daniil) : add policy( fifo etc...)
  /// for a while  fifo is setting threadPoolSize as 1
  final int threadPoolSize;
  final workers = <Worker<O>>[];
  final _resultBroadcaster = StreamController<O>.broadcast();

  WorkerManager({this.threadPoolSize = 1});

  Stream<O> get resultStream => _resultBroadcaster.stream;

  ///cashed results, override hashcode and equals operator !!!
  // Map<int, O> cash = {};

  final _queue = Queue<QueueMember<I>>();

  void _sendResult(
    Result result,
    //                    bool cashResult,
    //                    int cashKey
  ) {
    /// TODO: is it necessary?
    //  if (cashResult) cash.putIfAbsent(cashKey, () => result);
    final error = result.error;
    final data = result.data as O;
    result.error != null ? _resultBroadcaster.addError(error) : _resultBroadcaster.add(data);
  }

  void _manageQueue() {
    if (_queue.isNotEmpty) {
      final queueMember = _queue.removeFirst();
      manageWork(function: queueMember.function, bundle: queueMember.bundle);
    }
  }

  void manageWork(
      {@required Function function,
      I bundle,
      WorkPriority priority = WorkPriority.high,
      Duration timeout,
      bool cashResult = false}) async {
//    final cashKey = runtimeType.hashCode ^ bundle.hashCode;
//    if (cash.containsKey(cashKey)) {
//      _resultBroadcaster.add(cash[cashKey]);
//      return;
//    }

    final busyWorkers = workers.where((worker) => worker.isBusy);
    if (workers.length < threadPoolSize) {
      final worker = Worker<O>();
      await worker.initPortConnection();
      worker.work(function: function, bundle: bundle, timeout: timeout).then((Result result) {
        _sendResult(result);
        _manageQueue();
      });
      workers.add(worker);
    } else if (busyWorkers.length == threadPoolSize) {
      final queueBundle = QueueMember(function: function, bundle: bundle);
      priority == WorkPriority.high ? _queue.addFirst(queueBundle) : _queue.addLast(queueBundle);
    } else {
      workers
          .firstWhere((worker) => !worker.isBusy)
          .work(function: function, bundle: bundle, timeout: timeout)
          .then((Result result) {
        _sendResult(result);
        _manageQueue();
      });
    }
  }

  void cleanUp() {
    workers.forEach((worker) {
      worker.kill();
    });
    workers.clear();
    //   cash.clear();
    _queue.clear();
  }

  void endWork() {
    _resultBroadcaster.close();
    cleanUp();
  }
}

class QueueMember<I> {
  final Function function;
  final I bundle;
  QueueMember({this.function, this.bundle});
}

class Result {
  final data;
  final error;
  Result({this.data, this.error});
}

class Worker<O> {
  Isolate _isolate;
  final _receivePort = ReceivePort();
  SendPort _sendPort;

  bool isBusy = false;

  Future<void> initPortConnection() async {
    _isolate = await Isolate.spawn(_handleWithPorts, _IsolateBundle(port: _receivePort.sendPort));
    _sendPort = await _receivePort.first;
  }

  Future<Result> work<I>({@required Function function, I bundle, Duration timeout}) async {
    isBusy = true;
    final receivePort = ReceivePort();
    _sendPort.send(_IsolateBundle(
        port: receivePort.sendPort, function: function, bundle: bundle, timeout: timeout));
    final Result result = await receivePort.first;
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

void _handleWithPorts<I>(_IsolateBundle isolateBundle) async {
  final receivePort = ReceivePort();
  isolateBundle.port.send(receivePort.sendPort);
  await for (_IsolateBundle<I> isolateBundle in receivePort) {
    final function = isolateBundle.function;
    final bundle = isolateBundle.bundle;
    final sendPort = isolateBundle.port;
    final timeout = isolateBundle.timeout;
    Result result;
    execute() => bundle == null ? function() : function(bundle);
    try {
      if (timeout == null) {
        result = Result(data: await execute());
      } else {
        result = await Future.microtask(() async {
          final data = await execute();
          return Result(data: data);
        }).timeout(timeout, onTimeout: () {
          throw TimeoutException;
        });
      }
    } catch (error) {
      result = Result(error: error);
    }
    sendPort.send(result);
  }
}

class _IsolateBundle<I> {
  final SendPort port;
  final Function function;
  final I bundle;
  final Duration timeout;
  _IsolateBundle({this.port, this.function, this.bundle, this.timeout});
}
