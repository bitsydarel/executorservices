/// Package that allow to execute dart code into a isolate.
///
/// A variant of java executor api.
library executorservices;

import "dart:async";

import "dart:collection";

import "dart:isolate";

import "package:executorservices/src/services/Isolate_executor_service.dart";
import "package:executorservices/src/tasks/tasks.dart";
import "package:meta/meta.dart" show visibleForTesting, protected;

export "package:executorservices/src/services/isolate_executor_service.dart";

typedef OnTaskCompleted = void Function(TaskOutput output, Executor executor);

/// A [Exception] that's thrown when a [ExecutorService]
/// is shutting down but client keep submitting work to it.
class TaskRejectedException implements Exception {
  /// Create a [TaskRejectedException] with the following [service].
  const TaskRejectedException(this.service);

  /// [ExecutorService] that trowed the [TaskRejectedException].
  final ExecutorService service;

  @override
  String toString() => "Task can't be submitted because "
      "[${service.runtimeType}:${service.identifier}]"
      " is shutting down";
}

/// A [Exception] that's thrown when a [Task] failed with a exception.
///
/// Why having a custom [Exception] ?
///
/// Because [SendPort] send method does not accept object that are not from
/// the same code and in the same process unless they are primitive.
class TaskFailedException implements Exception {
  /// [TaskFailedException] for the following [errorType] and [errorMessage].
  const TaskFailedException(this.errorType, this.errorMessage);

  /// The type of the error that was thrown.
  final Type errorType;

  /// Message describing the error.
  final String errorMessage;

  @override
  String toString() => "Task failed with $errorType because $errorMessage";
}

/// Class that execute [Task].
abstract class Executor {
  /// Create a [Executor] with the [onTaskCompleted].
  const Executor(this.onTaskCompleted);

  /// Callback that's called when a [Task] has completed.
  final OnTaskCompleted onTaskCompleted;

  /// Verify if the [Executor] is currently executing any [Task].
  FutureOr<bool> isBusy();

  /// Execute the [Task] on the [Executor].
  void execute<R>(final Task<R> task);

  /// Kill the [Executor], this is the best place to free all resources.
  Future<void> kill();
}

/// A service that may execute [Task] on many [Executor].
abstract class ExecutorService {
  /// Create a new [ExecutorService] instance.
  ///
  /// [identifier] of the [ExecutorService].
  ///
  /// [maxConcurrency] for how many concurrent task can't be run at a time.
  ExecutorService(
    this.identifier,
    this.maxConcurrency, [
    final List<Executor> availableExecutors,
  ])  : assert(identifier != null, "identifier can't be null"),
        assert(maxConcurrency > 0, "maxConcurrency should be at least 1"),
        executors = availableExecutors ?? [];

  /// Create a IO [ExecutorService], that's backed by [Isolate].
  factory ExecutorService.newIOExecutorService([
    final String identifier = "io_isolate_service",
    final int maxConcurrency = 2 ^ 63,
  ]) {
    return IsolateExecutorService(identifier, maxConcurrency);
  }

  /// The identifier of the [ExecutorService].
  final String identifier;

  /// The maximum number of [Task] allowed to be run at a time.
  final int maxConcurrency;

  /// The list of [Executor] that can run a [Task].
  @protected
  final List<Executor> executors;

  /// The pending [Task] that need to be executed.
  final Queue<Task> _pendingTasks = Queue();

  /// A repertoire of currently running [Task] that are waiting to be completed.
  final Map<Capability, Completer> _inProgressTasks = {};

  bool _shuttingDown = false;

  /// Submit a top level or static [function] without argument.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  ///
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// Implement [Task] if the [function] is can't be a top level or static.
  Future<R> submitAction<R>(final FutureOr<R> Function() function) {
    return submit(ActionTask(function));
  }

  /// Submit a top level or static [function] with one argument.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// Implement [Task] if the [function] is can't be a top level or static.
  Future<R> submitCallable<P, R>(
    final FutureOr<R> Function(P parameter) function,
    final P argument,
  ) {
    return submit(CallableTask(argument, function));
  }

  /// Submit a top level or static [function] with his two arguments.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// Implement [Task] if the [function] is can't be a top level or static.
  Future<R> submitFunction2<P1, P2, R>(
    final FutureOr<R> Function(P1 p1, P2 p2) function,
    final P1 argument1,
    final P2 argument2,
  ) {
    return submit(Function2Task(argument1, argument2, function));
  }

  /// Submit a top level or static [function] with 3 arguments.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// Implement [Task] if the [function] is can't be a top level or static.
  Future<R> submitFunction3<P1, P2, P3, R>(
    final FutureOr<R> Function(P1 p1, P2 p2, P3 p3) function,
    final P1 argument1,
    final P2 argument2,
    final P3 argument3,
  ) {
    return submit(Function3Task(argument1, argument2, argument3, function));
  }

  /// Submit a top level or static [function] with 4 arguments.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// Implement [Task] if the [function] is can't be a top level or static.
  Future<R> submitFunction4<P1, P2, P3, P4, R>(
    final FutureOr<R> Function(P1 p1, P2 p2, P3 p3, P4 p4) function,
    final P1 argument1,
    final P2 argument2,
    final P3 argument3,
    final P4 argument4,
  ) {
    return submit(
      Function4Task(
        argument1,
        argument2,
        argument3,
        argument4,
        function,
      ),
    );
  }

  /// Submit a [task] to the [ExecutorService].
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws [TaskFailedException] if for some reason the [task] failed
  /// with a exception.
  Future<R> submit<R>(final Task<R> task) async {
    if (_shuttingDown) {
      return Future.error(TaskRejectedException(this));
    } else {
      final taskResult = Completer<R>();

      _inProgressTasks[task.identifier] = taskResult;

      final executor = await findAvailableExecutor();

      if (executor != null) {
        executor.execute(task);
      } else if (executors.length < maxConcurrency) {
        final newExecutor = await createExecutor(onTaskCompleted);

        executors.add(newExecutor);

        newExecutor.execute(task);
      } else {
        _pendingTasks.addLast(task);
      }

      return taskResult.future;
    }
  }

  /// Get the current pending tasks.
  List<Task> getPendingTasks() => UnmodifiableListView(_pendingTasks);

  /// Allow to verify if the [ExecutorService]
  /// can accept any [Task] or [Function].
  FutureOr<bool> canSubmitTask() => !_shuttingDown;

  /// Shutdown the [ExecutorService].
  Future<void> shutdown() async {
    _shuttingDown = true;

    for (final executor in executors) {
      await executor.kill();
    }
  }

  /// Create a new [Executor] to execute [Task].
  Future<Executor> createExecutor(final OnTaskCompleted onTaskCompleted);

  /// Find the next available executor to execute a [Task].
  @visibleForTesting
  Future<Executor> findAvailableExecutor() async {
    for (final executor in executors) {
      final isBusy = await executor.isBusy();

      if (!isBusy) {
        return executor;
      }
    }
    return null;
  }

  /// Callback that's called when a [Executor]'s done processing a [Task].
  @visibleForTesting
  void onTaskCompleted(
    final TaskOutput taskOutput,
    final Executor executor,
  ) {
    final completer = _inProgressTasks.remove(taskOutput.taskIdentifier);

    // Here if dart supported sealed class it's would be great.
    // todo: check for sealed class support for dart.
    if (taskOutput is SuccessTaskOutput) {
      completer.complete(taskOutput.result);
    } else if (taskOutput is FailedTaskOutput) {
      completer.completeError(taskOutput.error);
    }

    if (_pendingTasks.isNotEmpty) {
      /// We give this task to the passed executor.
      executor.execute(_pendingTasks.removeFirst());
    }
  }
}

/// A class representing a unit of execution.
abstract class Task<R> {
  /// Create a new task.
  Task() : identifier = Capability();

  /// [Task] identifier that can allow us to identify a task through isolates.
  final Capability identifier;

  /// Run the task.
  Future<R> execute();
}
