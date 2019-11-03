import "dart:io";
import "dart:math";

import "package:executorservices/executorservices.dart";

import "utils.dart";

/// Create a [ExecutorService] backed by isolates.
///
/// Isolates are created as needed to execute incoming task.
///
/// If there's free isolates they we will be re-used.
///
/// This executor does not release backed isolates and
/// the max number of isolates is equal to the specified count.
void main() {
  printRunningIsolate("main");

  final executorService = ExecutorService.newFixedExecutor(
    Random.secure().nextInt(10 + 1),
  );

  for (var index = 0; index < 100000; index++) {
    executorService.submitCallable(concurrentFunction, index).then(
          (result) => printRunningIsolate(
            "concurrentFunction$index:result:$result",
          ),
        );
  }

  Future.delayed(Duration(minutes: 15), () => exit(0));
}
