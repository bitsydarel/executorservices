import "dart:async";

import "package:executorservices/executorservices.dart";
import "package:executorservices/src/task_manager.dart";
import "package:executorservices/src/tasks/task_event.dart";
import "package:executorservices/src/tasks/task_output.dart";
import "package:executorservices/src/tasks/task_tracker.dart";
import "package:executorservices/src/tasks/tasks.dart";
import "package:mockito/mockito.dart";
import "package:test/test.dart";

import "test_utils.dart";

void main() {
  test(
    "Should return the available executor if there's one that is not busy",
    () {
      final mockExecutor1 = MockExecutor(1);
      final mockExecutor2 = MockExecutor(2);

      when(mockExecutor1.isBusy()).thenAnswer((_) => false);
      when(mockExecutor2.isBusy()).thenAnswer((_) => true);

      final executorService = _FakeExecutorService(
        "fakeexecutor",
        2,
        false,
        [mockExecutor1, mockExecutor2],
      );

      final task = CleanableFakeDelayingTask();
      final taskTracker = TaskTracker();

      expect(
        executorService.createNewTaskEvent(TaskRequest(task, taskTracker)),
        completion(equals(SubmittedTaskEvent(task, mockExecutor1))),
      );
    },
  );

  test(
    "Should return null if there's no available executor",
    () {
      final mockExecutor1 = MockExecutor(1);
      final mockExecutor2 = MockExecutor(2);

      when(mockExecutor1.isBusy()).thenAnswer((_) => true);
      when(mockExecutor2.isBusy()).thenAnswer((_) => true);

      final executorService = _FakeExecutorService(
        "fakeexecutor",
        2,
        false,
        [mockExecutor1, mockExecutor2],
      );

      final task = CleanableFakeDelayingTask();
      final taskTracker = TaskTracker();

      expect(
        executorService.createNewTaskEvent(TaskRequest(task, taskTracker)),
        completion(equals(SubmittedTaskEvent(task, null))),
      );
    },
  );

  test(
    "should put the task into pending queue if there's no available executor",
    () {
      final mockExecutor1 = MockExecutor(1);

      when(mockExecutor1.isBusy()).thenAnswer((_) => true);

      final executorService = _FakeExecutorService(
        "fakeexecutor",
        1,
        false,
        [mockExecutor1],
      );

      expect(executorService.getTaskManager().getPendingTasks(), isEmpty);

      // we can't await for the result because the executor will never be
      // ready to process this task so we will wait forever.
      executorService.submitAction(() => print("should not be printe"));

      expect(
        // Workaround to wait for when the event-loop will process the
        // future task in the queue.
        // It's might make the test flaky but work as of now.
        Future.delayed(
          Duration(milliseconds: 500),
          executorService.getTaskManager().getPendingTasks,
        ),
        completion(hasLength(1)),
      );
    },
  );

  test(
    "should execute the task if there's one available executor",
    () async {
      final mockExecutor1 = MockExecutor(1);

      when(mockExecutor1.isBusy()).thenAnswer((_) => false);

      final executorService = _FakeExecutorService(
        "fakeservice",
        1,
        false,
        [mockExecutor1],
      );

      final task = ActionTask(() => print(""));

      verifyNever(mockExecutor1.execute(task));

      // we can't await for the result because the executor will never be
      // ready to process this task so we will wait forever.
      // ignore: unawaited_futures
      executorService.submit(task);

      await Future.delayed(Duration(milliseconds: 500));

      verify(mockExecutor1.execute(task))..called(1);
    },
  );

  test(
    "should create a executer and execute the task if there's"
    " no free executor and the max concurrency allow it",
    () async {
      final mockExecutor1 = MockExecutor(1);
      final mockExecutor2 = MockExecutor(2);

      final executorService = _FakeExecutorService(
        "fakeservice",
        2,
        false,
        [mockExecutor1],
        (configuration) => mockExecutor2,
      );

      when(mockExecutor1.isBusy()).thenAnswer((_) => true);

      final task = ActionTask(() => print(""));

      // we can't await for the result because the executor will never be
      // ready to process this task so we will wait forever.
      // ignore: unawaited_futures
      executorService.submit(task);

      await Future.delayed(Duration(milliseconds: 500));

      verify(mockExecutor2.execute(task))..called(1);
    },
  );

  test(
    "should remove unused executors if executors are more $maxNonBusyExecutors",
    () async {
      final mockExecutor1 = MockExecutor(1);
      final mockExecutor2 = MockExecutor(2);
      final mockExecutor3 = MockExecutor(3);
      final mockExecutor4 = MockExecutor(4);
      final mockExecutor5 = MockExecutor(5);
      final mockExecutor6 = MockExecutor(6);
      final mockExecutor7 = MockExecutor(7);
      final mockExecutor8 = MockExecutor(8);

      when(mockExecutor1.isBusy()).thenAnswer((_) => false);
      when(mockExecutor1.lastUsage()).thenReturn(
        DateTime.now().subtract(Duration(minutes: 1)),
      );

      when(mockExecutor2.isBusy()).thenAnswer((_) => false);
      when(mockExecutor2.lastUsage()).thenReturn(
        DateTime.now().subtract(Duration(minutes: 2)),
      );

      when(mockExecutor3.isBusy()).thenAnswer((_) => false);
      when(mockExecutor3.lastUsage()).thenReturn(
        DateTime.now().subtract(Duration(minutes: 3)),
      );

      when(mockExecutor4.isBusy()).thenAnswer((_) => false);
      when(mockExecutor4.lastUsage()).thenReturn(
        DateTime.now().subtract(Duration(minutes: 4)),
      );

      when(mockExecutor5.isBusy()).thenAnswer((_) => false);
      when(mockExecutor5.lastUsage()).thenReturn(
        DateTime.now().subtract(Duration(minutes: 5)),
      );

      when(mockExecutor6.isBusy()).thenAnswer((_) => false);
      when(mockExecutor6.lastUsage()).thenReturn(
        DateTime.now().subtract(Duration(minutes: 6)),
      );

      when(mockExecutor7.isBusy()).thenAnswer((_) => false);
      when(mockExecutor7.lastUsage()).thenReturn(
        DateTime.now().subtract(Duration(minutes: 7)),
      );

      when(mockExecutor8.isBusy()).thenAnswer((_) => false);
      when(mockExecutor8.lastUsage()).thenReturn(
        DateTime.now().subtract(Duration(minutes: 8)),
      );

      final executorService = _FakeExecutorService(
        "fakeexecutor",
        8,
        true /* We are allowing the service to cleanup executors */,
        [
          mockExecutor1,
          mockExecutor2,
          mockExecutor3,
          mockExecutor4,
          mockExecutor5,
          mockExecutor6,
          mockExecutor7,
          mockExecutor8,
        ],
      );

      expect(executorService.getExecutors(), hasLength(8));

      final task = CleanableFakeDelayingTask();
      final taskTracker = TaskTracker();

      await executorService.createNewTaskEvent(TaskRequest(task, taskTracker));

      expect(executorService.getExecutors(), hasLength(7));

      expect(
        executorService.getExecutors(),
        equals([
          mockExecutor1,
          mockExecutor2,
          mockExecutor3,
          mockExecutor4,
          mockExecutor5,
          mockExecutor6,
          mockExecutor7,
        ]),
      );
    },
  );

  test(
    "should return result even if there's a task with the same unique id",
    () {
      final executors = ExecutorService.newUnboundExecutor();

      final task = CleanableFakeDelayingTask();

      final results = <Future<void>>[];

      for (var index = 0; index < 10; index++) {
        results.add(executors.submit(task));
      }

      for (var index = 0; index < 10; index++) {
        results.add(executors.submit(FakeDelayingTask()));
      }

      expect(Future.wait(results), completes);
    },
  );
}

class _FakeExecutorService extends ExecutorService {
  _FakeExecutorService(
    String identifier,
    int maxConcurrency,
    // ignore: avoid_positional_boolean_parameters
    bool allowCleanup,
    List<Executor> executors, [
    this.onCreateExecutor,
  ]) : super(
          identifier,
          maxConcurrency,
          releaseUnusedExecutors: allowCleanup,
          availableExecutors: executors,
        );

  final Executor Function(OnTaskCompleted callback) onCreateExecutor;

  @override
  Executor createExecutor(final OnTaskCompleted onTaskCompleted) =>
      onCreateExecutor != null
          ? onCreateExecutor(onTaskCompleted)
          : MockExecutor(0);
}
