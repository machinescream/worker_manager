// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.
library worker_manager;

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

enum WorkPriority { high, low }

const _checkDelay = 100;

class WorkerManager<O, I> {
  final int threadPoolSize;
  final workers = <Worker<O>>[];
  final _resultBroadcaster = StreamController<O>.broadcast();

  WorkerManager({this.threadPoolSize = 2});

  Stream<O> get resultStream => _resultBroadcaster.stream;

  ///cashed results, override hashcode and equals operator !!!
  Map<int, O> cash = {};

  final queue = Queue<QueueMember<I>>();
  Timer timer;

  void manageWork({@required Function function, I bundle, WorkPriority priority = WorkPriority
      .high, bool cashResult = false}) async {
    final cashKey = runtimeType.hashCode ^ bundle.hashCode;
    if (cash.containsKey(cashKey)) {
      _resultBroadcaster.add(cash[cashKey]);
      return;
    }

    void sendResult(O result) {
      if (cashResult) cash.putIfAbsent(cashKey, () => result);
      _resultBroadcaster.add(result);
    }

    if (timer == null) {
      timer = Timer.periodic(Duration(milliseconds: _checkDelay), (time) {
        if (queue.isNotEmpty) {
          final freeWorkers = workers.where((worker) => !worker.isBusy);
          if (freeWorkers.isNotEmpty) {
            final queueBundle = queue.removeFirst();
            freeWorkers.first.work(function: queueBundle.function, bundle: queueBundle.bundle
                                   ).then(sendResult
                                          );
          }
        }
      });
    }

    final busyWorkers = workers.where((worker) => worker.isBusy);
    if (workers.length < threadPoolSize) {
      final worker = Worker<O>();
      await worker.initPortConnection();
      worker.work(function: function, bundle: bundle
                  ).then(sendResult
                         );
      workers.add(worker);
    } else if (busyWorkers.length == threadPoolSize) {
      final queueBundle = QueueMember(function: function, bundle: bundle
                                      );
      priority == WorkPriority.high ? queue.addFirst(queueBundle) : queue.addLast(queueBundle);
    } else {
      workers.firstWhere((worker) => !worker.isBusy
                         ).work(function: function, bundle: bundle
                                ).then(sendResult
                                       );
    }
  }

  void endWork() {
    timer.cancel();
    _resultBroadcaster.close();
    workers.forEach((worker) {
      worker.kill();
    });
    workers.clear();
    cash.clear();
    queue.clear();
  }
}

class QueueMember<I> {
  final Function function;
  final I bundle;
  QueueMember({this.function, this.bundle});
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

  Future<O> work<I>({@required Function function, I bundle}) async {
    isBusy = true;
    final receivePort = ReceivePort();
    _sendPort.send(_IsolateBundle(port: receivePort.sendPort, function: function, bundle: bundle));
    final O result = await receivePort.first;
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
    sendPort.send(await function(bundle));
  }
}

class _IsolateBundle<I> {
  final SendPort port;
  final Function function;
  final I bundle;
  _IsolateBundle({this.port, this.function, this.bundle});
}
