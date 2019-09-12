import 'dart:async';

class Task<I, O> {
  final Function function;
  final I bundle;
  final Duration timeout;
  final bool cash;
  final completer = Completer<O>();

  Task(
      {this.function, this.bundle, this.timeout, this.cash = false}
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          function == other.function &&
          bundle == other.bundle;

  @override
  int get hashCode => function.hashCode ^ bundle.hashCode;
}
