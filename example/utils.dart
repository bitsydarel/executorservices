import "dart:isolate";
import "dart:math";

Future<int> concurrentFunction(final int id) async {
  printRunningIsolate("concurrentFunction:$id");
  final randomNumber = Random.secure().nextInt(10);
  await Future.delayed(Duration(seconds: randomNumber));
  return randomNumber;
}

Future<int> concurrentFunctionTimed(
  final int id,
  final DateTime startTime,
) async {
  printRunningIsolate("concurrentFunction:$id");
  final randomNumber = Random.secure().nextInt(10);
  await Future.delayed(Duration(seconds: randomNumber));
  print("Elapsed time: ${DateTime.now().difference(startTime)}");
  return randomNumber;
}

void printRunningIsolate(final String tag) {
  print("Running $tag in isolate: ${Isolate.current.debugName}");
}
