// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:worker_manager/worker_manager.dart';

void main() async {
  workerManager.log = true;
  await workerManager.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: true,
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
                    for (var i = 0; i < 50; i++) {
                      compute(fibCompute, 43).then((value) {
                        setState(() {
                          computeResults.add(value);
                        });
                      });
                    }
                  },
                ),
                Spacer(),
                CupertinoButton(
                  child: Text('run executor'),
                  onPressed: () {
                    for (var i = 0; i < 5; i++) {
                      workerManager.execute(() => fib(43)).then((value) {
                        setState(() {
                          executorResults.add(value);
                        });
                      });
                    }
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

int fib(int n) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2) + fib(n - 1);
}

int fibCompute(int n) {
  if (n < 2) {
    return n;
  }
  return fibCompute(n - 2) + fibCompute(n - 1);
}
