import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:worker_manager/worker_manager.dart';

void main() async {
  await WorkerManager().initManager();
  runApp(MyApp()
         );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(showPerformanceOverlay: true, home: MyHomePage(),
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
  DateTime time;

  @override
  Widget build(BuildContext context) {
    final task = Task(function: fib, bundle: 40
                      );
    return Scaffold(body: Center(child: Container(height: 350,
                                                    width: 200,
                                                    color: Colors.cyan,
                                                    child: Column(children: <Widget>[
                                                      RaisedButton(child: Text('fib(40)'
                                                                               ),
                                                                     onPressed: () async {
                                                                       if (time == null)
                                                                         time = DateTime.now();
                                                                       workerManager.manageWork(
                                                                           task: task
                                                                           ).listen((sr) {
                                                                         setState(() {
                                                                           results.add(sr
                                                                                       );
                                                                         }
                                                                                  );
                                                                         if (results.length == 3) {
                                                                           print(DateTime.now()
                                                                                     .difference(
                                                                               time
                                                                               )
                                                                                 );
                                                                         }
                                                                       }
                                                                                    ).onError((
                                                                                                  error) {}
                                                                                              );
                                                                       setState(() {
                                                                         clicks++;
                                                                       }
                                                                                );
                                                                     },
                                                                   ),
                                                      RaisedButton(child: Text('kill'
                                                                               ), onPressed: () {
                                                        workerManager.killTask(task: task
                                                                               );
                                                      },
                                                                   ),
                                                      Row(children: <Widget>[
                                                        Text(clicks.toString()
                                                             ),
                                                        CircularProgressIndicator(),
                                                        Text(results.length.toString()
                                                             )
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

Future<String> getData(String kek) async =>
    (await get(kek
               )).body.toString();
