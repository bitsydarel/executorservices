import "dart:collection";

import "package:executorservices/src/exceptions.dart";
import "package:executorservices/src/task_manager.dart";
import "package:executorservices/src/tasks/task_output.dart";
import "package:executorservices/src/tasks/task_tracker.dart";
import "package:mockito/mockito.dart";
import "package:test/test.dart";

import "test_utils.dart";

void main() {
  test(
    "Should notify the task tracker client when task completed with success",
    () {
      final task = FakeDelayingTask();
      final taskTracker = TaskTracker();

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{task.identifier: taskTracker},
        Queue(),
        null,
        null,
      );

      expect(taskManager.getInProgressTasks(), hasLength(1));

      final mockExecutor = MockExecutor(0);

      taskManager.onTaskOutput(
        SuccessTaskOutput(task.identifier, 100),
        mockExecutor,
      );

      expect(taskTracker.progress(), completion(equals(100)));

      expect(taskManager.getInProgressTasks(), isEmpty);
    },
  );

  test(
    "Should notify the task tracker client when task completed with a failure",
    () {
      final task = FakeDelayingTask();
      final taskTracker = TaskTracker();

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{task.identifier: taskTracker},
        Queue(),
        null,
        null,
      );

      expect(taskManager.getInProgressTasks(), hasLength(1));

      final mockExecutor = MockExecutor(0);

      taskManager.onTaskOutput(
        FailedTaskOutput(
          task.identifier,
          const TaskFailedException(NullThrownError, "fake null pointer errpr"),
        ),
        mockExecutor,
      );

      expect(
        taskTracker.progress(),
        throwsA(const TypeMatcher<TaskFailedException>()),
      );

      expect(taskManager.getInProgressTasks(), isEmpty);
    },
  );

  test(
    "Should notify the subscribable task tracker client "
    "when a subscribable task emitted a event",
    () {
      final task = FakeSubscribableTask(10);
      final taskTracker = SubscribableTaskTracker();

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{task.identifier: taskTracker},
        Queue(),
        null,
        null,
      );

      expect(taskManager.getInProgressTasks(), hasLength(1));

      final mockExecutor = MockExecutor(0);

      final eventValue = task.max / 2;

      taskManager.onTaskOutput(
        SubscribableTaskEvent(task.identifier, eventValue),
        mockExecutor,
      );

      expect(
        taskTracker.progress(),
        emits(equals(eventValue)),
      );

      expect(taskManager.getInProgressTasks(), hasLength(1));
    },
  );

  test(
    "Should notify the subscribable task tracker client "
    "when a subscribable task emitted a error",
    () {
      final task = FakeSubscribableTask(10);
      final taskTracker = SubscribableTaskTracker();

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{task.identifier: taskTracker},
        Queue(),
        null,
        null,
      );

      expect(taskManager.getInProgressTasks(), hasLength(1));

      final mockExecutor = MockExecutor(0);

      taskManager.onTaskOutput(
        SubscribableTaskError(
          task.identifier,
          const TaskFailedException(
            IntegerDivisionByZeroException,
            "fake zero division error",
          ),
        ),
        mockExecutor,
      );

      expect(
        taskTracker.progress(),
        emitsError(const TypeMatcher<TaskFailedException>()),
      );

      expect(taskManager.getInProgressTasks(), hasLength(1));
    },
  );

  test(
    "Should notify the subscribable task tracker client "
    "when a subscribable task has been cancelled",
    () {
      final task = FakeSubscribableTask(10);
      final taskTracker = SubscribableTaskTracker();

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{task.identifier: taskTracker},
        Queue(),
        null,
        null,
      );

      expect(taskManager.getInProgressTasks(), hasLength(1));

      final mockExecutor = MockExecutor(0);

      taskManager.onTaskOutput(
        SubscribableTaskCancelled(task.identifier),
        mockExecutor,
      );

      expect(
        taskTracker.progress(),
        emitsInOrder([
          neverEmits(const TypeMatcher<int>()),
          neverEmits(isNull),
          emitsDone
        ]),
      );

      expect(taskManager.getInProgressTasks(), isEmpty);
    },
  );

  test(
    "Should notify the subscribable task tracker client "
    "when a subscribable task is done emitting event",
    () {
      final task = FakeSubscribableTask(10);
      final taskTracker = SubscribableTaskTracker();

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{task.identifier: taskTracker},
        Queue(),
        null,
        null,
      );

      expect(taskManager.getInProgressTasks(), hasLength(1));

      final mockExecutor = MockExecutor(0);

      taskManager.onTaskOutput(
        SubscribableTaskDone(task.identifier),
        mockExecutor,
      );

      expect(
        taskTracker.progress(),
        emitsInOrder([
          neverEmits(const TypeMatcher<int>()),
          neverEmits(isNull),
          emitsDone
        ]),
      );

      expect(taskManager.getInProgressTasks(), isEmpty);
    },
  );

  test(
    "Should run the next pending task if there's"
    " one and the executor is not busy",
    () {
      final task = FakeSubscribableTask(10);
      final mockExecutor = MockExecutor(0);
      when(mockExecutor.isBusy()).thenReturn(false);

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{},
        Queue()..add(task),
        null,
        null,
      );

      expect(taskManager.getPendingTasks(), hasLength(1));

      taskManager.onTaskOutput(null, mockExecutor);

      expect(taskManager.getPendingTasks(), isEmpty);

      verify(mockExecutor.execute(task)).called(1);
    },
  );

  group(
    "Should not run the next pending task",
    () {
      final task = FakeSubscribableTask(10);

      test(
        "if there's a pending task but the executor is busy",
        () {
          final mockExecutor = MockExecutor(0);

          final taskManager =
              TaskManager.private(null, Queue()..add(task), null, null);

          expect(taskManager.getPendingTasks(), hasLength(1));

          when(mockExecutor.isBusy()).thenReturn(true);

          taskManager.onTaskOutput(null, mockExecutor);

          expect(taskManager.getPendingTasks(), hasLength(1));

          verifyNever(mockExecutor.execute(task));
        },
      );

      test(
        "if there's no pending tasks",
        () {
          final mockExecutor = MockExecutor(0);

          final taskManager = TaskManager.private(null, Queue(), null, null);

          expect(taskManager.getPendingTasks(), isEmpty);

          taskManager.onTaskOutput(null, mockExecutor);

          verifyZeroInteractions(mockExecutor);
        },
      );
    },
  );
}
