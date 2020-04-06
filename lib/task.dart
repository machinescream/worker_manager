import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:worker_manager/runnable.dart';

enum WorkPriority { high, low, regular }

class Task<A, B, C, D, O> {
  final Runnable<A, B, C, D, O> runnable;
  final Duration timeout;
  final completer = Completer<O>();
  final id = Uuid().v4();

  Task({this.runnable, this.timeout});
}
