import 'dart:isolate';

class IsolateBundle {
  final SendPort port;
  final Function function;
  final Object bundle;
  final Duration timeout;

  IsolateBundle({this.port, this.function, this.bundle, this.timeout});
}
