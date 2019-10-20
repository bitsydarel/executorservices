A library for Dart and Flutter developers.

[license](https://github.com/bitsydarel/executorservices/blob/master/LICENSE).

## Description
It allows you to execute code in isolates or any executor currently supported.

Support concurrent execution of tasks or functions.

Support cleanup of unused isolates.

Support caching of isolate that allow you to reuse them (like thread).

It's extendable.

## Usage

A simple usage example:

```dart
import "package:executorservices/executorservices.dart";
import "dart:math";

main() {
  final cachedExecutorService = ExecutorService.newUnboundExecutor();

  cachedExecutorService.submitAction(randomInt);

  cachedExecutorService.submit(SomeIntensiveTask());
}

int randomInt() {
  return Random.secure().nextInt(1000);
}

class SomeIntensiveTask extends Task<String> {
  @override
  FutureOr<String> execute() async {
    await Future.delayed(Duration(minutes: 5));
    return "Done executing intensive task";
  }
} 
```

By default you can't re-submit the same instance of a Task subclass to a ExecutorService multiple times.
Because the result of your submitted task is associated with the task instance identifier.
So by default submitting the same instance of a task multiple times will result in unexpected behaviors.

For example, this won't work:

```dart
main() {
  final executors = ExecutorService.newUnboundExecutor();
  
  final task = SameInstanceTask();

  executors.submit(task);
  executors.submit(task);
  executors.submit(task);
  
  for (var index = 0; index < 10; index++) {
    executors.submit(task);
  }
}

class SameInstanceTask extends Task<String> {
  @override
  FutureOr<String> execute() async {
    await Future.delayed(Duration(minutes: 5));
    return "Done executing same instance task";
  }
} 
``` 

But if you want to submit the same instance of a task multiple times you need to override the Task is clone method.

For example, this will now work:
```dart
main() {
  final executors = ExecutorService.newUnboundExecutor();
  
  final task = SameInstanceTask();

  for (var index = 0; index < 10; index++) {
    executors.submit(task);
  }
  
  final taskWithParams = SameInstanceTaskWithParams("Darel Bitsy");

  for (var index = 0; index < 10; index++) {
    executors.submit(taskWithParams);
  }
}

class SameInstanceTask extends Task<String> {
  @override
  FutureOr<String> execute() async {
    await Future.delayed(Duration(minutes: 5));
    return "Done executing same instance task";
  }
  
  @override
  SameInstanceTask clone() {
    return SameInstanceTask();
  }
}

class SameInstanceTaskWithParams extends Task<String> {
  SameInstanceTaskWithParams(this.name);

  final String name;

  @override
  FutureOr<String> execute() async {
    await Future.delayed(Duration(minutes: 5));
    return "Done executing same instance task with name: $name";
  }
    
  @override
  SameInstanceTaskWithParams clone() {
    return SameInstanceTaskWithParams(name);
  }
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]:https://github.com/bitsydarel/executorservices/issues
