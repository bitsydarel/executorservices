import "package:executorservices/executorservices.dart";
import "package:executorservices/src/tasks/task_output.dart";
import "executors/isolate_executor_web.dart"
    if (dart.library.io) "executors/isolate_executor.dart";

/// A [IsolateExecutorService] that run [Task]
/// into a [IsolateExecutor].
class IsolateExecutorService extends ExecutorService {
  /// Create a [IsolateExecutorService] with the following [identifier].
  ///
  /// [maxConcurrency] is the max of isolate to use for executing [Task].
  ///
  /// [allowCleanup] if true we will kill unused isolate
  /// if the [maxConcurrency] is greater than 5.
  IsolateExecutorService(
    String identifier,
    int maxConcurrency, {
    bool allowCleanup = false,
  }) : super(
          identifier,
          maxConcurrency,
          releaseUnusedExecutors: allowCleanup,
        );

  int _isolateCounter = 1;

  @override
  Executor createExecutor(final OnTaskCompleted onTaskCompleted) {
    return IsolateExecutor(
      "${identifier}_executor${_isolateCounter++}",
      onTaskCompleted,
    );
  }
}
