import "dart:async";
import "dart:collection";

import "package:executorservices/executorservices.dart";
import "package:executorservices/src/tasks/task_event.dart";
import "package:executorservices/src/tasks/task_output.dart";
import "package:executorservices/src/tasks/task_tracker.dart";
import "package:meta/meta.dart" show visibleForTesting;

typedef OnTaskRegistered = Future<SubmittedTaskEvent> Function(
  TaskRequest request,
);

/// [ExecutorService] tasks manager.
class TaskManager {
  /// Create [TaskManager] with [onTaskRegistered].
  ///
  /// [onTaskRegistered] allow you to specify
  /// on which [Executor] the [TaskManager] should run a specific task.
  factory TaskManager(
    OnTaskRegistered onTaskRegistered,
  ) {
    assert(onTaskRegistered != null, "onTaskRegistered cannot be null");

    return TaskManager.private(
      {},
      Queue(),
      StreamController(),
      onTaskRegistered,
    );
  }

  /// Create [TaskManager] with [_inProgressTasks], [_pendingTasks],
  /// [_taskHandler] and [_onTaskRegistered].
  @visibleForTesting
  TaskManager.private(
    this._inProgressTasks,
    this._pendingTasks,
    this._taskHandler,
    this._onTaskRegistered,
  );

  /// A repertoire of currently running [Task] that are waiting to be completed.
  final Map<Object, BaseTaskTracker> _inProgressTasks;

  /// The pending [BaseTask] that need to be executed.
  final Queue<BaseTask> _pendingTasks;

  /// A [StreamController] that handle all the new task submitted to the
  /// [ExecutorService].
  final StreamController<TaskRequest> _taskHandler;

  final Future<SubmittedTaskEvent> Function(TaskRequest taskRequest)
      _onTaskRegistered;

  /// Handle a [request] to be executed or queued for future run.
  void handle<R>(TaskRequest<R> request) {
    if (_inProgressTasks.containsKey(request.task.identifier)) {
      final newTask = request.task.clone();

      if (newTask == null) {
        throw UnsupportedError(
          "There's already a submitted task with the same instance, "
          "override the clone method of your task's class if you want "
          "to submit the same instance of your task multiple times",
        );
      }

      // update the request object with the new task.
      request = TaskRequest(newTask, request.taskCompleter);
    }

    // Save the task completer so we can manage the task update the task state.
    _inProgressTasks[request.task.identifier] = request.taskCompleter;

    if (!_taskHandler.hasListener) {
      _taskHandler.stream.asyncMap(_onTaskRegistered).listen(_handleTask);
    }

    _taskHandler.add(request);
  }

  /// Dispose the [TaskManager].
  Future<void> dispose() {
    _inProgressTasks.clear();
    _pendingTasks.clear();
    return _taskHandler.close();
  }

  /// Callback that's called when a [Executor]'s done processing a [Task].
  void onTaskOutput(
    final TaskOutput taskOutput,
    final Executor executor,
  ) {
    // Here if dart supported sealed class it's would be great.
    // todo: check for sealed class support for future dart versions.
    if (taskOutput is SuccessTaskOutput) {
      // this is a terminal event so we remove the task from the in progress
      final tracker = _inProgressTasks.remove(taskOutput.taskIdentifier);
      // notify the client of this tracker that the task's done.
      (tracker as TaskTracker).complete(taskOutput.result);
    } else if (taskOutput is FailedTaskOutput) {
      // this is a terminal event so we remove the task from the in progress.
      // notify the client that the task failed.
      _inProgressTasks
          .remove(taskOutput.taskIdentifier)
          .completeWithError(taskOutput.error);
    } else if (taskOutput is SubscribableTaskEvent) {
      final tracker = _inProgressTasks[taskOutput.taskIdentifier];
      // notify the client of the task that a new event has been received.
      (tracker as SubscribableTaskTracker).addEvent(taskOutput.event);
    } else if (taskOutput is SubscribableTaskError) {
      final tracker = _inProgressTasks[taskOutput.taskIdentifier];
      // notify the client of the task that a error has been received.
      (tracker as SubscribableTaskTracker).completeWithError(taskOutput.error);
    } else if (taskOutput is SubscribableTaskCancelled) {
      // this is a terminal event so we remove the task from the in progress.
      final tracker = _inProgressTasks.remove(taskOutput.taskIdentifier);
      // notify the client of this tracker that the task has terminated.
      (tracker as SubscribableTaskTracker).complete();
    } else if (taskOutput is SubscribableTaskDone) {
      // this is a terminal event so we remove the task from the in progress.
      final tracker = _inProgressTasks.remove(taskOutput.taskIdentifier);
      // notify the client of this tracker that the task's done.
      (tracker as SubscribableTaskTracker).complete();
    }

    if (_pendingTasks.isNotEmpty && !executor.isBusy()) {
      /// We give this task to the passed executor.
      executor.execute(_pendingTasks.removeFirst());
    }
  }

  /// Get the current running tasks.
  Map<Object, BaseTaskTracker> getInProgressTasks() =>
      UnmodifiableMapView(_inProgressTasks);

  /// Get the current pending [Task].
  List<BaseTask> getPendingTasks() => UnmodifiableListView(_pendingTasks);

  void _handleTask(final SubmittedTaskEvent event) {
    if (event.executor == null) {
      _pendingTasks.addLast(event.task);
    } else {
      event.executor.execute(event.task);
    }
  }
}

/// [TaskManager] request.
class TaskRequest<R> {
  /// Create a task manager request.
  const TaskRequest(this.task, this.taskCompleter);

  /// [BaseTask] to be managed by the [TaskManager].
  final BaseTask<R> task;

  /// [BaseTaskTracker] for completion.
  final BaseTaskTracker<R> taskCompleter;
}
