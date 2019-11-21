# Executor

![GitHub Logo](images/logo2.jpg)

Executor is a library for running CPU intensive functions inside a separate dart isolate. This is useful if you want to avoid skipping frames when the main isolate is rendering the UI. Since isolates are able to run when the main thread is created, make sure that your functions that are added to the Executor task queue are static or defined globally (just in a dart file, not inside a class).

## Notice

- Executor - is a `Singleton`, meaning there is only ever one instance of Executor.

## Usage

1st step: Initialize Executor with the number of isolates you need (this is not necessary, but recommended). Write this
 code inside
 main function
(make sure that you main is async):

```dart
 await Executor(isolatePoolSize: 2).warmUp();
```

2nd step: Create a Task with the function you wish to run in the isolate.

```dart
final task = Task<return type>(
  function: yourFunction,
  bundle: one parameter for your function, it can be empty,
  timeout: Duration( time for calculation ) - optional parameter
);
```

3rd step: Call Executor.addTask(your task). Executor returns a Stream.

```dart
Executor().addTask<parameter type, return type>(
    task: Task(
        function: yourFunction,
        bundle: parameter, timeout:
        Duration(seconds: 25),
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
Executor().removeTask(task: task);
```

Optional: Stop all current tasks in the Executor().

```dart
Executor().stop();
```
