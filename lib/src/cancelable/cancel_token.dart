import 'dart:async';
import 'dart:collection';
import 'cancelable.dart';

class _ListenerEntry extends LinkedListEntry<_ListenerEntry> {
  _ListenerEntry(this.listener);
  final void Function() listener;
}

class CancelTokenSource {
  final token = CancelToken._();

  void cancel() {
    token._cancel();
  }
}

class CancelToken {
  final LinkedList<_ListenerEntry> _listeners = LinkedList<_ListenerEntry>();

  CancelToken._();

  void addListener(void Function() listener) {
    throwIfCanceled();
    _listeners.add(_ListenerEntry(listener));
  }

  void removeListener(void Function() listener) {
    for (final _ListenerEntry entry in _listeners) {
      if (entry.listener == listener) {
        entry.unlink();
        return;
      }
    }
  }

  void throwIfCanceled() {
    if (canceled) throw CanceledError();
  }

  void dispose() {
    _listeners.clear();
  }

  bool _canceled = false;
  bool get canceled => _canceled;
  void _cancel() {
    throwIfCanceled();
    _canceled = true;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (_listeners.isEmpty) {
      return;
    }

    final List<_ListenerEntry> localListeners =
        List<_ListenerEntry>.from(_listeners);

    for (final _ListenerEntry entry in localListeners) {
      if (entry.list != null) {
        entry.listener();
      }
    }
  }
}

extension TokenExtensions<T> on Cancelable<T>{
  static Cancelable<T> cancelableFromFunction<T>(Future<T> Function(CancelToken token) fun) {
    final cancelTokenSource = CancelTokenSource();
    final completer = Completer<T>();
    final future = fun(cancelTokenSource.token);
    future.then((value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }).onError((error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error!, stackTrace);
      }
    });
    return Cancelable<T>(
      completer,
          () {
        if (!cancelTokenSource.token.canceled) {
          cancelTokenSource.cancel();
        }
        if (!completer.isCompleted) {
          completer.completeError(CanceledError());
        }
      },
    );
  }

  Cancelable<T> withToken(CancelToken token) {
    if (token.canceled) {
      cancel();
    } else {
      token.addListener(cancel);
    }
    return this;
  }
}
