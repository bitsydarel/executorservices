import "dart:math";

import "package:executorservices/executorservices.dart";

import "utils.dart";

void main() {
  printRunningIsolate("main");

  final executorService = ExecutorService.newFixedExecutor(
    Random.secure().nextInt(10),
  );

  for (var index = 0; index < 100; index++) {
    executorService.submitCallable(concurrentFunction, index).then(
          (result) => printRunningIsolate(
            "concurrentFunction$index:result:$result",
          ),
        );
  }
}
