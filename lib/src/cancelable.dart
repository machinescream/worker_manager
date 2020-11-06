import 'dart:async';

typedef OnCancel = void Function();

class CanceledError implements Exception {}

class Cancelable<O> implements Future<O> {
  final Completer<O> _completer;
  OnCancel _onCancel;

  Cancelable(this._completer, this._onCancel);

  Future<O> get _future => _completer.future;

  void cancel() {
    _onCancel?.call();
    _onCancel = null;
  }

  @override
  Stream<O> asStream() => _future.asStream();

  @override
  Future<O> catchError(Function onError, {bool Function(Object error) test}) =>
      _future.catchError(onError, test: test);

  void _completeError<T>(Completer<T> completer, Function onError, Object e) {
    if (!completer.isCompleted) {
      if (onError != null) {
        onError(e);
        completer.complete();
        return;
      }
      completer.completeError(e);
    }
  }

  void _completeValue<T>(Completer<T> completer, T value) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  Cancelable<R> next<R>(
      {FutureOr<R> Function(O value) onValue,
      Function onError,
      OnCancel onNext}) {
    final resultCompleter = Completer<R>();
    _completer.future.then((value) {
      try {
        if (value != null && onValue != null) {
          _completeValue(resultCompleter, onValue(value));
        } else {
          onNext?.call();
          _completeValue(resultCompleter, null);
        }
      } catch (error) {
        _completeError(resultCompleter, onError, error);
      }
    }, onError: (e) {
      _completeError(resultCompleter, onError, e);
    });
    return Cancelable(resultCompleter, () {
      cancel();
      _completeError(resultCompleter, onError, CanceledError());
    });
  }

  @override
  Future<O> timeout(Duration timeLimit, {FutureOr Function() onTimeout}) =>
      _future.timeout(timeLimit);

  @override
  Future<O> whenComplete(FutureOr Function() action) =>
      _future.whenComplete(action);

  @override
  Future<R> then<R>(FutureOr<R> Function(O value) onValue,
          {Function onError}) =>
      _future.then(onValue, onError: onError);
}
