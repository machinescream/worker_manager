
import 'package:worker_manager/src/port/send_port.dart';

class ArgumentsSendPort<A> {
  final SendPort? sendPort;
  final A argument;

  ArgumentsSendPort(this.argument, {this.sendPort});

  ArgumentsSendPort copyWith({A? argument, SendPort? sendPort}) {
    return ArgumentsSendPort(
      argument ?? this.argument,
      sendPort: sendPort ?? this.sendPort
    );
  }
}