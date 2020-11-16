# Executor

![GitHub Logo](images/logo2.jpg)

Executor is a library for running CPU intensive functions inside a separate dart isolate.
This is useful if you want to avoid skipping frames when the main isolate is rendering the UI.
Since isolates are able to run when the main thread created, make sure your functions
that are added to the Executor task queue are static or defined globally (just in a dart file, not
inside a class).

## Notice

- Executor - is a `Singleton`, meaning there is only ever one instance of Executor.

## Usage

The 1st step: Initialize Executor (initialization flow based on available processors number).
Write this code inside main function (make sure your main is async):

```dart
void main() async{
 await Executor().warmUp();
 //Your code down below
}
```

The 2nd step: Call execute methods with args and function, Executor returns the Cancelable.

```dart
final someRepo = Repo();
final page = 2;

Future<List<Users>> fetchUsers(Repo someRepo, int page) => someRepo.fetch(page);
// or
class SomeClass{
  final Repo someRepo;
  int page = 174;
  static Future<List<Users>> fetchUsers(Repo someRepo, int page) => someRepo.fetch(page);
}

Executor().execute(arg1: someRepo, arg2: page, fun2: fetchUsers).then((result) {
  //handle result here
});
//or:
final result = await Executor().execute(arg1: someRepo, arg2: page, fun2: fetchUsers);
```

## Notice

- Cancelable - is a class implements Future. If you are call cancel method, everything in runtime
inside your function will be stopped and Cancelable will throw CanceledError.
- Also, you can chain Cancelables by ```next``` method, and throw errors forward
- If you want to chain cancelables from origin to tail, you should use ```onValue``` callback.
 It means ```onValue``` should return something a sync value or a ```Future``` (means
  ```Cancelable``` could be returned).
- If you want just get a value and, you don't need to push a tail forward - use a onNext callback
 to handle that scenario.

```dart
  int fibonacci(int n) {
    if (n < 2) {
      return n;
    }
    return fib(n - 2) + fib(n - 1);
  }
final fibonacciOperation = Executor.execute(arg1: 88, Fun1: fibonacci).then((data){
        //nothing here
    }, onError(e){
        //cancelable error will be thrown
    });
final fibonacciOperation2 = Executor.execute(arg1: 88, Fun1: fibonacci).next(onValue: (data){
        return data * 5; // returning a new Cancelable that can cancel the origin Cancelable
    });
```

