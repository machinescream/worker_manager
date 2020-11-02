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

  void _completeWithError(Completer completer, dynamic e) {
    if (!completer.isCompleted) {
      completer.completeError(e);
    }
  }

  void _justComplete(Completer completer) {
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  Cancelable<R> next<R>(FutureOr<R> Function(O value) onValue,
      {Function onError}) {
    final resultCompleter = Completer<R>();
    _completer.future.then((value) {
      try {
        resultCompleter.complete(onValue(value));
      } catch (error) {
        _completeWithError(resultCompleter, error);
      }
    }, onError: (error) {
      if (onError == null) {
        _completeWithError(resultCompleter, error);
      } else {
        onError(error);
        _justComplete(resultCompleter);
      }
    });
    return Cancelable(resultCompleter, () {
      cancel();
      final c = CanceledError();
      if (onError == null) {
        _completeWithError(resultCompleter, c);
      } else {
        onError(c);
        _justComplete(resultCompleter);
      }
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
