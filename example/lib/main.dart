// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/cupertino.dart';
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
    return const MaterialApp(
      showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final results = [];
  int number = 0;
  Cancelable<void>? lastKnownOperation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(number.toString()),
            const CircularProgressIndicator(),
            Text(results.length.toString()),
            const SizedBox(
              height: 200,
            ),
            Builder(builder: (context) {
              return ElevatedButton(
                  child: const Text('fib(40) compute isolate'),
                  onPressed: () {
                    setState(() {
                      number++;
                      lastKnownOperation =
                          Executor().execute(arg1: 41, fun1: fib).next(onValue: (value) {
                        setState(() {
                          results.add(null);
                        });
                      }, onError: (e) {
                        final c = Scaffold.of(context).showBottomSheet((ctx) {
                          return Container(
                            padding: EdgeInsets.only(bottom: 100),
                            child: Text(
                              'task canceled',
                              style: TextStyle(fontSize: 30, color: Colors.white),
                            ),
                            color: Colors.green,
                          );
                        });
                        Future.delayed(Duration(seconds: 3), () {
                          c.close();
                        });
                      });
                    });
                  });
            }),
            ElevatedButton(
              child: const Text('cancel last'),
              onPressed: lastKnownOperation?.cancel,
            ),
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
