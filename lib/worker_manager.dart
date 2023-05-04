library worker_manager;

export 'src/scheduling/task.dart' show WorkPriority;
export 'src/port/send_port.dart';

import 'dart:async';
import 'dart:developer';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:worker_manager/src/port/send_port.dart';
import 'package:worker_manager/src/number_of_processors/processors_io.dart'
    if (dart.library.web) 'package:worker_manager/src/number_of_processors/processors_web.dart';
import 'package:worker_manager/src/scheduling/task.dart';
import 'package:worker_manager/src/scheduling/work_priority.dart';
import 'src/worker/worker.dart';

part 'src/cancelable/cancelable.dart';

part 'src/scheduling/executor.dart';
part 'src/scheduling/executor_logger.dart';
