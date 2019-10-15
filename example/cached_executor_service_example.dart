import "package:executorservices/executorservices.dart";

import "utils.dart";

void main() async {
  printRunningIsolate("main");

  final executorService = ExecutorService.newUnboundExecutor();

  for (var index = 0; index < 10; index++) {
    executorService.submitCallable(concurrentFunction, index).then(
          (result) => printRunningIsolate(
            "concurrentFunction$index:result:$result",
          ),
        );
  }

  await Future.delayed(
    Duration(seconds: 10),
    () => print("Executor count: ${executorService.getExecutors().length}"),
  );

  for (var index = 10; index < 20; index++) {
    executorService.submitCallable(concurrentFunction, index).then(
          (result) => printRunningIsolate(
            "concurrentFunction$index:result:$result",
          ),
        );
  }

  await Future.delayed(
    Duration(seconds: 10),
    () => print("Executor count: ${executorService.getExecutors().length}"),
  );

  executorService.submitCallable(concurrentFunction, 100).then(
        (result) => printRunningIsolate(
          "concurrentFunction100:result:$result",
        ),
      );

  await Future.delayed(
    Duration(seconds: 10),
    () => print("Executor count: ${executorService.getExecutors().length}"),
  );
}
