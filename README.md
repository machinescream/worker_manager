Executor is instrument to run any functions inside separate dart isolate.
This is useful if you want to avoid lags and freezes in UI isolate(main).
If you parse big json data or calculating math it can make your app laggy.
To solve this problem, make sure that you functions, which working with Executor is static
or defined as global (just in a dart file, not inside a class).

First step: Executor - is a Singleton, you can call Executor everywhere you want, it will not produce
any instance except first one.

Second step: You MUST set isolatePool size for Executor and warm up isolates. Write this code inside main function
 (make sure that you main is async):

```
 await Executor(threadPoolSize: 2).warmUp();
```
Third step: To run code inside isolate you should create a Task
```
final task = Task<return type>(function: yourFunction,
 bundle: one parameter for your function, it can be empty
 timeout: Duration( time for calculation) - optional parameter
);
```
Fourth step: Call Executor.addTask(you task). it will return Stream with result.
Here is example:
```
Executor().addTask<parameter type, return type>(
    task: Task(function: yourFunction, bundle: parameter,
     timeout: Duration(seconds: 25))).listen((data) {
                handle with you result
              }).onError((error) {
                handle error
              });
```
Bonus: you can stop task every time you want. Removing task will produce nothing
 and you will not get any data inside listen method.
```
final task1 = Task(function: fibonacci, bundle: 88);
Executor.addTask(task: task1).listen((data){
        nothing here
    });
Executor().removeTask(task: task1);
```
Optional: you can end work with Executor().
```
Executor().stop();
```

