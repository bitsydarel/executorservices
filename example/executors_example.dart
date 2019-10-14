import "dart:io";
import "dart:isolate";
import "dart:math" as math;

import "package:executorservices/executorservices.dart";
import "package:http/http.dart" as http;

void main() async {
  printRunningIsolate("main");

  final executorService = ExecutorService.newIOExecutorService();

  final subClassVersionResult = await executorService.submit(
    GetJsonFromUrlTask("https://jsonplaceholder.typicode.com/posts/1"),
  );

  printRunningIsolate("main:GetJsonFromUrlTask:result");

  print(subClassVersionResult);

  await executorService.submitAction(
    _functionWithoutArgument,
  );

  print("main:_functionWithoutArgument:done");

  final functionWithOneArgumentResult = await executorService.submitCallable(
    functionWithOneArgument,
    10,
  );

  print("main:functionWithOneArgument:result:$functionWithOneArgumentResult");
}

void _functionWithoutArgument() {
  printRunningIsolate("_functionWithoutArgument:enter");
  sleep(Duration(seconds: 5));
  printRunningIsolate("_functionWithoutArgument:exit");
}

Future<int> functionWithOneArgument(final int max) async {
  printRunningIsolate("functionWithOneArgument:enter");
  await Future.delayed(Duration(seconds: 3));
  printRunningIsolate("functionWithOneArgument:exit");
  return math.Random.secure().nextInt(max);
}

class GetJsonFromUrlTask extends Task<String> {
  GetJsonFromUrlTask(this.url);

  final String url;

  @override
  Future<String> execute() {
    return http.get(url).then((response) {
      printRunningIsolate(url);
      return response.body;
    });
  }
}

void printRunningIsolate(final String tag) {
  print("Running $tag in isolate: ${Isolate.current.debugName}");
}
