import 'dart:async';
import 'package:worker_manager/src/runnable.dart';
import 'package:worker_manager/src/task.dart';

import '../../worker_manager.dart';

class IsolateWrapperImpl implements IsolateWrapper {
  @override
  num? runnableNumber;
  Completer? _result;

  @override
  Future<void> initialize() async => Future.value();

  @override
  Future<O> work<A, B, C, D, O>(Task<A, B, C, D, O> task) async {
    runnableNumber = task.number;
    _result = Completer<O>();
    if (!_result!.isCompleted) {
      _result?.complete(await _execute(task.runnable));
    }
    return _result!.future as Future<O>;
  }

  static FutureOr _execute(Runnable runnable) => runnable();

  @override
  Future<void> kill() async {
    _result = null;
  }
}
