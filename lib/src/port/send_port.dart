import 'dart:isolate';

export 'send_port_io.dart' if (dart.library.html) 'send_port_web.dart';

class TypeSendPort<T> implements Capability {
  final SendPort? _sendPort;
  TypeSendPort({
    SendPort? sendPort,
  }) : _sendPort = sendPort;

  final _pendingMessages = [];

  void firePendingMessages(){
    for (final message in _pendingMessages) {
      send(message);
    }
    _pendingMessages.clear();
  }

  void send(T message){
    final sendPort = _sendPort;
    if(sendPort != null){
      sendPort.send(message);
      return;
    }
    _pendingMessages.add(message);
  }

  late final Function(dynamic message) onMessage;
}
