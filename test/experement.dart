import 'package:worker_manager/worker_manager.dart';

Future<void> main() async {
  await Executor().warmUp();
  final t1 = Executor().execute(
      arg1: 0,
      fun1: (arg, port) {
        port.onMessage = (message) {
          print(message);
        };
      });

  final port = t1.port;

  Executor().execute(
      arg1: 0,
      fun1: (arg, __) {
        port?.send("hi t1 from t2");
      });

  port?.send("hello");

  await Future.delayed(Duration(seconds: 2));
}
