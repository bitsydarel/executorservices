import "package:executorservices/executorservices.dart";

import "utils.dart";

void main() {
  printRunningIsolate("main");

  final executorService = ExecutorService.newUnboundExecutor();

  final startTime = DateTime.now();

  for (var index = 0; index < 10000; index++) {
    executorService
        .submitFunction2(
          concurrentFunctionTimed,
          index,
          startTime,
        )
        .then(
          (result) => printRunningIsolate(
            "concurrentFunction$index:result:$result",
          ),
        );
  }
}
