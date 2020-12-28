import 'dart:async';

typedef OnCancel = void Function();
typedef OnNext<T> = void Function(T value);

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

  static Cancelable<List<R>> mergeAll<R>(List<Cancelable<R>> cancelables) {
    final resultCompleter = Completer<List<R>>();
    Future.wait(cancelables).then((value) {
      resultCompleter.complete(value);
    }, onError: (e) {
      if (!resultCompleter.isCompleted) {
        resultCompleter.completeError(e);
      }
    });
    return Cancelable(resultCompleter, () {
      for (final cancelable in cancelables) {
        cancelable.cancel();
      }
      if (!resultCompleter.isCompleted) {
        resultCompleter.completeError(CanceledError());
      }
    });
  }

  @override
  Stream<O> asStream() => _future.asStream();

  @override
  Future<O> catchError(Function onError, {bool Function(Object error) test}) =>
      _future.catchError(onError, test: test);

  void _completeError<T>({Completer<T> completer, Function onError, Object e}) {
    if (!completer.isCompleted) {
      if (onError != null) {
        onError(e);
        completer.complete();
        return;
      }
      completer.completeError(e);
    }
  }

  void _completeValue<T>({Completer<T> completer, T value}) {
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  Cancelable<R> next<R>(
      {FutureOr<R> Function(O value) onValue,
      Function onError,
      OnNext<O> onNext}) {
    final resultCompleter = Completer<R>();
    _completer.future.then((value) {
      try {
        if (value != null && onValue != null) {
          _completeValue(completer: resultCompleter, value: onValue(value));
        } else {
          onNext?.call(value);
          _completeValue(completer: resultCompleter);
        }
      } catch (error) {
        _completeError(completer: resultCompleter, onError: onError, e: error);
      }
    }, onError: (e) {
      _completeError(completer: resultCompleter, onError: onError, e: e);
    });
    return Cancelable(resultCompleter, () {
      cancel();
      _completeError(
          completer: resultCompleter, e: CanceledError(), onError: onError);
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
