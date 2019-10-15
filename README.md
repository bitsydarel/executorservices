A library for Dart and Flutter developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/bitsydarel/executorservices/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import "package:executorservices/executorservices.dart";
import "dart:math";

main() {
  final cachedExecutorService = ExecutorService.newCachedExecutor();

  cachedExecutorService.submitAction(randomInt);

  cachedExecutorService.submit(SomeIntensiveTask());
}

int randomInt() {
  return Random.secure().nextInt(1000);
}

class SomeIntensiveTask extends Task<String> {
  @override
  Future<String> execute() async {
    await Future.delayed(Duration(minutes: 5));
    return "Done executing intensive task";
  }
} 
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]:https://github.com/bitsydarel/executorservices/issues
