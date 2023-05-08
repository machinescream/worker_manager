# Worker Manager

Worker Manager is a powerful and easy-to-use library that helps you efficiently manage CPU-intensive tasks in your Flutter applications. It offers several advantages over traditional async programming or the built-in compute method.

# Breaking changes
Since 6.0.0 you must pass any functions with desired arguments by a lambda expression, to not break any code, please consider to use older versions of worker_manager. Also, to call worker_manager you should call 
worker_manager global variable instead of Executor() constructor.
# Advantages

## Efficient Scheduling
This library schedules CPU-intensive functions to avoid skipping frames or freezes in your Flutter application. It ensures that your app runs smoothly, even when dealing with heavy computations.

## Reusable Isolates
Unlike the [compute](https://api.flutter.dev/flutter/foundation/compute-constant.html) method, which always creates a new Dart isolate, Worker Manager reuses existing isolates. This approach is more efficient and prevents overloading the CPU. When resources are not freed up, using the compute method may cause freezes and skipped frames.

## Cancelable Tasks
Worker Manager provides a cancellation functionality through the Cancelable class and its `cancel` method. This feature allows developers to free up resources when they are no longer needed, improving the app's performance and responsiveness.

## Inter-Isolate Communication
The library supports communication between isolates with the `executeWithPort` method. This feature enables sending progress messages or other updates between isolates, providing more control over your tasks.

# Usage

## Execute the task
```dart
Cancelable<ResultType> cancelable = workerManager.execute<ResultType>(
  () async {
    // Your CPU-intensive function here
  },
  priority: WorkPriority.immediately,
);
```
## Execute a Task with Inter-Isolate Communication
```dart
Cancelable<ResultType> cancelable = workerManager.executeWithPort<ResultType, MessageType>(
  (SendPort sendPort) async {
    // Your CPU-intensive function here
    // Use sendPort.send(message) to communicate with the main isolate
  },
  onMessage: (MessageType message) {
    // Handle the received message in the main isolate
  },
);
```

## Cancel a Task
```dart
cancelable.cancel();
```

## Dispose Worker Manager
```dart
await workerManager.dispose();
```

By using Worker Manager, you can enjoy the benefits of efficient task scheduling, reusable isolates, cancellable tasks, and inter-isolate communication. It provides a clear advantage over traditional async programming and the built-in compute method, ensuring that your Flutter applications remain performant and responsive even when handling CPU-intensive tasks.
