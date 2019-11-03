import "dart:async";
import "dart:math";

import "package:executorservices/executorservices.dart";
import "package:http/http.dart" as http;

import "utils.dart";

void main() {
  final executorService = ExecutorService.newSingleExecutor();

  executorService
      .submit(
        GetJsonFromUrlTask("https://jsonplaceholder.typicode.com/posts/1"),
      )
      .then((data) => printRunningIsolate("GetJsonFromUrlTask:result\n$data"));

  executorService
      .submitAction(onShotFunction)
      .then((_) => printRunningIsolate("onShotFunction:done"));

  executorService.submitCallable(getRandomNumber, 10).then(
        (number) => printRunningIsolate(
          "getRandomNumber:result:$number",
        ),
      );

  executorService.submitCallable(getRandomNumberSync, 1000000).then(
        (number) => printRunningIsolate(
          "getRandomNumberSync:result:$number",
        ),
      );

  executorService
      .submitFunction2(getFullName, "Darel", "Bitsy")
      .then((result) => printRunningIsolate("getFullName:result:$result"));

  executorService
      .submitFunction3(greet, "Darel", "Bitsy", "bdeg")
      .then((result) => printRunningIsolate("greet:result:$result"));

  executorService.subscribeToAction(getPosts).listen(
        (number) => print("event received: $number"),
        onError: (error) => print("error received $error"),
        onDone: () => print("task is done"),
      );
}

Stream<String> getPosts() async* {
  for (var index = 0; index < 10; index++) {
    final post = await http.get(
      "https://jsonplaceholder.typicode.com/posts/$index",
    );

    yield post.body;
  }
}

void onShotFunction() async {
  printRunningIsolate("onShotFunction:enter");
  await Future.delayed(Duration(seconds: 3));
}

Future<int> getRandomNumber(final int max) async {
  printRunningIsolate("getRandomNumber:enter");
  await Future.delayed(Duration(seconds: 2));
  return Random.secure().nextInt(max);
}

int getRandomNumberSync(final int max) {
  printRunningIsolate("getRandomNumber:enter");
  return Random.secure().nextInt(max);
}

Future<String> getFullName(final String firstName, final String lastName) {
  printRunningIsolate("getRandomNumber");
  return Future.delayed(Duration(seconds: 1))
      .then((_) => "$firstName $lastName");
}

Future<String> greet(
  final String firstName,
  final String lastName,
  final String surname,
) {
  printRunningIsolate("greet");
  return Future.delayed(Duration(seconds: 2))
      .then((_) => "Hello $firstName $lastName $surname");
}

class GetJsonFromUrlTask extends Task<String> {
  GetJsonFromUrlTask(this.url);

  final String url;

  @override
  FutureOr<String> execute() {
    return http.get(url).then((response) {
      printRunningIsolate(url);
      return response.body;
    });
  }
}
