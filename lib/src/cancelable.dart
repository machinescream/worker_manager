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

  void _complete(Completer completer, {Object e}) {
    if (!completer.isCompleted) {
      if (e != null) {
        completer.completeError(e);
      } else {
        completer.complete();
      }
    }
  }

  void _completeWithError(Completer completer, Object e,
      {void Function(Object e) onError}) {
    if (onError == null) {
      _complete(completer, e: e);
    } else {
      onError(e);
      _complete(completer);
    }
  }

  Cancelable<R> next<R>(FutureOr<R> Function(O value) onValue,
      {Function onError}) {
    final resultCompleter = Completer<R>();
    _completer.future.then((value) {
      try {
        resultCompleter.complete(onValue(value));
      } catch (error) {
        _complete(resultCompleter, e: error);
      }
    }, onError: (e) {
      _complete(resultCompleter, e: e);
    });
    return Cancelable(resultCompleter, () {
      cancel();
      _complete(resultCompleter, e: CanceledError());
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
