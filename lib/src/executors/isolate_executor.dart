import "dart:async";
import "dart:isolate";

import "package:executorservices/executorservices.dart";
import 'package:executorservices/src/tasks/tasks.dart';

/// [Executor] that execute [Task] into a isolate.
class IsolateExecutor extends Executor {
  /// Create an [IsolateExecutor] with the specified [identifier].
  IsolateExecutor(
    this.identifier,
    OnTaskCompleted taskCompletion,
  ) : super(taskCompletion);

  /// The identifier of the [IsolateExecutor].
  final String identifier;

  /// The isolate that's will execute [Task] in a isolated environment.
  Isolate _isolate;

  /// The port to send command to the [_isolate].
  SendPort _isolateCommandPort;

  /// The port that will receive the [_isolate].
  ReceivePort _isolateOutputPort;

  /// The subscription to the [_isolateOutputPort] event stream.
  StreamSubscription _outputSubscription;

  var _processingTask = false;

  @override
  void execute<R>(Task task) async {
    if (_isolate == null) {
      await _initialize();
    }
    _processingTask = true;
    _isolateCommandPort.send(task);
  }

  @override
  FutureOr<bool> isBusy() => _isolate != null && _processingTask;

  Future<void> _initialize() async {
    _isolateOutputPort = ReceivePort();

    _isolate = await Isolate.spawn(
      IsolateExecutor._isolateSetup,
      _isolateOutputPort.sendPort,
      debugName: identifier,
      errorsAreFatal: false,
    );

    final outputEvent = _isolateOutputPort.asBroadcastStream();

    // We wait for the first output before listening to the other output event
    // The first output is the isolate command port.
    _isolateCommandPort = await outputEvent.first;

    _outputSubscription = outputEvent.listen(
      (event) {
        if (event is TaskOutput) {
          _processingTask = false;
          onTaskCompleted(event, this);
        }
      },
    );
  }

  @override
  Future<void> kill() async {
    await _outputSubscription?.cancel();
    _isolate?.kill(priority: Isolate.immediate);
    _isolateOutputPort?.close();
  }

  static void _isolateSetup(final SendPort executorOutputPort) async {
    // The isolate's command port
    final isolateCommandPort = ReceivePort();

    // Send the isolate command port as first event.
    executorOutputPort.send(isolateCommandPort.sendPort);

    /// Iterate through all the event received in the isolate command port.
    await for (final Task task in isolateCommandPort) {
      try {
        final result = await task.execute();
        executorOutputPort.send(SuccessTaskOutput(task.identifier, result));
      } on Object catch (error) {
        final taskError = TaskFailedException(
          error.runtimeType,
          error.toString(),
        );

        executorOutputPort.send(FailedTaskOutput(task.identifier, taskError));
      }
    }
  }
}
