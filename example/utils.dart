import "dart:isolate";
import "dart:math";

Future<int> concurrentFunction(final int id) async {
  printRunningIsolate("concurrentFunction:$id");
  final randomNumber = Random.secure().nextInt(5);
  await Future.delayed(
    Duration(seconds: id),
  );
  return randomNumber;
}

void printRunningIsolate(final String tag) {
  print("Running $tag in isolate: ${Isolate.current.debugName}");
}
