// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.

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
      // Performance overlay throws unimplemented for Flutter Web
      // showPerformanceOverlay: true,
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final computeResults = [];
  final executorResults = [];
  var computeTaskRun = 0;
  var executorTaskRun = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Fibonacci calculation of 43 "),
            const CircularProgressIndicator(),
            Row(
              children: [
                Text(computeTaskRun.toString()),
                Spacer(),
                Text(executorTaskRun.toString()),
              ],
            ),
            const SizedBox(
              height: 200,
            ),
            Text('Results'),
            Row(
              children: [
                Text(computeResults.length.toString()),
                Spacer(),
                Text(executorResults.length.toString()),
              ],
            ),
            Row(
              children: [
                CupertinoButton(
                  child: Text('run compute'),
                  onPressed: () {
                    setState(() {
                      computeTaskRun++;
                      compute(fibCompute, 43).then((value) {
                        setState(() {
                          computeResults.add(value);
                        });
                      });
                    });
                  },
                ),
                Spacer(),
                CupertinoButton(
                  child: Text('run executor'),
                  onPressed: () {
                    setState(() {
                      executorTaskRun++;
                      Executor().execute(arg1: 43, fun1: fib).then((value) {
                        setState(() {
                          executorResults.add(value);
                        });
                      });
                    });
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}

int fib(int n, TypeSendPort port) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2, port) + fib(n - 1, port);
}

int fibCompute(int n) {
  if (n < 2) {
    return n;
  }
  return fibCompute(n - 2) + fibCompute(n - 1);
}
