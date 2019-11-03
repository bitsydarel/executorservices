import "package:executorservices/executorservices.dart";

import "utils.dart";

void main() {
  final executorService = ExecutorService.newComputationExecutor();

  final cancelExample = executorService
      .subscribeToAction(
        manageableTimedCounter,
      )
      .listen(
        (number) => printRunningIsolate("timedCounter:cancel:onData=$number"),
        onError: (error) => printRunningIsolate(
          "timedCounter:cancel:onError=$error",
        ),
        onDone: () => printRunningIsolate("timedCounter:cancel:onDone"),
      );

  Future.delayed(Duration(seconds: 5), cancelExample.cancel);

  final pauseSubscription = executorService
      .subscribeToAction(
        manageableTimedCounter,
      )
      .listen(
        (number) => printRunningIsolate("timedCounter:pause:onData=$number"),
        onError: (error) => printRunningIsolate(
          "timedCounter:pause:onError=$error",
        ),
        onDone: () => printRunningIsolate("timedCounter:pause:onDone"),
      );

  Future.delayed(Duration(seconds: 5), () async {
    pauseSubscription.pause();
    await Future.delayed(Duration(seconds: 1));
    assert(pauseSubscription.isPaused, "should be in paused state");
    await pauseSubscription.cancel();
  });

  final resumeSubscription = executorService
      .subscribeToAction(
        manageableTimedCounter,
      )
      .listen(
        (number) => printRunningIsolate("timedCounter:resume:onData=$number"),
        onError: (error) => printRunningIsolate(
          "timedCounter:resume:onError=$error",
        ),
        onDone: () => printRunningIsolate("timedCounter:resume:onDone"),
      );

  Future.delayed(Duration(seconds: 5), () async {
    resumeSubscription.pause();
    await Future.delayed(Duration(seconds: 1));
    assert(resumeSubscription.isPaused, "should be in paused state");

    resumeSubscription.resume();

    await Future.delayed(Duration(seconds: 1));
    assert(!resumeSubscription.isPaused, "should be in resumed state");
    await resumeSubscription.cancel();
  });
}

Stream<int> manageableTimedCounter([int maxCount]) async* {
  var i = 0;

  while (maxCount != i) {
    printRunningIsolate("timedCounter:inside:$i");

    await Future.delayed(Duration(seconds: 1));

    yield i++;
  }
}
