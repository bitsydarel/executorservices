import "dart:async";
import "dart:isolate";

import "package:executorservices/executorservices.dart";

/// Class representing a [Task]'s output.
abstract class TaskOutput<R> {
  /// Create [TaskOutput] for a [Task] with [taskIdentifier].
  const TaskOutput(this.taskIdentifier);

  /// Identifier that identify the [TaskOutput] a specific [Task].
  final Capability taskIdentifier;
}

/// Subclass of [TaskOutput] that represent a failure output.
class FailedTaskOutput<R> extends TaskOutput<R> {
  /// Create [SuccessTaskOutput] for a [Task] that failed with [error].
  const FailedTaskOutput(Capability taskIdentifier, this.error)
      : assert(taskIdentifier != null, "taskIdentifier can't be null"),
        assert(error != null, "error can't be null"),
        super(taskIdentifier);

  /// The error produced by a [Task].
  final TaskFailedException error;
}

/// Subclass of [TaskOutput] that represent a success output.
class SuccessTaskOutput<R> extends TaskOutput<R> {
  /// Create [SuccessTaskOutput] for a [Task] that succeeded with [result].
  const SuccessTaskOutput(Capability taskIdentifier, this.result)
      : assert(taskIdentifier != null, "taskIdentifier can't be null"),
        super(taskIdentifier);

  /// The result of a [Task].
  final R result;
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
  /// Create a [Task] that run a [_function] with the following [_parameter].
  CallableTask(this._parameter, this._function);

  final P _parameter;

  final FutureOr<R> Function(P parameter) _function;

  @override
  Future<R> execute() => _function(_parameter);
}

/// A [Task] that require two parameters.
class Function2Task<P1, P2, R> extends Task<R> {
  /// Create a [Task] that run a [_function]
  /// with [_parameter1] and [_parameter2].
  Function2Task(this._parameter1, this._parameter2, this._function);

  final P1 _parameter1;

  final P2 _parameter2;

  final FutureOr<R> Function(P1 parameter1, P2 parameter2) _function;

  @override
  Future<R> execute() => _function(_parameter1, _parameter2);
}

/// A [Task] that require three parameters.
class Function3Task<P1, P2, P3, R> extends Task<R> {
  /// Create a [Task] that run a [_function]
  /// with [_parameter1], [_parameter2], [_parameter3].
  Function3Task(
    this._parameter1,
    this._parameter2,
    this._parameter3,
    this._function,
  );

  final P1 _parameter1;

  final P2 _parameter2;

  final P3 _parameter3;

  final FutureOr<R> Function(P1 p1, P2 p2, P3 p3) _function;

  @override
  Future<R> execute() => _function(_parameter1, _parameter2, _parameter3);
}

/// A [Task] that require four parameters.
class Function4Task<P1, P2, P3, P4, R> extends Task<R> {
  /// Create a [Task] that run a [_function]
  /// with [_parameter1], [_parameter2], [_parameter3] and [_parameter4].
  Function4Task(
    this._parameter1,
    this._parameter2,
    this._parameter3,
    this._parameter4,
    this._function,
  );

  final P1 _parameter1;

  final P2 _parameter2;

  final P3 _parameter3;

  final P4 _parameter4;

  final FutureOr<R> Function(P1 p1, P2 p2, P3 p3, P4 p4) _function;

  @override
  Future<R> execute() {
    return _function(
      _parameter1,
      _parameter2,
      _parameter3,
      _parameter4,
    );
  }
}
