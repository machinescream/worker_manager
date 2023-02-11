# Executor

![GitHub Logo](images/logo.jpg)

## Some news
Probably, scheduler will be removed from worker_manger after few tests because it seems unnecessary
to schedule isolates while dartVM handle it by native scheduler

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
int fib(int n, TypeSendPort port) {
  if (n < 2) {
    return n;
  }
  return fib(n - 2, port) + fib(n - 1, port);
}

void perform() {
  final task = Executor().execute(arg1: 41, fun1: fib);
  //task can be canceled if you need it, for example in dispose method in widget, block, presenter to stop parsing or
  //long calculation
  task.cancel();
}
```

**NOTE:** Since `4.4.0`, all functions passed to `execute` method should have the required parameter `TypeSendPort` which allows the function to send messages to the `notification` callback in `execute` method.

Unfortunately, type check for `notification` parameter is weak cause Dart doesn't support invariant types yet. Carefully send message and don't forget what you expect to receive.

## What is Cancelable?
- `Cancelable` - is a class implements Future. You can `await` `Cancelable` same as `Future` class.
- Calling `cancel` method trigger isolate to be killed. That means everything you wrote in passed function will stop 
  exact at time you called `cancel`.
- `Cancelable` can be chained same as `Future` by next method(`then` alternative).
- Static method `mergeAll` is alternative to `Future.wait`.
- 'pause' - pausing isolate
- 'resume' - resuming isolate

## Pausing and resuming isolate
From `4.3.0` version of this library you can pause and resume pool of isolates by call
`Executor().pausePool()` and `Executor().resumePool()`, also you can pause and resume `Cancelable`
by using `resume()` and `pause()` API.

## Sending messages between isolates
Since `5.0.0` you can listen messages from other tasks by using required parameter `SendPort` and addidng callback
`onMessage` to the port. To send messages from main isolate or others isolate, make sure that executor runs your task then
use method `send` from `.port` from you `Cancelable`. Example: `myCanclelable.port.send("hello")`. This feature could be a little bit unstable, please use it if you sure that `Executor` runs your task.

## Sending messages from isolate to main isolate
Since `4.4.0` you can send messages from your function by using required parameter `SendPort` and
handle the message in notification callback from `execute` method. Unfortunately, type check for 
notification parameter is weak cause `Dart` doesn't support invariant types yet. Carefully send 
message and don't forget what you expect to receive.

## Conclusion
Wish you beautiful and performant applications, this lib is open to pull request, please support!

