import "package:executorservices/executorservices.dart";

import "utils.dart";

/// Create a [ExecutorService] backed by isolates.
///
/// Isolates are created as needed to execute incoming task.
///
/// If there's free isolates they we will be re-used.
///
/// Unused isolates are release gradually.
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
