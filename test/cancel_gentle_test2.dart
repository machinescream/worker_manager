import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void main() {
  test("https://github.com/machinescream/worker_manager/issues/105", () async {
    final task = workerManager.executeGentle((isCanceled) {
          print("work started");
          Future.delayed(Duration(seconds: 1));
          if(!isCanceled()){
            print("Finished grasefully");
          }else{
            throw Exception("somethign went wrong");
          }
        });
    //allowing task to be scheduled from queue, but not removed from queue
    await Future.delayed(Duration(milliseconds: 500));
    task.cancel();
  });
}
