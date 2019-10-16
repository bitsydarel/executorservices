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
        final intermediary = task.execute();

        onTaskCompleted(
          SuccessTaskOutput(
            task.identifier,
            intermediary is Future ? await intermediary : intermediary,
          ),
          this,
        );
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
    // ignore since there's no releasable resources.
  }

  @override
  DateTime lastUsage() => _lastUsage;
}
