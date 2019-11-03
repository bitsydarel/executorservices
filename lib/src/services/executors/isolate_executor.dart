import "dart:async";
import "dart:isolate";

import "package:executorservices/executorservices.dart";
import "package:executorservices/src/tasks/task_event.dart";
import "package:executorservices/src/tasks/task_output.dart";
import "package:executorservices/src/utils/utils.dart";

/// [Executor] that execute [Task] into a isolate.
class IsolateExecutor extends Executor {
  /// Create an [IsolateExecutor] with the specified [identifier].
  IsolateExecutor(
    this.identifier,
    OnTaskCompleted taskCompletion,
  )   : assert(taskCompletion != null, "taskCompletion can't be null"),
        super(taskCompletion);

  /// The identifier of the [IsolateExecutor].
  final String identifier;

  /// The isolate that's will execute [Task] in a isolated environment.
  Isolate _isolate;

  /// The port to send command to the [_isolate].
  SendPort _isolateCommandPort;

  /// The port that will receive the [_isolate]'s responses.
  ReceivePort _isolateOutputPort;

  /// The subscription to the [_isolateOutputPort] event stream.
  StreamSubscription _outputSubscription;

  var _processingTask = false;

  DateTime _lastUsage;

  @override
  void execute<R>(BaseTask<R> task) async {
    _processingTask = true;

    if (_isolate == null) {
      await _initialize();
    }

    _isolateCommandPort.send(task);

    _lastUsage = DateTime.now();
  }

  @override
  void cancelSubscribableTask(CancelledSubscribableTaskEvent event) {
    _sendEventToIsolate(event);
  }

  @override
  void pauseSubscribableTask(PauseSubscribableTaskEvent event) {
    _sendEventToIsolate(event);
  }

  @override
  void resumeSubscribableTask(ResumeSubscribableTaskEvent event) {
    _sendEventToIsolate(event);
    // if a task have been resumed then we update the executor state.
    _processingTask = true;
  }

  @override
  bool isBusy() => _processingTask;

  @override
  Future<void> kill() async {
    await _outputSubscription?.cancel();
    _isolate?.kill(priority: Isolate.immediate);
    _isolateOutputPort?.close();
  }

  @override
  DateTime lastUsage() => _lastUsage;

  Future<void> _initialize() async {
    _isolateOutputPort = ReceivePort();

    _isolate = await Isolate.spawn(
      IsolateExecutor._isolateSetup,
      _isolateOutputPort.sendPort,
      debugName: identifier,
      errorsAreFatal: false,
    );

    // We create a multi-subscription output port.
    // This will allow us to get the first event and still listen
    // for subsequent events.
    final outputEvent = _isolateOutputPort.asBroadcastStream();

    // We wait for the first output before listening to the other output event
    // The first output is the isolate command port.
    _isolateCommandPort = await outputEvent.first;

    // Un-definitely process the event in of the outputEvent.
    // Until the subscription is cancelled or the stream is closed.
    _outputSubscription = outputEvent.listen(
      (event) {
        if (event is TaskOutput) {
          // if the output is final or
          if (event is SuccessTaskOutput ||
              event is FailedTaskOutput ||
              event is SubscribableTaskCancelled ||
              event is SubscribableTaskDone) {
            _processingTask = false;
          } else {
            _processingTask = true;
          }
          onTaskCompleted(event, this);
          _lastUsage = DateTime.now();
        }
      },
    );
  }

  void _sendEventToIsolate(dynamic event) {
    assert(
      _isolate != null,
      "subscribable task pause requested but isolate is null. "
      "This is a bug please report",
    );

    _isolateCommandPort.send(event);

    _lastUsage = DateTime.now();
  }

  static void _isolateSetup(final SendPort executorOutputPort) async {
    // The isolate's command port
    final isolateCommandPort = ReceivePort();

    // Send the isolate command port as first event.
    executorOutputPort.send(isolateCommandPort.sendPort);

    // the in progress subscribable tasks.
    // allow us to keep track of the subscription to every subscribe task
    // so we can cancel them.
    final inProgressSubscriptions = <Object, StreamSubscription>{};

    // Iterate through all the event received in the isolate command port.
    await for (final message in isolateCommandPort) {
      try {
        if (message is Task) {
          final intermediary = message.execute();
          // Notify that the task has succeeded.
          executorOutputPort.send(
            SuccessTaskOutput(
              message.identifier,
              intermediary is Future ? await intermediary : intermediary,
            ),
          );
        } else if (message is SubscribableTask) {
          _handleSubscribableTask(
            message,
            executorOutputPort,
            inProgressSubscriptions,
          );
        } else if (message is CancelledSubscribableTaskEvent) {
          await cleanupSubscription(
            message.taskIdentifier,
            inProgressSubscriptions,
          );
          // Notify that the task has been successfully cancelled.
          executorOutputPort.send(
            SubscribableTaskCancelled(message.taskIdentifier),
          );
        } else if (message is PauseSubscribableTaskEvent) {
          pauseSubscription(
            message.taskIdentifier,
            inProgressSubscriptions,
          );
        } else if (message is ResumeSubscribableTaskEvent) {
          resumeSubscription(
            message.taskIdentifier,
            inProgressSubscriptions,
          );
        } else {
          throw ArgumentError(
            "${message.runtimeType} messages are not supported,"
            " your message should extends $Task or $SubscribableTask",
          );
        }
      } on Object catch (error) {
        final taskError = TaskFailedException(
          error.runtimeType,
          error.toString(),
        );
        // Notify that the task has failed paused.
        executorOutputPort.send(
          FailedTaskOutput(message.identifier, taskError),
        );
      }
    }
  }

  static void _handleSubscribableTask(
    SubscribableTask message,
    SendPort executorOutputPort,
    Map<Object, StreamSubscription> inProgressSubscriptions,
  ) {
    final stream = message.execute();

    // Ignoring the cancellation of the subscription
    // because it's the user who control when to cancel the stream.
    // We also cancel stream when it's stream is done.
    // ignore: cancel_subscriptions
    final subscription = stream.listen(
      (event) => executorOutputPort.send(
        SubscribableTaskEvent(message.identifier, event),
      ),
      onError: (error) => executorOutputPort.send(
        SubscribableTaskError(
          message.identifier,
          TaskFailedException(error.runtimeType, error.toString()),
        ),
      ),
      onDone: () async {
        // cleanup  the subscription.
        await cleanupSubscription(message.identifier, inProgressSubscriptions);
        // notify that the subscribable task's done emitting data.
        executorOutputPort.send(
          SubscribableTaskDone(message.identifier),
        );
      },
    );

    // keep the subscription so that it's can be cancelled, paused, resumed.
    inProgressSubscriptions[message.identifier] = subscription;
  }
}
