import "package:executorservices/executorservices.dart";

import "utils.dart";

/// Create a [ExecutorService] backed by isolates.
///
/// Isolates are created as needed to execute incoming task.
///
/// If there's free isolates they we will be re-used.
///
/// This executor does not release backed isolates and
/// the max number of isolates is equal to the cpu count of the running device.
void main() {
  printRunningIsolate("main");

  final executorService = ExecutorService.newComputationExecutor();

  for (var index = 0; index < 100; index++) {
    executorService.submitCallable(concurrentFunction, index).then(
          (result) => printRunningIsolate(
            "concurrentFunction$index:result:$result",
          ),
        );
  }
}
