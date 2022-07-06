import 'package:worker_manager/worker_manager.dart';

export 'send_port_io.dart' if (dart.library.html) 'send_port_web.dart';

class TypeSendPort<T> {
  final SendPort sendPort;

  void send(T value) => sendPort.send(value);

  TypeSendPort(this.sendPort);
}
