import 'dart:async';

import 'package:uuid/uuid.dart';

class Task<I, O> {
  final Function function;
  final I bundle;
  final Duration timeout;
  final completer = Completer<O>();
  String id;

  Task({this.function, this.bundle, this.timeout}) {
    this.id = Uuid().v4();
  }
}
