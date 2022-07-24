import 'dart:async';
import '../port/send_port.dart';
import '../worker/worker.dart';
import '../scheduling/runnable.dart';
import '../scheduling/task.dart';

class WorkerImpl implements Worker {
  int? _runnableNumber;

  @override
  int? get runnableNumber => _runnableNumber;
  Completer? _result;

  @override
  Future<void> initialize() async => Future.value();

  @override
  Future<O> work<A, B, C, D, O, T>(Task<A, B, C, D, O, T> task) async {
    _runnableNumber = task.number;

    // Dummy sendPort for web
    task.runnable.sendPort = TypeSendPort(null);

    _result = Completer<O>();
    if (!_result!.isCompleted) {
      try {
        var r = await _execute(task.runnable);
        _result?.complete(r);
      } catch (error, stacktrace) {
        _result?.completeError(error, stacktrace);
      } finally {
        _runnableNumber = null;
      }
    }
    return _result!.future as Future<O>;
  }

  static FutureOr _execute(Runnable runnable) => runnable();

  @override
  Future<void> kill() async {
    _result = null;
  }

  @override
  void pause() {}

  @override
  void resume() {}

  @override
  bool get paused => false;
}
