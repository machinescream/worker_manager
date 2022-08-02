library worker_manager;

export 'src/scheduling/task.dart' show WorkPriority;
export 'src/port/send_port.dart';

import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:worker_manager/src/port/send_port.dart';
import 'package:worker_manager/src/scheduling/runnable.dart';
import 'package:worker_manager/src/number_of_processors/processors_web.dart'
    if (dart.library.io) 'package:worker_manager/src/number_of_processors/processors_io.dart';
import 'package:worker_manager/src/scheduling/task.dart';
import 'src/worker/worker.dart';


part 'src/cancelable/cancelable.dart';
part 'src/scheduling/executor.dart';
part 'src/cancelable/cancel_token.dart';

