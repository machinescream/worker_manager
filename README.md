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

2nd step: Call execute methods with args and function, Executor returns a CancelableOperation.

```dart
class Counter {
  int fib(int n) {
    if (n < 2) {
      return n;
    }
    return fib(n - 2) + fib(n - 1);
  }
  static int _fib(Counter counter, int arg) => counter.fib(arg);
}

Executor().execute(arg1: counter, arg2: 20, fun2: fun21).value.then((result) {
  handle result here
                  });
//or:
final result = await Executor().execute(arg1: counter, arg2: 20, fun2: fun21).value;
```

Bonus: you can stop isolate any time you want. Canceling a cancelableOperation will produce nothing
and will result in no data passed into the then callback.

```dart
  int fibonacci(int n) {
    if (n < 2) {
      return n;
    }
    return fib(n - 2) + fib(n - 1);
  }
final fibonacciOperation = Executor.execute(arg1: 88, Fun1: fibonacci).value.then((data){
        nothing here
    });
fibonacciOperation.cancel();
```

