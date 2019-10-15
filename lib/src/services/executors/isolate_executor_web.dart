import "dart:async";

import "package:executorservices/executorservices.dart";
import "package:executorservices/src/tasks/tasks.dart";

/// [Executor] that execute [Task] into a isolate.
class IsolateExecutor extends Executor {
  /// Create an [IsolateExecutor] with the specified [identifier].
  IsolateExecutor(
    this.identifier,
    OnTaskCompleted taskCompletion,
  ) : super(taskCompletion);

  /// The identifier of the [IsolateExecutor].
  final String identifier;

  var _processingTask = false;

  DateTime _lastUsage;

  @override
  void execute<R>(Task<R> task) {
    _processingTask = true;

    Future.microtask(() async {
      try {
        final result = await task.execute();
        onTaskCompleted(SuccessTaskOutput(task.identifier, result), this);
      } on Object catch (error) {
        final taskError = TaskFailedException(
          error.runtimeType,
          error.toString(),
        );
        onTaskCompleted(FailedTaskOutput(task.identifier, taskError), this);
      }
    });

    _lastUsage = DateTime.now();
  }

  @override
  FutureOr<bool> isBusy() => _processingTask;

  @override
  FutureOr<void> kill() {
    // ignore since no resources are helded.
  }

  @override
  DateTime lastUsage() => _lastUsage;
}
