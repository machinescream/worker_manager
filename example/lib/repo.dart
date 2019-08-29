import 'dart:async';

import 'package:http/http.dart';
import 'package:worker_manager/worker_manager.dart';

class Repository {
  final workerManager = WorkerManager<String, String>();
  StreamSubscription subscription;
  Repository() {
    initRepository();
  }

  initRepository() {
    subscription = workerManager.resultStream.listen((data) {
      print('listen:$data');
    });
    subscription.onError((error) {
      print('error:$error');
    });
    getData();
  }
git 
  void getData() {
    workerManager.manageWork(function: getData2, timeout: Duration(microseconds: 0));
  }
}

getData2() async {
  return ((await get('https://dar.dev'))).body.toString();
}
