import 'dart:async';
import "dart:math";

import "package:executorservices/executorservices.dart";
import 'package:executorservices/src/tasks/task_output.dart';
import "package:mockito/mockito.dart";

class MockExecutor extends Mock implements Executor {
  MockExecutor(this.id);

  final int id;

  @override
  String toString() => "MockExecutor$id";
}

class CleanableFakeDelayingTask extends FakeDelayingTask {
  CleanableFakeDelayingTask([Duration delay]) : super(delay);

  @override
  CleanableFakeDelayingTask clone() =>
      CleanableFakeDelayingTask(delaySimulationTime);
}

class FakeDelayingTask extends Task<int> {
  FakeDelayingTask([Duration delay])
      : delaySimulationTime = delay ?? const Duration(seconds: 1);

  final Duration delaySimulationTime;

  @override
  Future<int> execute() async {
    await Future.delayed(delaySimulationTime);
    return Random.secure().nextInt(delaySimulationTime.inMilliseconds);
  }
}

class FakeFailureTask extends Task<int> {
  FakeFailureTask(this.failPoint);

  final int failPoint;

  @override
  FutureOr<int> execute() async {
    for (var index = 0; index < failPoint * 2; index++) {
      await Future.delayed(const Duration(milliseconds: 100));
      assert(index != failPoint, "Fail point reached");
    }
    return failPoint;
  }
}

class FakeSubscribableTask extends SubscribableTask<int> {
  FakeSubscribableTask(this.max);

  final int max;

  @override
  Stream<int> execute() async* {
    for (var index = 0; index < max; index++) {
      await Future.delayed(const Duration(milliseconds: 100));
      yield index;
    }
  }
}

class FakeFailureSubscribableTask extends SubscribableTask<int> {
  FakeFailureSubscribableTask(this.failPoint);

  final int failPoint;

  @override
  Stream<int> execute() async* {
    for (var index = 0; index < failPoint * 2; index++) {
      await Future.delayed(const Duration(milliseconds: 100));
      assert(index != failPoint, "Fail point reached");
      yield index;
    }
  }
}

class MockOnTaskCompleted extends Mock {
  void call(TaskOutput output, Executor executor);
}
