import 'dart:async';

typedef OnCancel = void Function();

class CanceledError implements Exception {}

class Cancelable<O> implements Future<O> {
  Completer<O> _completer;
  OnCancel onCancel;

  Cancelable(this._completer, this.onCancel);

  Future<O> get _future => _completer.future;

  void cancel() {
    onCancel?.call();
    onCancel = null;
  }

  @override
  Stream<O> asStream() => _future.asStream();

  @override
  Future<O> catchError(Function onError, {bool Function(Object error) test}) => _future.catchError(onError, test: test);

  Cancelable<O> next(Function(O value) onValue) {
    final resultCompleter = Completer<O>();
    _completer.future.then((value) {
      try {
        onValue(value);
        resultCompleter.complete(value);
      } catch (error) {
        resultCompleter.completeError(error);
      }
    }, onError: (e) {
      resultCompleter.completeError(e);
    });
    return Cancelable(resultCompleter, cancel);
  }

  @override
  Future<O> timeout(Duration timeLimit, {FutureOr Function() onTimeout}) => _future.timeout(timeLimit);

  @override
  Future<O> whenComplete(FutureOr Function() action) => _future.whenComplete(action);


  @override
  Future<R> then<R>(FutureOr<R> Function(O value) onValue, {Function onError}) =>
      _future.then(onValue, onError: onError);
}
