import "package:executorservices/src/services/executors/isolate_executor_web.dart"
    as web_executor;
import "package:executorservices/src/tasks/task_event.dart";
import "package:executorservices/src/tasks/task_output.dart";
import "package:mockito/mockito.dart";
import "package:test/test.dart";

import "test_utils.dart";

void main() {
  group("isolate executor web state", () {
    test(
      "Should not be busy if is not executing a task",
      () {
        final mockOnTaskCompleted = MockOnTaskCompleted();

        final executor =
            web_executor.IsolateExecutor("web", mockOnTaskCompleted);

        expect(executor.isBusy(), isFalse);
      },
    );

    test("Should be busy if is executing a task", () {
      final task = FakeDelayingTask(Duration(milliseconds: 500));

      final mockOnTaskCompleted = MockOnTaskCompleted();

      final executor = web_executor.IsolateExecutor("web", mockOnTaskCompleted);

      expect(executor.isBusy(), isFalse);

      executor.execute(task);

      expect(executor.isBusy(), isTrue);
    });
  });

  group(
    "isolate executor web on task completed",
    () {
      test(
        "Should return a success output if the task succeded without error",
        () async {
          final task = FakeDelayingTask(Duration(milliseconds: 500));

          final mockOnTaskCompleted = MockOnTaskCompleted();

          final executor =
              web_executor.IsolateExecutor("web", mockOnTaskCompleted);

          expect(executor.isBusy(), isFalse);

          executor.execute(task);

          await Future.delayed(Duration(seconds: 1));

          verify(
            mockOnTaskCompleted.call(
              argThat(isA<SuccessTaskOutput>()),
              executor,
            ),
          ).called(1);

          expect(executor.isBusy(), isFalse);
        },
      );

      test(
        "Should return a failure output if the task failed with an error",
        () async {
          final task = FakeFailureTask(5);

          final mockOnTaskCompleted = MockOnTaskCompleted();

          final executor =
              web_executor.IsolateExecutor("web", mockOnTaskCompleted);

          expect(executor.isBusy(), isFalse);

          executor.execute(task);

          await Future.delayed(Duration(seconds: 1));

          verify(
            mockOnTaskCompleted.call(
              argThat(isA<FailedTaskOutput>()),
              executor,
            ),
          ).called(1);

          expect(executor.isBusy(), isFalse);
        },
      );

      test(
        "Should emit subscribable task event if the subscribable task emit it",
        () async* {
          final task = FakeSubscribableTask(5);

          final mockOnTaskCompleted = MockOnTaskCompleted();

          final executor =
              web_executor.IsolateExecutor("web", mockOnTaskCompleted);

          expect(executor.isBusy(), isFalse);

          executor.execute(task);

          await Future.delayed(Duration(seconds: 1));

          verify(
            mockOnTaskCompleted.call(
              argThat(isA<SubscribableTaskEvent>()),
              executor,
            ),
          ).called(5);
        },
      );

      test(
        "Should emit subscribable task error "
        "if the subscribable task throwed an error",
        () async {
          final task = FakeFailureSubscribableTask(5);

          final mockOnTaskCompleted = MockOnTaskCompleted();

          final executor =
              web_executor.IsolateExecutor("web", mockOnTaskCompleted);

          expect(executor.isBusy(), isFalse);

          executor.execute(task);

          await Future.delayed(Duration(seconds: 1));

          verify(
            mockOnTaskCompleted.call(
              argThat(isA<SubscribableTaskEvent>()),
              executor,
            ),
          ).called(5);

          verify(
            mockOnTaskCompleted.call(
              argThat(isA<SubscribableTaskError>()),
              executor,
            ),
          ).called(1);
        },
      );

      test(
        "Should emit subscribable task done if the task has completed",
        () async {
          final task = FakeSubscribableTask(1);

          final mockOnTaskCompleted = MockOnTaskCompleted();

          final executor =
              web_executor.IsolateExecutor("web", mockOnTaskCompleted);

          expect(executor.isBusy(), isFalse);

          executor.execute(task);

          await Future.delayed(Duration(seconds: 1));

          verify(
            mockOnTaskCompleted.call(
              argThat(isA<SubscribableTaskEvent>()),
              executor,
            ),
          ).called(1);

          verify(
            mockOnTaskCompleted.call(
              argThat(isA<SubscribableTaskDone>()),
              executor,
            ),
          ).called(1);

          expect(executor.isBusy(), isFalse);
        },
      );

      test(
        "Should emit subscribable task cancelled if the task is cancelled",
        () async {
          final task = FakeSubscribableTask(100000);

          final mockOnTaskCompleted = MockOnTaskCompleted();

          final executor =
              web_executor.IsolateExecutor("web", mockOnTaskCompleted);

          expect(executor.isBusy(), isFalse);

          executor.execute(task);

          await Future.delayed(Duration(seconds: 1));

          verifyNever(
            mockOnTaskCompleted.call(
              argThat(isA<SubscribableTaskDone>()),
              executor,
            ),
          );

          expect(executor.isBusy(), isTrue);

          executor.cancelSubscribableTask(
            CancelledSubscribableTaskEvent(task.identifier),
          );

          await Future.delayed(Duration(seconds: 1));

          verify(
            mockOnTaskCompleted.call(
              argThat(isA<SubscribableTaskCancelled>()),
              executor,
            ),
          ).called(1);

          expect(executor.isBusy(), isFalse);
        },
      );
    },
  );
}
