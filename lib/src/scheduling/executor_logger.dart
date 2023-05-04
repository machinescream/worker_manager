part of worker_manager;

class Mixinable<T> {
  late final itSelf = this as T;
}

mixin _ExecutorLogger on Mixinable<_Executor> {
  var log = false;

  String get _currentTaskId;

  @mustCallSuper
  void init({int? isolatesCount}) {
    logMessage(
      "${isolatesCount ?? numberOfProcessors} have been spawned and initialized",
    );
  }

  @mustCallSuper
  void execute<R>(FutureOr<R> Function() execution){
    logMessage("added task with number $_currentTaskId");
  }

  @mustCallSuper
  void dispose() {
    logMessage("worker_manager have been disposed");
  }

  void logMessage(String message) {
    if (log) print(message);
  }
}
