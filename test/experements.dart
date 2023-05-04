import 'dart:async';
import 'dart:isolate';

class T<R> {

}

(int a, int b) complete(T t, int num){
  return (1, 2);
}

Future<void> main() async{
  final t = T();
  final result = await Isolate.run(() => complete(t, 7));
  print(result);
}


// import 'package:worker_manager/worker_manager.dart';
//
// Future<void> main() async {
//   await Executor().warmUp();
//   final t1 = Executor().execute(
//     arg1: 0,
//     fun1: (arg, port) {
//       port.send("notification");
//       port.onMessage = (message) {
//         print(message);
//       };
//     },
//     notification: (_) {
//       print(_);
//     },
//   );
//
//   final port = t1.port;
//
//   Executor().execute(
//       arg1: 0,
//       fun1: (arg, __) {
//         port?.send("hi t1 from t2");
//       });
//
//   port?.send("hello");
//
//   await Future.delayed(Duration(seconds: 2));
// }
