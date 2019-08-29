import 'package:example/repo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:worker_manager/worker_manager.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  WorkerManager workerManager;

  @override
  void initState() {
    super.initState();
    Repository();
  }

  @override
  Widget build(BuildContext context) {
    workerManager = WorkerManager<int, int>(threadPoolSize: 4);
    return Scaffold(
      body: Center(
        child: Container(
          height: 350,
          width: 200,
          color: Colors.cyan,
          child: Column(
            children: <Widget>[
              RaisedButton(
                child: Text('fib(25)'),
                onPressed: () async {
                  workerManager.manageWork(function: fib, bundle: 25);
                },
              ),
              RaisedButton(
                child: Text('fib(40)'),
                onPressed: () {
                  workerManager.manageWork(
                      function: fib, bundle: 40, timeout: Duration(microseconds: 0));
                },
              ),
              RaisedButton(
                child: Text('end work'),
                onPressed: () {
                  workerManager.endWork();
                },
              ),
              StreamBuilder(
                stream: workerManager.resultStream,
                builder: (ctx, snap) => Text(snap.data.toString()),
              )
            ],
          ),
        ),
      ),
    );
  }
}

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}
