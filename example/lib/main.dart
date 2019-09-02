import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
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
  WorkerManager workerManager = WorkerManager();
  int clicks = 0;
  List results = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          height: 350,
          width: 200,
          color: Colors.cyan,
          child: Column(
            children: <Widget>[
              RaisedButton(
                child: Text('fib(40)'), onPressed: () async {
                workerManager.manageWork(
                    function: fib, bundle: 10, timeout: Duration(milliseconds: 200
                                                                 )
                    ).listen((sr) {
                  print(sr
                        );
                }
                             ).onError((error) {
                  print(error
                        );
                }
                                       );
                setState(() {
                  clicks++;
                }
                         );
                },
              ), Row(children: <Widget>[Text(clicks.toString()
                                             ), CircularProgressIndicator(),
              ],
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

Future<String> getData() async =>
    (await get('https://www.googl.com'
               )).body.toString();
