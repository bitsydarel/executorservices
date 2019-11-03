import "dart:async";

import "package:executorservices/executorservices.dart";
import "package:executorservices/src/tasks/task_event.dart";
import "package:executorservices/src/tasks/task_output.dart";
import "package:executorservices/src/utils/utils.dart";

/// [Executor] that execute [Task] into a isolate.
class IsolateExecutor extends Executor {
  /// Create an [IsolateExecutor] with the specified [identifier].
  IsolateExecutor(
    this.identifier,
    OnTaskCompleted taskCompletion,
  )   : assert(taskCompletion != null, "taskCompletion can't be null"),
        super(taskCompletion);

  /// The identifier of the [IsolateExecutor].
  final String identifier;

  var _processingTask = false;

  DateTime _lastUsage;

  final _inProgressSubscriptions = <Object, StreamSubscription>{};

  @override
  void execute<R>(BaseTask<R> task) {
    _processingTask = true;

    if (task is Task) {
      Future.microtask(() async {
        try {
          final intermediary = (task as Task).execute();

          _setTerminalTaskOutput(
            SuccessTaskOutput(
              task.identifier,
              intermediary is Future ? await intermediary : intermediary,
            ),
          );
        } on Object catch (error) {
          final taskError = TaskFailedException(
            error.runtimeType,
            error.toString(),
          );

          _setTerminalTaskOutput(FailedTaskOutput(task.identifier, taskError));
        }
      });
    } else if (task is SubscribableTask) {
      try {
        final stream = (task as SubscribableTask).execute();

        // Ignoring the cancellation of the subscription
        // because it's the user who control when to cancel the stream.
        // We also cancel stream when it's stream is done.
        // ignore: cancel_subscriptions
        final subscription = stream.listen(
          (event) {
            _lastUsage = DateTime.now();

            onTaskCompleted(
              SubscribableTaskEvent(task.identifier, event),
              this,
            );
          },
          onError: (error) {
            _lastUsage = DateTime.now();

            onTaskCompleted(
              SubscribableTaskError(
                task.identifier,
                TaskFailedException(error.runtimeType, error.toString()),
              ),
              this,
            );
          },
          onDone: () async {
            await cleanupSubscription(
              task.identifier,
              _inProgressSubscriptions,
            );

            _setTerminalTaskOutput(SubscribableTaskDone(task.identifier));
          },
        );
        // keep the subscription so that it's can be cancelled, paused, resumed.
        _inProgressSubscriptions[task.identifier] = subscription;
      } on Object catch (error) {
        final taskError = TaskFailedException(
          error.runtimeType,
          error.toString(),
        );

        _setTerminalTaskOutput(FailedTaskOutput(task.identifier, taskError));
      }
    } else {
      throw ArgumentError(
        "${task.runtimeType} messages are not supported,"
        " your message should extends $Task or $SubscribableTask",
      );
    }

    _lastUsage = DateTime.now();
  }

  @override
  void cancelSubscribableTask(CancelledSubscribableTaskEvent event) async {
    await cleanupSubscription(event.taskIdentifier, _inProgressSubscriptions);
    _setTerminalTaskOutput(SubscribableTaskCancelled(event.taskIdentifier));
  }

  @override
  void pauseSubscribableTask(PauseSubscribableTaskEvent event) {
    pauseSubscription(event.taskIdentifier, _inProgressSubscriptions);
  }

  @override
  void resumeSubscribableTask(ResumeSubscribableTaskEvent event) {
    resumeSubscription(event.taskIdentifier, _inProgressSubscriptions);
    _lastUsage = DateTime.now();
  }

  @override
  bool isBusy() => _processingTask;

  @override
  FutureOr<void> kill() async {
    for (final subscription in _inProgressSubscriptions.values) {
      await subscription.cancel();
    }

    _inProgressSubscriptions.clear();
  }

  @override
  DateTime lastUsage() => _lastUsage;

  void _setTerminalTaskOutput(final TaskOutput output) {
    _processingTask = false;
    onTaskCompleted(output, this);
    _lastUsage = DateTime.now();
  }
}
