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
  Cancelable<O> catchError(Function onError, {bool Function(Object error) test}) => this.._future.catchError(onError);

  @override
  Cancelable<R> then<R>(FutureOr<R> onValue(O value), {Function onError}) {
    final resultCompleter = Completer<R>();
    _future.then((value) {
      try {
        resultCompleter.complete(onValue(value));
      } catch (e) {
        resultCompleter.completeError(e);
      }
    }, onError: (e) {
      onError?.call(e);
      resultCompleter.completeError(e);
    });
    return Cancelable(resultCompleter, onCancel);
  }

  @override
  Future<O> timeout(Duration timeLimit, {FutureOr Function() onTimeout}) => _future.timeout(timeLimit);

  @override
  Future<O> whenComplete(FutureOr Function() action) => _future.whenComplete(action);
}
