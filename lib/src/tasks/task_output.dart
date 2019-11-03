import "package:executorservices/executorservices.dart";

typedef OnTaskCompleted = void Function(TaskOutput output, Executor executor);

/// Class representing a [Task]'s output.
abstract class TaskOutput {
  /// Create [TaskOutput] for a [Task] with [taskIdentifier].
  const TaskOutput(this.taskIdentifier);

  /// Identifier that identify the [TaskOutput] a specific [Task].
  final Object taskIdentifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskOutput &&
          runtimeType == other.runtimeType &&
          taskIdentifier == other.taskIdentifier;

  @override
  int get hashCode => taskIdentifier.hashCode;
}

/// Subclass of [TaskOutput] that represent a failure output.
class FailedTaskOutput<R> extends TaskOutput {
  /// Create [SuccessTaskOutput] for a [Task] that failed with [error].
  const FailedTaskOutput(Object taskIdentifier, this.error)
      : assert(taskIdentifier != null, "taskIdentifier can't be null"),
        assert(error != null, "error can't be null"),
        super(taskIdentifier);

  /// The error produced by a [Task].
  final TaskFailedException error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is FailedTaskOutput &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => super.hashCode ^ error.hashCode;

  @override
  String toString() => "FailedTaskOutput{error: $error}";
}

/// Subclass of [TaskOutput] that represent a success output.
class SuccessTaskOutput<R> extends TaskOutput {
  /// Create [SuccessTaskOutput] for a [Task] that succeeded with [result].
  const SuccessTaskOutput(Object taskIdentifier, this.result)
      : assert(taskIdentifier != null, "taskIdentifier can't be null"),
        super(taskIdentifier);

  /// The result of a [Task].
  final R result;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is SuccessTaskOutput &&
          runtimeType == other.runtimeType &&
          result == other.result;

  @override
  int get hashCode => super.hashCode ^ result.hashCode;

  @override
  String toString() => "SuccessTaskOutput{result: $result}";
}

/// Subclass of [TaskOutput] that represent a stream event output.
class SubscribableTaskEvent<R> extends TaskOutput {
  /// Create [SubscribableTaskEvent] for a
  /// [SubscribableTask] that emitted a [event].
  const SubscribableTaskEvent(Object taskIdentifier, this.event)
      : assert(taskIdentifier != null, "taskIdentifier can't be null"),
        super(taskIdentifier);

  /// The event emitted by a [SubscribableTask].
  final R event;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is SubscribableTaskEvent &&
          runtimeType == other.runtimeType &&
          event == other.event;

  @override
  int get hashCode => super.hashCode ^ event.hashCode;
}

/// Subclass of [TaskOutput] that represent a stream error output.
class SubscribableTaskError extends TaskOutput {
  /// Create [SubscribableTaskError] for a
  /// [SubscribableTask] that emitted a [error].
  const SubscribableTaskError(Object taskIdentifier, this.error)
      : assert(taskIdentifier != null, "taskIdentifier can't be null"),
        super(taskIdentifier);

  /// The error emitted by a [SubscribableTask].
  final TaskFailedException error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is SubscribableTaskError &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => super.hashCode ^ error.hashCode;
}

/// Subclass of [TaskOutput] that represent a [SubscribableTask] cancellation.
class SubscribableTaskCancelled extends TaskOutput {
  /// Create [SubscribableTaskCancelled] for a
  /// [SubscribableTask] that is done emitting events.
  SubscribableTaskCancelled(Object taskIdentifier) : super(taskIdentifier);
}

/// Subclass of [TaskOutput] that represent a [SubscribableTask] completion.
class SubscribableTaskDone extends TaskOutput {
  /// Create [SubscribableTaskDone] for a
  /// [SubscribableTask] that has been cancelled.
  const SubscribableTaskDone(Object taskIdentifier) : super(taskIdentifier);
}
