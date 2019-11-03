import "dart:async";
import "dart:collection";

import "package:executorservices/src/task_manager.dart";
import "package:executorservices/src/tasks/task_event.dart";
import "package:executorservices/src/tasks/task_tracker.dart";
import "package:mockito/mockito.dart";
import "package:test/test.dart";

import "test_utils.dart";

void main() {
  test(
    "Should throw a error if the task manager "
    "contains a task and the task can't be cloned",
    () {
      final task = FakeDelayingTask(Duration(milliseconds: 500));
      final tracker = SubscribableTaskTracker();

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{task.identifier: tracker},
        Queue(),
        StreamController(),
        null,
      );

      expect(
        () => taskManager.handle(TaskRequest(task, tracker)),
        throwsUnsupportedError,
      );

      expect(taskManager.getInProgressTasks(), hasLength(1));
    },
  );

  test(
    "Should add the task to the queue if "
    "there's no executor available to execute it",
    () async {
      final task = CleanableFakeDelayingTask(Duration(milliseconds: 500));

      Future<SubmittedTaskEvent> onTaskRegistered(TaskRequest request) {
        return Future.value(SubmittedTaskEvent(task, null));
      }

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{},
        Queue(),
        StreamController<TaskRequest>(sync: true),
        onTaskRegistered,
      );

      expect(taskManager.getPendingTasks(), isEmpty);

      taskManager.handle(TaskRequest(task, TaskTracker()));

      // we have to wait because the current implementation of
      // task manager use a stream to handle task request events
      // and keep them ordered. So to avoid having test failing because of
      // dart event loop not processing the stream event, even when we specified
      // sync to true.
      await Future.delayed(Duration(milliseconds: 500));

      expect(taskManager.getPendingTasks(), hasLength(1));

      expect(taskManager.getPendingTasks().first, equals(task));
    },
  );

  test(
    "Should execute the task if there's a executor available to execute it",
    () async {
      final task = CleanableFakeDelayingTask(Duration(milliseconds: 500));
      final mockExecutor = MockExecutor(0);

      Future<SubmittedTaskEvent> onTaskRegistered(TaskRequest request) {
        return Future.value(SubmittedTaskEvent(task, mockExecutor));
      }

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{},
        Queue(),
        StreamController(sync: true),
        onTaskRegistered,
      );

      expect(taskManager.getPendingTasks(), isEmpty);

      taskManager.handle(TaskRequest(task, TaskTracker()));

      // we have to wait because the current implementation of
      // task manager use a stream to handle task request events
      // and keep them ordered. So to avoid having test failing because of
      // dart event loop not processing the stream event, even when we specified
      // sync to true.
      await Future.delayed(Duration(milliseconds: 500));

      expect(taskManager.getPendingTasks(), isEmpty);

      verify(mockExecutor.execute(task)).called(1);
    },
  );

  test(
    "Should dispose task manager if dispose is called",
    () async {
      final task = CleanableFakeDelayingTask(Duration(milliseconds: 500));

      Future<SubmittedTaskEvent> onTaskRegistered(TaskRequest request) {
        return Future.value(SubmittedTaskEvent(task, null));
      }

      final taskHandler = StreamController<TaskRequest>();

      final taskManager = TaskManager.private(
        <Object, BaseTaskTracker>{},
        Queue(),
        // some would say that using the sync parameter
        // would make the streamController synchronous but nope...
        taskHandler,
        onTaskRegistered,
      );

      expect(taskManager.getPendingTasks(), isEmpty);

      for (var i = 0; i < 10; i++) {
        taskManager.handle(TaskRequest(task, TaskTracker()));
      }

      // we have to wait because the current implementation of
      // task manager use a stream to handle task request events
      // and keep them ordered. So to avoid having test failing because of
      // dart event loop not processing the stream event, even when we specified
      // sync to true.
      await Future.delayed(Duration(milliseconds: 500));

      expect(taskManager.getPendingTasks(), isNotEmpty);

      expect(taskManager.getInProgressTasks(), isNotEmpty);

      expect(taskManager.dispose(), completes);

      expect(taskHandler.isClosed, isTrue);

      expect(taskManager.getPendingTasks(), isEmpty);

      expect(taskManager.getInProgressTasks(), isEmpty);
    },
  );
}
