import 'dart:async';

import 'package:worker_manager/src/runnable.dart';

class Task<A, B, C, D, O> {
  final Runnable<A, B, C, D, O> runnable;
  final resultCompleter = Completer<O>();
  final int number;

  Task(this.number, {this.runnable});
}
