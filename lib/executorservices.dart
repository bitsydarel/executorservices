/// Package that allow to execute dart code into a isolate.
///
/// A variant of java executor api.
library executorservices;

import "dart:async";

import "dart:collection";

import "package:executorservices/src/exceptions.dart";
import "package:executorservices/src/services/isolate_executor_service.dart";
import "package:executorservices/src/tasks/tasks.dart";
import "package:meta/meta.dart" show visibleForTesting, protected, factory;

import "src/utils/utils_stub.dart"
    if (dart.library.html) "src/utils/utils_web.dart"
    if (dart.library.io) "src/utils/utils.dart";

export "src/exceptions.dart";

/// Maximum allowed executors to be kept.
const int maxNonBusyExecutors = 5;

typedef OnTaskCompleted = void Function(TaskOutput output, Executor executor);

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
  FutureOr<void> kill();

  /// Get the last time this executor was used.
  DateTime lastUsage();
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
    this.maxConcurrency, {
    this.releaseUnusedExecutors = false,
    final List<Executor> availableExecutors,
  })  : assert(identifier != null, "identifier can't be null"),
        assert(maxConcurrency > 0, "maxConcurrency should be at least 1"),
        _executors = availableExecutors ?? [];

  /// Create a cached [ExecutorService], that's backed by many [Executor].
  ///
  /// Note: It's unbound but restrict to the value of 2 ^ 63 so that you won't
  /// shoot yourself in the foot, if you want to go pass this
  /// use [ExecutorService.newFixedExecutor].
  ///
  /// Note: use isolate if the platform support them.
  factory ExecutorService.newUnboundExecutor([
    final String identifier = "io_isolate_service",
  ]) {
    return IsolateExecutorService(identifier, 2 ^ 63, allowCleanup: true);
  }

  /// Create a IO [ExecutorService], that's backed by a number [Executor]
  /// matching the number of cpu available.
  ///
  /// Note: use isolate if the platform support them.
  factory ExecutorService.newComputationExecutor([
    final String identifier = "computation_isolate_service",
  ]) {
    return IsolateExecutorService(identifier, getCpuCount());
  }

  /// Create a [ExecutorService] backed by a single [Executor].
  ///
  /// Note: use isolate if the platform support them.
  factory ExecutorService.newSingleExecutor([
    final String identifier = "single_isolate_service",
  ]) {
    return IsolateExecutorService(identifier, 1);
  }

  /// Create a [ExecutorService] backed by fixed number [Executor].
  ///
  /// Note: use isolate if the platform support them.
  factory ExecutorService.newFixedExecutor(
    final int executorCount, [
    final String identifier = "single_isolate_service",
  ]) {
    return IsolateExecutorService(identifier, executorCount);
  }

  /// The identifier of the [ExecutorService].
  final String identifier;

  /// The maximum number of [Task] allowed to be run at a time.
  final int maxConcurrency;

  /// Release the unused [Executor].
  final bool releaseUnusedExecutors;

  /// The list of [Executor] that can run a [Task].
  @protected
  final List<Executor> _executors;

  /// The pending [Task] that need to be executed.
  final Queue<Task> _pendingTasks = Queue();

  /// A repertoire of currently running [Task] that are waiting to be completed.
  final Map<Object, Completer> _inProgressTasks = {};

  /// A [StreamController] that handle all the new task submitted to the
  /// [ExecutorService].
  final StreamController<Task> _taskManager = StreamController();

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
      Function4Task(argument1, argument2, argument3, argument4, function),
    );
  }

  /// Submit a [task] to the [ExecutorService].
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws [TaskFailedException] if for some reason the [task] failed
  /// with a exception.
  Future<R> submit<R>(Task<R> task) {
    if (_shuttingDown) {
      return Future.error(TaskRejectedException(this));
    } else {
      final taskResult = Completer<R>();

      if (_inProgressTasks.containsKey(task.identifier)) {
        task = task.clone();

        if (task == null) {
          throw UnsupportedError(
            "There's already a submitted task with the same instance,"
            " override the clone method of your task's class if you want"
            " to submit the same instance of your task multiple times",
          );
        }
      }

      _inProgressTasks[task.identifier] = taskResult;

      if (!_taskManager.hasListener) {
        _taskManager.stream.asyncMap(createNewTaskEvent).map(
          (event) {
            if (event.executor == null && _executors.length < maxConcurrency) {
              final newExecutor = createExecutor(onTaskCompleted);
              _executors.add(newExecutor);
              event.executor = newExecutor;
              return event;
            } else {
              return event;
            }
          },
        ).listen(_handleTask);
      }

      _taskManager.add(task);

      return taskResult.future;
    }
  }

  /// Shutdown the [ExecutorService].
  Future<void> shutdown() async {
    _shuttingDown = true;

    for (final executor in _executors) {
      await executor.kill();
    }

    await _taskManager.close();
  }

  /// Create a new [Executor] to execute [Task].
  Executor createExecutor(final OnTaskCompleted onTaskCompleted);

  /// Get the current pending [Task].
  List<Task> getPendingTasks() => UnmodifiableListView(_pendingTasks);

  /// Get the current list of [Executor].
  List<Executor> getExecutors() => UnmodifiableListView(_executors);

  /// Allow to verify if the [ExecutorService]
  /// can accept any [Task] or [Function].
  FutureOr<bool> canSubmitTask() => !_shuttingDown;

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

  void _handleTask(final SubmittedTaskEvent event) {
    if (event.executor == null) {
      _pendingTasks.addLast(event.task);
    } else {
      event.executor.execute(event.task);
    }
  }

  /// Create a [SubmittedTaskEvent] for [task] with
  /// the next available [Executor] to execute the [task].
  @visibleForTesting
  Future<SubmittedTaskEvent> createNewTaskEvent(final Task task) async {
    final available = <Executor>[];

    for (final executor in _executors) {
      final isBusy = await executor.isBusy();

      if (!isBusy) {
        available.add(executor);
      }
    }

    available.sort(
      (left, right) => right.lastUsage().compareTo(left.lastUsage()),
    );

    if (releaseUnusedExecutors && available.length > maxNonBusyExecutors) {
      final releasableExecutor = available.last;
      _executors.remove(releasableExecutor);
      await releasableExecutor.kill();
    }

    return SubmittedTaskEvent(
      task,
      available.isNotEmpty ? available.first : null,
    );
  }
}

/// A class representing a unit of execution.
abstract class Task<R> {
  /// [Task] identifier that allow us to identify a task through isolates.
  final Object identifier = createTaskIdentifier();

  /// Run the task.
  FutureOr<R> execute();

  /// Clone the [Task].
  ///
  /// This allow you to submit the same instance of your task multiple times.
  ///
  /// Note: You should always return a new instance of your task class.
  @factory
  Task<R> clone() => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;
}
