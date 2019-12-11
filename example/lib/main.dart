// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:worker_manager/executor.dart';
import 'package:worker_manager/task.dart';

void main() async {
  await Executor(isolatePoolSize: 2).warmUp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: true,
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
            RaisedButton(
                child: Text('fib(40) main isolate'),
                onPressed: () {
                  setState(() {
                    final result = fib(40);
                    results.add(result);
                  });
                }),
            RaisedButton(
                child: Text('fib(40) isolated'),
                onPressed: () {
                  final task = Task(function: fib, arg: 40);
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

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}

void kek(_) {}
