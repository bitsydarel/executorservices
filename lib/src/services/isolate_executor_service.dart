import "package:executorservices/src/executors/isolate_executor.dart";
import "package:executorservices/executorservices.dart";

/// A [IsolateExecutorService] that run [Task] into a [IsolateExecutor].
class IsolateExecutorService extends ExecutorService {
  /// Create a [IsolateExecutorService].
  IsolateExecutorService(String identifier, int maxConcurrency)
      : super(identifier, maxConcurrency);

  int _isolateCounter = 1;

  @override
  Future<Executor> createExecutor(final OnTaskCompleted onTaskCompleted) {
    return Future.value(IsolateExecutor(
      "${identifier}_executor${_isolateCounter++}",
      onTaskCompleted,
    ));
  }
}
