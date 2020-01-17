# Executor

![GitHub Logo](images/logo2.jpg)

Executor is a library for running CPU intensive functions inside a separate dart isolate. This is useful if you want to avoid skipping frames when the main isolate is rendering the UI. Since isolates are able to run when the main thread is created, make sure that your functions that are added to the Executor task queue are static or defined globally (just in a dart file, not inside a class).

## Notice

- Executor - is a `Singleton`, meaning there is only ever one instance of Executor.

## Usage

1st step: Initialize Executor (this is not necessary, but recommended. Executor initialization flow based on available processors number ). Write this code inside main function (make sure that you main is async):

```dart
 await Executor().warmUp();
```

2nd step: Create a Task with the runnable you wish to run in the isolate.

```dart
final task = Task(runnable: Runnable(arg1: Counter(), arg2: 40, fun2: calculate));

class Counter {
  int fib(int n) {
    if (n < 2) {
      return n;
    }
    return fib(n - 2) + fib(n - 1);
  }
}
int calculate(Counter counter, int arg) => counter.fib(arg);

```

3rd step: Call Executor.addTask(your task). Executor returns a Stream.

```dart
Executor().addTask(
    task: Task(
        runnable:: yourRunnable:,
        timeout: Duration(seconds: 25),
      ),
    ).listen((data) {
        handle with you result
      }).onError((error) {
        handle error
      });
```

Bonus: you can stop a task any time you want. Removing a task will produce nothing
and will result in no data passed into the listen method.

```dart
final task = Task(function: fibonacci, bundle: 88);
Executor.addTask(task: task).listen((data){
        nothing here
    });
task.cancel();
```

