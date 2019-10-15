import "dart:async";

import "../../executorservices.dart";

/// Event that notify that a new task have been submitted.
class SubmittedTaskEvent {
  /// Create a [SubmittedTaskEvent] for [task] and [executor].
  SubmittedTaskEvent(this.task, this.executor);

  /// Task to be executed.
  final Task task;

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

/// Class representing a [Task]'s output.
abstract class TaskOutput<R> {
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
class FailedTaskOutput<R> extends TaskOutput<R> {
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
class SuccessTaskOutput<R> extends TaskOutput<R> {
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

/// A [Task] that does not have any argument.
class ActionTask<R> extends Task<R> {
  /// Create a [Task] that run a [_function] without argument.
  ActionTask(this._function);

  final FutureOr<R> Function() _function;

  @override
  Future<R> execute() => _function();
}

/// A [Task] that require one parameter.
class CallableTask<P, R> extends Task<R> {
  /// Create a [Task] that run a [_function] with the following [_argument].
  CallableTask(this._argument, this._function);

  final P _argument;

  final FutureOr<R> Function(P parameter) _function;

  @override
  Future<R> execute() => _function(_argument);
}

/// A [Task] that require two parameters.
class Function2Task<P1, P2, R> extends Task<R> {
  /// Create a [Task] that run a [_function]
  /// with [_argument1] and [_argument2].
  Function2Task(this._argument1, this._argument2, this._function);

  final P1 _argument1;

  final P2 _argument2;

  final FutureOr<R> Function(P1 p1, P2 p2) _function;

  @override
  Future<R> execute() => _function(_argument1, _argument2);
}

/// A [Task] that require three parameters.
class Function3Task<P1, P2, P3, R> extends Task<R> {
  /// Create a [Task] that run a [_function]
  /// with [_argument1], [_argument2], [_argument3].
  Function3Task(
    this._argument1,
    this._argument2,
    this._argument3,
    this._function,
  );

  final P1 _argument1;

  final P2 _argument2;

  final P3 _argument3;

  final FutureOr<R> Function(P1 p1, P2 p2, P3 p3) _function;

  @override
  Future<R> execute() => _function(_argument1, _argument2, _argument3);
}

/// A [Task] that require four parameters.
class Function4Task<P1, P2, P3, P4, R> extends Task<R> {
  /// Create a [Task] that run a [_function]
  /// with [_argument1], [_argument2], [_argument3] and [_argument4].
  Function4Task(
    this._argument1,
    this._argument2,
    this._argument3,
    this._argument4,
    this._function,
  );

  final P1 _argument1;

  final P2 _argument2;

  final P3 _argument3;

  final P4 _argument4;

  final FutureOr<R> Function(P1 p1, P2 p2, P3 p3, P4 p4) _function;

  @override
  Future<R> execute() {
    return _function(_argument1, _argument2, _argument3, _argument4);
  }
}
