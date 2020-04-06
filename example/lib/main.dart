// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:worker_manager/executor.dart';

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
  final counter = Counter();

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
                  Executor().execute(arg1: counter, arg2: 20, fun2: fun21).then((result) {
                    setState(() {
                      results.add(result);
                    });
                  }, onError: (e, __) {
                    print(e);
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

  static int _fib(Counter counter, int arg) => counter.fib(arg);
}

Future<int> fun21(Counter counter, int arg) async => counter.fib(arg);
