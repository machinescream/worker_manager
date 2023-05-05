part of worker_manager;

final class CanceledError implements Exception {}

final class Cancelable<R> implements Future<R> {
  final Completer<R> _completer;
  final void Function()? _onCancel;
  final void Function()? _onPause;
  final void Function()? _onResume;

  Cancelable({
    required Completer<R> completer,
    void Function()? onCancel,
    void Function()? onPause,
    void Function()? onResume,
  })  : _completer = completer,
        _onCancel = onCancel,
        _onPause = onPause,
        _onResume = onResume;

  factory Cancelable.fromFuture(Future<R> future) {
    final completer = Completer<R>();
    future.then(
      (value) => completer.complete(value),
      onError: (Object e, StackTrace s) {
        _completeError(completer: completer, error: e, stackTrace: s);
      },
    );
    return Cancelable(
      completer: completer,
      onCancel: () {
        _completeError(completer: completer, error: CanceledError());
      },
    );
  }

  // factory Cancelable.justValue(R value) {
  //   return Cancelable(completer: Completer()..complete(value));
  // }
  //
  // factory Cancelable.justError(Object error) {
  //   return Cancelable(completer: Completer()..completeError(error));
  // }

  // TypeSendPort? get port => _task?.runnable.sendPort;

  Future<R> get future => _completer.future;

  static void _completeError<T>({
    required Completer<T> completer,
    required Object error,
    StackTrace? stackTrace,
    FutureOr<T> Function(Object error)? onError,
  }) {
    if (onError != null) {
      completer.complete(onError(error));
    } else {
      completer.completeError(error, stackTrace);
    }
  }

  void cancel() => _onCancel?.call();

  Cancelable<T> thenNext<T>(FutureOr<T> Function(R value)? onValue,
      [FutureOr<T> Function(Object error)? onError]) {
    final resultCompleter = Completer<T>();
    _completer.future.then((value) {
      try {
        resultCompleter.complete(onValue?.call(value));
      } catch (error) {
        _completeError(
          completer: resultCompleter,
          onError: onError,
          error: error,
        );
      }
    }, onError: (Object error) {
      _completeError(
        completer: resultCompleter,
        onError: onError,
        error: error,
      );
    });
    return Cancelable(
      completer: resultCompleter,
      onCancel: _onCancel,
      onPause: _onPause,
      onResume: _onResume,
    );
  }

  @experimental
  static Cancelable<Iterable<T>> mergeAll<T>(
    Iterable<Cancelable<T>> cancelables,
  ) {
    final resultCompleter = Completer<Iterable<T>>();
    Future.wait(cancelables).then((value) {
      resultCompleter.complete(value);
    }, onError: (Object error) {
      _completeError(
        completer: resultCompleter,
        error: error,
      );
    });
    return Cancelable(
      completer: resultCompleter,
      onCancel: () {
        for (final cancelable in cancelables) {
          cancelable.cancel();
        }
      },
      // onResume: () {
      //   for (final cancelable in cancelables) {
      //     cancelable.resume();
      //   }
      // },
      // onPause: () {
      //   for (final cancelable in cancelables) {
      //     cancelable.pause();
      //   }
      // },
    );
  }

  void pause() => _onPause?.call();

  void resume() => _onResume?.call();

  @override
  Stream<R> asStream() => future.asStream();

  @override
  Future<R> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) {
    return future.catchError(onError, test: test);
  }

  @override
  Future<R> timeout(
    Duration timeLimit, {
    FutureOr Function()? onTimeout,
  }) {
    return future.timeout(timeLimit);
  }

  @override
  Future<R> whenComplete(FutureOr Function() action) {
    return future.whenComplete(action);
  }

  @override
  Future<T> then<T>(
    FutureOr<T> Function(R value) onValue, {
    Function? onError,
  }) {
    return future.then(onValue, onError: onError);
  }
}
