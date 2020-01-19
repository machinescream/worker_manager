// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/runnable.dart';
import 'package:worker_manager/task.dart';

void main() async {
  await Executor().warmUp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
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
  final results = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RaisedButton(child: Text('fib(40) compute isolate'), onPressed: () {}),
            RaisedButton(
                child: Text('fib(40) isolated'),
                onPressed: () {
                  final counter = Counter();
                  final task = Task2(runnable: Runnable(arg1: counter, arg2: 50, fun2: fun21));
                  Executor().addTask(task: task).listen((result) {
                    setState(() {
                      results.add(result);
                    });
                  }).onError((error) {
                    print(error);
                  });
                }),
            CircularProgressIndicator(),
            Text(results.length.toString())
          ],
        ),
      ),
    );
  }
}

class Counter {
  int fib(int n) {
    if (n < 2) {
      return n;
    }
    return fib(n - 2) + fib(n - 1);
  }
}

Future<int> fun21(Counter counter, int arg) async => counter.fib(arg);
