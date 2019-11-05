/// Package that allow to execute dart code into a isolate.
///
/// A variant of java executor api.
library executorservices;

import "dart:async";

import "dart:collection";

import "package:executorservices/src/exceptions.dart";
import "package:executorservices/src/services/isolate_executor_service.dart";
import "package:executorservices/src/task_manager.dart";
import "package:executorservices/src/tasks/task_event.dart";
import "package:executorservices/src/tasks/task_output.dart";
import "package:executorservices/src/tasks/task_tracker.dart";
import "package:executorservices/src/tasks/tasks.dart";
import "package:meta/meta.dart" show visibleForTesting, protected, factory;

import "src/utils/utils.dart"
    if (dart.library.html) "src/utils/utils_web.dart"
    if (dart.library.io) "src/utils/io_utils.dart";

export "src/exceptions.dart";

/// Maximum allowed executors to be kept.
const int maxNonBusyExecutors = 5;

/// Class that execute [BaseTask].
abstract class Executor {
  /// Create a [Executor] with the [onTaskCompleted].
  const Executor(this.onTaskCompleted);

  /// Callback that's called when a [Task] has completed.
  final OnTaskCompleted onTaskCompleted;

  /// Verify if the [Executor] is currently executing any [BaseTask].
  bool isBusy();

  /// Execute the [BaseTask] on the [Executor].
  void execute<R>(BaseTask<R> task);

  /// Cancel any on going subscription to a [SubscribableTask].
  void cancelSubscribableTask(CancelledSubscribableTaskEvent event);

  /// Pause any on going subscription to a [SubscribableTask].
  void pauseSubscribableTask(PauseSubscribableTaskEvent event);

  /// Resume any on going subscription to a [SubscribableTask].
  void resumeSubscribableTask(ResumeSubscribableTaskEvent event);

  /// Kill the [Executor], this is the best place to free all resources.
  FutureOr<void> kill();

  /// Get the last time this executor was used.
  DateTime lastUsage();
}

/// A service that may execute [BaseTask] on many [Executor].
abstract class ExecutorService {
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

  /// Create a new [ExecutorService] instance.
  ///
  /// [identifier] of the [ExecutorService].
  ///
  /// [maxExecutorCount] for how many executors can be used at time to
  /// execute a task, some [Executor] can run multiple tasks at a time.
  ExecutorService(
    this.identifier,
    this.maxExecutorCount, {
    this.releaseUnusedExecutors = false,
    final List<Executor> availableExecutors,
  })  : assert(identifier != null, "identifier can't be null"),
        assert(maxExecutorCount > 0, "maxConcurrency should be at least 1"),
        assert(
          releaseUnusedExecutors
              ? maxExecutorCount > maxNonBusyExecutors
              : !releaseUnusedExecutors, // value is false, just inverse it.
          "releaseUnusedExecutors can only be true "
          "if the maxExecutorCount is greater than $maxNonBusyExecutors",
        ),
        assert(
          (availableExecutors != null &&
                  availableExecutors.length <= maxExecutorCount) ||
              availableExecutors == null,
          "availableExecutors size can be at most equal to $maxExecutorCount",
        ),
        _executors = availableExecutors ?? [];

  /// The identifier of the [ExecutorService].
  final String identifier;

  /// The maximum number of [Task] allowed to be run at a time.
  final int maxExecutorCount;

  /// Release the unused [Executor].
  final bool releaseUnusedExecutors;

  /// The list of [Executor] that can run a [Task].
  @protected
  final List<Executor> _executors;

  TaskManager _taskManager;

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
      final taskTracker = TaskTracker<R>();

      getTaskManager().handle(TaskRequest(task, taskTracker));

      return taskTracker.progress();
    }
  }

  /// Subscribe to the events emitted by
  /// a top level or static [function] without argument.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  ///
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// if the [function] is can't be a top level or static,
  /// you should Implement [SubscribableTask].
  Stream<R> subscribeToAction<R>(final Stream<R> Function() function) {
    return subscribe(SubscribableActionTask(function));
  }

  /// Subscribe to the events emitted by
  /// a top level or static [function] with one argument.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// if the [function] is can't be a top level or static,
  /// you should Implement [SubscribableTask].
  Stream<R> subscribeToCallable<P, R>(
    final Stream<R> Function(P parameter) function,
    final P argument,
  ) {
    return subscribe(SubscribableCallableTask(argument, function));
  }

  /// Subscribe to the events emitted by
  /// a top level or static [function] with his two arguments.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// if the [function] is can't be a top level or static,
  /// you should Implement [SubscribableTask].
  Stream<R> subscribeToFunction2<P1, P2, R>(
    final Stream<R> Function(P1 p1, P2 p2) function,
    final P1 argument1,
    final P2 argument2,
  ) {
    return subscribe(SubscribableFunction2Task(argument1, argument2, function));
  }

  /// Subscribe to the events emitted by
  /// a top level or static [function] with 3 arguments.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// if the [function] is can't be a top level or static,
  /// you should Implement [SubscribableTask].
  Stream<R> subscribeToFunction3<P1, P2, P3, R>(
    final Stream<R> Function(P1 p1, P2 p2, P3 p3) function,
    final P1 argument1,
    final P2 argument2,
    final P3 argument3,
  ) {
    return subscribe(
      SubscribableFunction3Task(argument1, argument2, argument3, function),
    );
  }

  /// Subscribe to the events emitted by
  /// a top level or static [function] with 4 arguments.
  ///
  /// Throws [TaskRejectedException] if the [ExecutorService] is shutting down.
  /// Throws a [TaskFailedException] if for some reason the [function] failed
  /// with a exception.
  ///
  /// if the [function] is can't be a top level or static.
  /// Subscribe to the events emitted by
  Stream<R> subscribeToFunction4<P1, P2, P3, P4, R>(
    final Stream<R> Function(P1 p1, P2 p2, P3 p3, P4 p4) function,
    final P1 argument1,
    final P2 argument2,
    final P3 argument3,
    final P4 argument4,
  ) {
    return subscribe(
      SubscribableFunction4Task(
        argument1,
        argument2,
        argument3,
        argument4,
        function,
      ),
    );
  }

  /// Subscribe to the stream of events produced by [task].
  Stream<R> subscribe<R>(SubscribableTask<R> task) {
    if (_shuttingDown) {
      return Stream.error(TaskRejectedException(this));
    } else {
      final taskTracker = SubscribableTaskTracker<R>();

      getTaskManager().handle(TaskRequest(task, taskTracker));

      return taskTracker.progress();
    }
  }

  /// Shutdown the [ExecutorService].
  Future<void> shutdown() async {
    _shuttingDown = true;

    for (final executor in _executors) {
      await executor.kill();
    }

    await _taskManager.dispose();
  }

  /// Create a new [Executor] to execute [Task].
  Executor createExecutor(final OnTaskCompleted onTaskCompleted);

  /// Get the current list of [Executor].
  List<Executor> getExecutors() => UnmodifiableListView(_executors);

  /// Allow to verify if the [ExecutorService]
  /// can accept any [Task] or [Function].
  FutureOr<bool> canSubmitTask() => !_shuttingDown;

  /// Create a [SubmittedTaskEvent] for [request] with
  /// the next available [Executor] to execute the [request]'s task.
  @visibleForTesting
  Future<SubmittedTaskEvent> createNewTaskEvent(
    final TaskRequest request,
  ) async {
    final available = <Executor>[];

    for (final executor in _executors) {
      if (!executor.isBusy()) {
        available.add(executor);
      }
    }

    available.sort(
      // sort the list in the way that the older is at the bottom
      (left, right) => right.lastUsage().compareTo(left.lastUsage()),
    );

    if (releaseUnusedExecutors && available.length > maxNonBusyExecutors) {
      final releasableExecutor = available.last;
      _executors.remove(releasableExecutor);
      await releasableExecutor.kill();
    }

    var executor = available.isNotEmpty ? available.first : null;

    // We create a new executor if we don't have any available executor
    // And if the provided maxConcurrency allows us.
    if (executor == null && _executors.length < maxExecutorCount) {
      executor = createExecutor(getTaskManager().onTaskOutput);
      _executors.add(executor);
    }

    if (request.taskCompleter is SubscribableTaskTracker) {
      (request.taskCompleter as SubscribableTaskTracker)
          .setCancellationCallback(() => _taskManager.cancelTask(request.task));
    }

    return SubmittedTaskEvent(request.task, executor);
  }

  /// Get the current [ExecutorService]'s [TaskManager].
  @visibleForTesting
  TaskManager getTaskManager() =>
      _taskManager ??= TaskManager(createNewTaskEvent);
}

/// A class representing a unit of execution.
abstract class BaseTask<R> {
  /// Task identifier that allow us to identify a task through isolates.
  final Object identifier = createTaskIdentifier();

  /// Execute the task.
  R execute();

  /// Clone the task.
  ///
  /// This allow you to submit the same instance of your task multiple times.
  ///
  /// Note: You should always return a new instance of your task class.
  @factory
  BaseTask<R> clone() => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BaseTask &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;
}

/// A class representing a unit of execution that return a [Future] or [R]
abstract class Task<R> extends BaseTask<FutureOr<R>> {
  /// Clone the [Task].
  ///
  /// This allow you to submit the same instance of your task multiple times.
  ///
  /// Note: You should always return a new instance of your task class.
  @override
  @factory
  Task<R> clone() => null;
}

/// A class representing a stream of unit of execution.
abstract class SubscribableTask<R> extends BaseTask<Stream<R>> {
  /// Clone the [SubscribableTask].
  ///
  /// This allow you to submit the same instance of your task multiple times.
  ///
  /// Note: You should always return a new instance of your task class.
  @override
  @factory
  SubscribableTask<R> clone() => null;
}
