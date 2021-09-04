# Executor

![GitHub Logo](images/logo2.jpg)

## Warning
Current implementation for web support same as `compute` method from flutter foundation.
True multithreading for web is under construction,
if you have any experience in web development, please help!

## What this library do?
Executor is a library for running CPU intensive functions inside a separate dart isolate.
This is useful if you want to avoid skipping frames when the main isolate is rendering the UI.
Since isolates are able to run when the main thread created, make sure your functions
that are added to the Executor task queue are static or defined globally (just in a dart file,
not inside a class).

## Notice
Executor - is a `Singleton`, meaning there is only ever one instance of Executor.

## Usage
At first, you might warm up executor. It is not necessary since cold start feature added,
but I personally recommend you to call initialization flow before start `runApp` function.
Isolate instantiation can block main thread, consequently frame drops is possible.

```dart
Future<void> main() async {
 await Executor().warmUp();
 runApp(MyApp());
}
```

You can pass the arguments to warmUp method:
1) log: true/false to see the logs
2) isolatesCount if you want to control how many isolates will be instantiated at run time. (Can be useful on android)

The 2nd step: Call execute methods with args and function, Executor returns the Cancelable.
```dart
//Function defined globally or static in some class
int fib(int n) {
 if (n < 2) {
  return n;
 }
 return fib(n - 2) + fib(n - 1);
}

void perform(){
  final task = Executor().execute(arg1: 41, fun1: fib);
  //task can be canceled if you need it, for example in dispose method in widget, block, presenter to stop parsing or
  //long calculation
  task.cancel();
}
```

## What is Cancelable?
- `Cancelable` - is a class implements Future. You can `await` `Cancelable` same as `Future` class.
- Calling `cancel` method trigger isolate to be killed. That means everything you wrote in passed function will stop 
  exact at time you called `cancel`.
- `Cancelable` can be chained same as `Future` by next method(`then` alternative).
- Static method `mergeAll` is alternative to `Future.wait`.

## Conclusion
Wish you beautiful and performant applications, this lib is open to pull request, please support!

