import "dart:async";

import "../../executorservices.dart";

/// A [Task] that does not have any argument.
class ActionTask<R> extends Task<R> {
  /// Create a [Task] that run a [_function] without argument.
  ActionTask(this._function);

  final FutureOr<R> Function() _function;

  @override
  FutureOr<R> execute() => _function();
}

/// A [Task] that require one parameter.
class CallableTask<P, R> extends Task<R> {
  /// Create a [Task] that run a [_function] with the following [_argument].
  CallableTask(this._argument, this._function);

  final P _argument;

  final FutureOr<R> Function(P parameter) _function;

  @override
  FutureOr<R> execute() => _function(_argument);
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
  FutureOr<R> execute() => _function(_argument1, _argument2);
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
  FutureOr<R> execute() => _function(_argument1, _argument2, _argument3);
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
  FutureOr<R> execute() {
    return _function(_argument1, _argument2, _argument3, _argument4);
  }
}

/// A [SubscribableTask] that does not have any argument.
class SubscribableActionTask<R> extends SubscribableTask<R> {
  /// Create a [Task] that run a [_function] without argument.
  SubscribableActionTask(this._function);

  final Stream<R> Function() _function;

  @override
  Stream<R> execute() => _function();
}

/// A [SubscribableTask] that require one parameter.
class SubscribableCallableTask<P, R> extends SubscribableTask<R> {
  /// Create a [Task] that run a [_function] with the following [_argument].
  SubscribableCallableTask(this._argument, this._function);

  final P _argument;

  final Stream<R> Function(P parameter) _function;

  @override
  Stream<R> execute() => _function(_argument);
}

/// A [SubscribableTask] that require two parameters.
class SubscribableFunction2Task<P1, P2, R> extends SubscribableTask<R> {
  /// Create a [Task] that run a [_function]
  /// with [_argument1] and [_argument2].
  SubscribableFunction2Task(this._argument1, this._argument2, this._function);

  final P1 _argument1;

  final P2 _argument2;

  final Stream<R> Function(P1 p1, P2 p2) _function;

  @override
  Stream<R> execute() => _function(_argument1, _argument2);
}

/// A [Task] that require three parameters.
class SubscribableFunction3Task<P1, P2, P3, R> extends SubscribableTask<R> {
  /// Create a [Task] that run a [_function]
  /// with [_argument1], [_argument2], [_argument3].
  SubscribableFunction3Task(
    this._argument1,
    this._argument2,
    this._argument3,
    this._function,
  );

  final P1 _argument1;

  final P2 _argument2;

  final P3 _argument3;

  final Stream<R> Function(P1 p1, P2 p2, P3 p3) _function;

  @override
  Stream<R> execute() => _function(_argument1, _argument2, _argument3);
}

/// A [Task] that require four parameters.
class SubscribableFunction4Task<P1, P2, P3, P4, R> extends SubscribableTask<R> {
  /// Create a [Task] that run a [_function]
  /// with [_argument1], [_argument2], [_argument3] and [_argument4].
  SubscribableFunction4Task(
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

  final Stream<R> Function(P1 p1, P2 p2, P3 p3, P4 p4) _function;

  @override
  Stream<R> execute() {
    return _function(_argument1, _argument2, _argument3, _argument4);
  }
}
