import "dart:async";

import "package:executorservices/executorservices.dart";

/// Base class for define a the result of a [BaseTask].
///
/// Note: the [BaseTaskTracker] is not bounded to the [BaseTask] id
/// because we support task cloning so the completer need to be reusable.
abstract class BaseTaskTracker<R> {
  /// Get the object allowing to follow the progress of a [BaseTask].
  R progress();

  /// Complete the [BaseTask] with [exception].
  void completeWithError(TaskFailedException exception);
}

/// A [BaseTaskTracker] subclass that follow process of a [Task].
class TaskTracker<R> extends BaseTaskTracker<Future<R>> {
  final Completer<R> _completer = Completer();

  @override
  Future<R> progress() => _completer.future;

  /// Complete the [Task] with the [result].
  void complete(final R result) => _completer.complete(result);

  @override
  void completeWithError(final TaskFailedException exception) {
    _completer.completeError(exception);
  }
}

/// A [BaseTaskTracker] subclass that allow
/// to follow process of a [SubscribableTask].
class SubscribableTaskTracker<R> extends BaseTaskTracker<Stream<R>> {
  /// Create [SubscribableTaskTracker].
  SubscribableTaskTracker() : _streamController = StreamController();

  final StreamController<R> _streamController;

  @override
  Stream<R> progress() => _streamController.stream;

  /// Add a new [event] to the [SubscribableTask].
  void addEvent(final R event) => _streamController.add(event);

  // ignore: use_setters_to_change_properties
  /// Set cancellation callback to [onCancelCallback].
  void setCancellationCallback(void Function() onCancelCallback) {
    _streamController.onCancel = onCancelCallback;
  }

  // ignore: use_setters_to_change_properties
  /// Set the on pause callback to [onPauseCallback].
  void setPauseCallback(void Function() onPauseCallback) {
    _streamController.onPause = onPauseCallback;
  }

  // ignore: use_setters_to_change_properties
  /// Set the on pause callback to [onResumeCallback].
  void setResumeCallback(void Function() onResumeCallback) {
    _streamController.onResume = onResumeCallback;
  }

  /// Complete the [SubscribableTask].
  void complete() async {
    // because the close method also call the cancel
    // method to cancel any ongoing subscription
    // we need to set it to null to avoid recalling the onCancel.
    _streamController.onCancel = null;
    return await _streamController.close();
  }

  @override
  void completeWithError(TaskFailedException exception) {
    _streamController.addError(exception);
  }
}
