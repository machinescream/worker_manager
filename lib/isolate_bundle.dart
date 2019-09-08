import 'dart:isolate';

class IsolateBundle<I> {
  final SendPort port;
  final Function function;
  final I bundle;

  IsolateBundle({this.port, this.function, this.bundle});
}
