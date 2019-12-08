import 'dart:async';

import 'package:uuid/uuid.dart';

typedef TaskCalculation<I>(I bundle);

class Task<O extends Object> {
  final TaskCalculation<O> function;
  final O bundle;
  final Duration timeout;
  final completer = Completer<O>();
  String id = Uuid().v4();

  Task({this.function, this.bundle, this.timeout});
}
