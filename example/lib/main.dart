// Copyright Daniil Surnin. All rights reserved.
// Use of this source code is governed by a Apache license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:worker_manager/worker_manager.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      showPerformanceOverlay: false,
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
  final kek = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[
            RaisedButton(
                child: Text('fib(40)'),
                onPressed: () {
                  final task = Task(function: getData, bundle: '123');
                  Executor().addTask(task: task).listen((data) {
                    kek.add(data);
                  }).onError((error) {
                    print(error);
                  });
                }),
            RaisedButton(
                child: Text('cancel'),
                onPressed: () {
                  setState(() {});
                }),
            Text(kek.length.toString())
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

Future<String> getData(String link) async => (await get(link)).body.toString();
