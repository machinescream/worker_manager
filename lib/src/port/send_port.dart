import 'dart:isolate';

export 'send_port_io.dart' if (dart.library.html) 'send_port_web.dart';

class TypeSendPort<T> implements Capability {
  final SendPort? _sendPort;
  TypeSendPort({
    SendPort? sendPort,
  }) : _sendPort = sendPort;

  late final Function(dynamic message) onMessage;

  void send<M>(M message) => _sendPort?.send(message);
}
