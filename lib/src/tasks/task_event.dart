import "package:executorservices/executorservices.dart";

/// Event that notify that a new [BaseTask] have been submitted.
class SubmittedTaskEvent {
  /// Create a [SubmittedTaskEvent] for [task] and [executor].
  SubmittedTaskEvent(this.task, this.executor);

  /// Task to be executed.
  final BaseTask task;

  /// Executor to executed the [task].
  ///
  /// Might be null if there's no available [Executor] to execute the [task].
  Executor executor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubmittedTaskEvent &&
          runtimeType == other.runtimeType &&
          task == other.task &&
          executor == other.executor;

  @override
  int get hashCode => task.hashCode ^ executor.hashCode;

  @override
  String toString() => "SubmittedTaskEvent{task: $task, executor: $executor}";
}

/// Event that notify that a [SubscribableTask] should be cancelled.
class CancelledSubscribableTaskEvent {
  /// Create a [CancelledSubscribableTaskEvent] for [taskIdentifier].
  CancelledSubscribableTaskEvent(this.taskIdentifier);

  /// Task's unique identifier.
  final Object taskIdentifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CancelledSubscribableTaskEvent &&
          runtimeType == other.runtimeType &&
          taskIdentifier == other.taskIdentifier;

  @override
  int get hashCode => taskIdentifier.hashCode;
}

/// Event that notify that a [SubscribableTask] should be paused.
class PauseSubscribableTaskEvent {
  /// Create a [PauseSubscribableTaskEvent] for [taskIdentifier].
  PauseSubscribableTaskEvent(this.taskIdentifier);

  /// Task's unique identifier.
  final Object taskIdentifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PauseSubscribableTaskEvent &&
          runtimeType == other.runtimeType &&
          taskIdentifier == other.taskIdentifier;

  @override
  int get hashCode => taskIdentifier.hashCode;
}

/// Event that notify that a [SubscribableTask] should be resumed.
class ResumeSubscribableTaskEvent {
  /// Create a [ResumeSubscribableTaskEvent] for [taskIdentifier].
  ResumeSubscribableTaskEvent(this.taskIdentifier);

  /// Task's unique identifier.
  final Object taskIdentifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResumeSubscribableTaskEvent &&
          runtimeType == other.runtimeType &&
          taskIdentifier == other.taskIdentifier;

  @override
  int get hashCode => taskIdentifier.hashCode;
}
