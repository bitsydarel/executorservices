import "../executorservices.dart";

/// A [Exception] that's thrown when a [ExecutorService]
/// is shutting down but client keep submitting work to it.
class TaskRejectedException implements Exception {
  /// Create a [TaskRejectedException] with the following [service].
  const TaskRejectedException(this.service);

  /// [ExecutorService] that trowed the [TaskRejectedException].
  final ExecutorService service;

  @override
  String toString() => "Task can't be submitted because "
      "[${service.runtimeType}:${service.identifier}]"
      " is shutting down";
}

/// A [Exception] that's thrown when a [Task] failed with a exception.
///
/// Why having a custom [Exception] ?
///
/// Because in platform supporting isolate sendPort send method
/// does not accept object that are not from the same code and in the same
/// process unless they are primitive.
class TaskFailedException implements Exception {
  /// [TaskFailedException] for the following [errorType] and [errorMessage].
  const TaskFailedException(this.errorType, this.errorMessage);

  /// The type of the error that was thrown.
  final Type errorType;

  /// Message describing the error.
  final String errorMessage;

  @override
  String toString() => "Task failed with $errorType because $errorMessage";
}
