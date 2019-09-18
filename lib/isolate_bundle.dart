import 'dart:isolate';

class IsolateBundle<I> {
  final SendPort port;
  final Function function;
  final I bundle;
  final Duration timeout;

  IsolateBundle({this.port, this.function, this.bundle, this.timeout});
}
