import 'dart:async';
import 'runnable.dart';

enum WorkPriority {
  immediately,
  veryHigh,
  high,
  highRegular,
  regular,
  almostLow,
  low
}

class Task<A, B, C, D, O, T> implements Comparable<Task<A, B, C, D, O, T>> {
  final Runnable<A, B, C, D, O, T> runnable;
  final resultCompleter = Completer<O>();
  final int number;
  final WorkPriority workPriority;
  final Function? onUpdateProgress;

  Task({
    required this.number,
    required this.runnable,
    this.workPriority = WorkPriority.high,
    this.onUpdateProgress,
  });

  @override
  int compareTo(Task other) {
    final index = WorkPriority.values.indexOf;
    return index(workPriority) - index(other.workPriority);
  }

  @override
  bool operator ==(covariant Task other) {
    return other.number == number;
  }

  @override
  int get hashCode => number;
}
