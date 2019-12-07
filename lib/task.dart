import 'dart:async';

import 'package:uuid/uuid.dart';

typedef O TaskCalculation<I, O>(I bundle);

class Task<I extends Object, O extends Object> {
  final TaskCalculation<I, O> function;
  final I bundle;
  final Duration timeout;
  final completer = Completer<O>();
  String id = Uuid().v4();

  Task({this.function, this.bundle, this.timeout});
}
