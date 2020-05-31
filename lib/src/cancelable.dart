import 'dart:async';

typedef OnCancel = void Function();

class CanceledError implements Exception {}

class Cancelable<O> implements Future {
  final Completer<O> _completer;
  final OnCancel onCancel;

  Cancelable(this._completer, this.onCancel);

  void cancel() {
    onCancel();
    if (!_completer.isCompleted) _completer.completeError(CanceledError());
  }

  Cancelable<O> next(Function(O value) onValue) {
    final resultCompleter = Completer<O>();
    _completer.future.then((value) {
      onValue(value);
      resultCompleter.complete(value);
    }, onError: (e) {
      resultCompleter.completeError(e);
    });
    return Cancelable(resultCompleter, cancel);
  }

  @override
  Stream asStream() => _completer.future.asStream();

  @override
  Future catchError(Function onError, {bool Function(Object error) test}) =>
      _completer.future.catchError(onError, test: test);

  @override
  Future<R> then<R>(Function(O value) onValue, {Function onError}) => _completer.future.then(onValue, onError: onError);

  @override
  Future timeout(Duration timeLimit, {FutureOr Function() onTimeout}) => _completer.future.timeout(timeLimit);

  @override
  Future whenComplete(FutureOr Function() action) => _completer.future.whenComplete(action);
}
