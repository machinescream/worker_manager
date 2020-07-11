// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:worker_manager/worker_manager.dart';

void main() async {
  await Executor().warmUp(log: true);
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
  int number = 0;
  Cancelable<void> lastKnownOperation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(number.toString()),
            CircularProgressIndicator(),
            Text(results.length.toString()),
            SizedBox(
              height: 200,
            ),
            Builder(builder: (context) {
              return RaisedButton(
                  child: Text('fib(40) compute isolate'),
                  onPressed: () {
//                    setState(() {
//                      number++;
//                    });
                    test().catchError(print);

//                    lastKnownOperation = Executor().execute(arg1: 41, fun1: fib).then((value) {
//                      setState(() {
//                        results.add(null);
//                      });
//                    })..catchError((e) {
//                      Scaffold.of(context).showBottomSheet((context) => Container(
//                            child: Text(
//                              'canceled',
//                              style: TextStyle(fontSize: 30, color: Colors.white),
//                            ),
//                            color: Colors.green,
//                          ));
//                    });
                  });
            }),
            RaisedButton(
                child: Text('cancel last'),
                onPressed: () {
                  lastKnownOperation.cancel();
                }),
          ],
        ),
      ),
    );
  }
}

int fib(int n) {
//  throw -1;
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}

Future<void> test() async {
  await Executor().execute(arg1: 41, fun1: fib).next((value) => value);
}

Future<String> hello(String text) async =>
    await Future.delayed(Duration(milliseconds: 1000), () => text);
