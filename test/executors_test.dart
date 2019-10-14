import "dart:async";

import "package:executorservices/executorservices.dart";
import "package:executorservices/src/tasks/tasks.dart";
import "package:mockito/mockito.dart";
import "package:test/test.dart";

void main() {
  test(
    "Should return the available executor if there's one that is not busy",
    () {
      final mockExecutor1 = MockExecutor();
      final mockExecutor2 = MockExecutor();

      when(mockExecutor1.isBusy()).thenAnswer((_) => false);
      when(mockExecutor2.isBusy()).thenAnswer((_) => Future.value(true));

      final executorService = _FakeExecutorService(
        "fakeexecutor",
        1,
        [mockExecutor1, mockExecutor2],
      );

      expect(
        executorService.findAvailableExecutor(),
        completion(equals(mockExecutor1)),
      );
    },
  );

  test(
    "Should return null if there's no available executor",
    () {
      final mockExecutor1 = MockExecutor();
      final mockExecutor2 = MockExecutor();

      when(mockExecutor1.isBusy()).thenAnswer((_) => true);
      when(mockExecutor2.isBusy()).thenAnswer((_) => Future.value(true));

      final executorService = _FakeExecutorService(
        "fakeexecutor",
        2,
        [mockExecutor1, mockExecutor2],
      );

      expect(
        executorService.findAvailableExecutor(),
        completion(isNull),
      );
    },
  );

  test(
    "should put the task into pending queue if there's no available executor",
    () {
      final mockExecutor1 = MockExecutor();

      when(mockExecutor1.isBusy()).thenAnswer((_) => Future.value(true));

      final executorService = _FakeExecutorService(
        "fakeexecutor",
        1,
        [mockExecutor1],
      );

      expect(executorService.getPendingTasks(), isEmpty);

      // we can't await for the result because the executor will never be
      // ready to process this task so we will wait forever.
      executorService.submitAction(() => print("should not be printe"));

      expect(
        // Workaround to wait for when the event-loop will process the
        // future task in the queue.
        // It's might make the test flaky but work as of now.
        Future.delayed(
          Duration(milliseconds: 500),
          executorService.getPendingTasks,
        ),
        completion(hasLength(1)),
      );
    },
  );

  test(
    "should execute the task if there's one available executor",
    () async {
      final mockExecutor1 = MockExecutor();

      when(mockExecutor1.isBusy()).thenAnswer((_) => Future.value(false));

      final executorService = _FakeExecutorService(
        "fakeservice",
        1,
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
      final mockExecutor1 = MockExecutor();
      final mockExecutor2 = MockExecutor();

      final executorService = _FakeExecutorService(
        "fakeservice",
        2,
        [mockExecutor1],
        (configuration) => Future.value(mockExecutor2),
      );

      when(mockExecutor1.isBusy()).thenAnswer((_) => Future.value(true));

      final task = ActionTask(() => print(""));

      // we can't await for the result because the executor will never be
      // ready to process this task so we will wait forever.
      // ignore: unawaited_futures
      executorService.submit(task);

      await Future.delayed(Duration(milliseconds: 500));

      verify(mockExecutor2.execute(task))..called(1);
    },
  );
}

class _FakeExecutorService extends ExecutorService {
  _FakeExecutorService(
    String identifier,
    int maxConcurrency,
    List<Executor> executors, [
    this.onCreateExecutor,
  ]) : super(identifier, maxConcurrency, executors);

  final Future<Executor> Function(OnTaskCompleted callback) onCreateExecutor;

  @override
  Future<Executor> createExecutor(final OnTaskCompleted onTaskCompleted) =>
      onCreateExecutor != null
          ? onCreateExecutor(onTaskCompleted)
          : Future.value(MockExecutor());
}

class MockExecutor extends Mock implements Executor {}
