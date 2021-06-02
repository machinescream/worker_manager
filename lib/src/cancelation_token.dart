import 'dart:collection';

import 'cancelable.dart';

class _ListenerEntry extends LinkedListEntry<_ListenerEntry> {
  _ListenerEntry(this.listener);
  final void Function() listener;
}

class CancelationTokenSource {
  final token = CancelationToken._();

  void cancel() {
    token._cancel();
  }
}

class CancelationToken {
  final LinkedList<_ListenerEntry> _listeners = LinkedList<_ListenerEntry>();

  CancelationToken._();

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
