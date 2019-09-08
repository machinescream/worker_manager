# worker_manager

wrapper an isolate

## Getting Started

WorkerManager is Singleton. Just create link everywhere you want
```
class _MyHomePageState extends State<MyHomePage> {
  WorkerManager workerManager = WorkerManager();
```
Creating task for workerManager with global function and Bundle class for your function.
    bundle and timeout is optional parameters.

```
  final task = Task(function: fib, bundle: 40, timeout: Duration(days: 78));
```
Remember, that you global function must have only one parameter, like int, String or your
    bundle class .
    For example:
```
    Class Bundle {
      final int age;
      final String name;
      Bundle(this.age, this.name);
    }
```
optional parameters is ok, just be ready to avoid NPE
    
ManageWork function working with your task and returning stream which
                  return result of your global function in listen callback.
                   Also you can handle errors in onError callback
```
workerManager.manageWork(task: task).listen((data) {
  print(data);
}).onError((error) {
  print(error);
});
```
You can specify types to avoid dynamic types
First - input type, Second - output
```
workerManager.manageWork<ClassBundle, String>
```

Killing task, stream will return nothing
```
workerManager.killTask(task: task);
```
Good case when you want to end your hard calculations in dispose method
```
  @override
  void dispose() {
    workerManager.killTask(task: task);
    super.dispose();
  }
```
   This is not necessary, this code will run
   before your awesome widgets build,
   to avoid micro freezes.
   if you don't want to spawn free of calculation isolates,
   don't write this code :
```
void main() async {
  await WorkerManager().initManager();
  runApp(MyApp());
}
```
