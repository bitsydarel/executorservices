import "dart:io";
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

  executorService
      .submitFunction2(getFullName, "Darel", "Bitsy")
      .then((result) => printRunningIsolate("getFullName:result:$result"));

  executorService
      .submitFunction3(greet, "Darel", "Bitsy", "bdeg")
      .then((result) => printRunningIsolate("greet:result:$result"));
}

void onShotFunction() {
  printRunningIsolate("onShotFunction:enter");
  sleep(Duration(seconds: 3));
}

Future<int> getRandomNumber(final int max) async {
  printRunningIsolate("getRandomNumber:enter");
  await Future.delayed(Duration(seconds: 2));
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
  Future<String> execute() {
    return http.get(url).then((response) {
      printRunningIsolate(url);
      return response.body;
    });
  }
}
