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

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]:https://github.com/bitsydarel/executorservices/issues
