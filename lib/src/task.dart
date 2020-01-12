import 'dart:async';

import 'package:uuid/uuid.dart';

typedef FutureOr<O> TaskFunction<I extends Object, O extends Object>(I arg);

class Task<I extends Object, O extends Object> {
  final TaskFunction<I, O> function;
  final I arg;
  final Duration timeout;
  final completer = Completer<O>();
  String id = Uuid().v4();

  Task({this.function, this.arg, this.timeout});
}
