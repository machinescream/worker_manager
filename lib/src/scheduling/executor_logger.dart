part of '../../worker_manager.dart';

class Mixinable<T> {
  late final itSelf = this as T;
}

mixin _ExecutorLogger on Mixinable<_Executor> {
  var log = false;

  @mustCallSuper
  void init() {
    logMessage(
      "${itSelf._isolatesCount} workers have been spawned and initialized",
    );
  }

  void logTaskAdded<R>(String uid) {
    logMessage("added task with number $uid");
  }

  @mustCallSuper
  void dispose() {
    logMessage("worker_manager have been disposed");
  }

  @mustCallSuper
  void _cancel(Task task) {
    logMessage("Task ${task.id} have been canceled");
  }

  void logMessage(String message) {
    if (log) print(message);
  }
}
