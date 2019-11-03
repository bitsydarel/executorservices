import "dart:async";

/// todo: update check when type aliases will be available in dart.
Object createTaskIdentifier() => throw UnsupportedError(
      "Cannot create a task identifier without dart:html or dart:io.",
    );

/// Get the cpu count on the machine.
int getCpuCount() => throw UnsupportedError(
      "Cannot get cpu count without dart:html or dart:io.",
    );

/// Cleanup a ongoing subscription to a [StreamSubscription].
Future<void> cleanupSubscription(
  final Object taskIdentifier,
  final Map<Object, StreamSubscription> inProgressSubscriptions,
) async {
  final inProgressTask = inProgressSubscriptions.remove(taskIdentifier);

  if (inProgressTask != null) {
    // cancel the in progress subscribable task subscription.
    await inProgressTask.cancel();
  } else {
    print("subscribable task cleanup requested but the task is not running");
  }
}

/// Pause a ongoing subscription to a [StreamSubscription].
void pauseSubscription(
  final Object taskIdentifier,
  final Map<Object, StreamSubscription> inProgressSubscriptions,
) {
  // ignore: cancel_subscriptions
  final inProgressTask = inProgressSubscriptions[taskIdentifier];

  if (inProgressTask != null) {
    // pause the in progress subscribable task subscription.
    inProgressTask.pause();
  } else {
    print("subscribable task pause requested but the task is not running");
  }
}

/// Resume a ongoing subscription to a [StreamSubscription].
void resumeSubscription(
  final Object taskIdentifier,
  final Map<Object, StreamSubscription> inProgressSubscriptions,
) {
  // ignore: cancel_subscriptions
  final inProgressTask = inProgressSubscriptions[taskIdentifier];

  if (inProgressTask != null) {
    // resume the in progress subscribable task subscription.
    inProgressTask.resume();
  } else {
    print("subscribable task resume requested but the task is not running");
  }
}
