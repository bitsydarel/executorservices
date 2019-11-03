import "package:executorservices/executorservices.dart";
import "package:http/http.dart" as http;

import "utils.dart";

void main() {
  final executorService = ExecutorService.newComputationExecutor();

  executorService.subscribeToCallable(streamRandomInts, 5).listen(
        (number) => printRunningIsolate("streamRandomInts:onData=$number"),
        onError: (error) =>
            printRunningIsolate("streamRandomInts:onError=$error"),
        onDone: () => printRunningIsolate("streamRandomInts:onDone"),
      );

  executorService.subscribeToFunction2(failAtCount, 10, 7).listen(
        (number) => printRunningIsolate("failAtCount:onData=$number"),
        onError: (error) => printRunningIsolate("failAtCount:onError=$error"),
        onDone: () => printRunningIsolate("failAtCount:onDone"),
      );

  executorService
      .subscribe(
        _LocalMethodExample(10),
      )
      .listen(
        (number) => printRunningIsolate("_LocalMethodExample:onData=$number"),
        onError: (error) => printRunningIsolate(
          "_LocalMethodExample:onError=$error",
        ),
        onDone: () => printRunningIsolate("_LocalMethodExample:onDone"),
      );
}

class _LocalMethodExample extends SubscribableTask<String> {
  _LocalMethodExample(this.postCount);

  final int postCount;

  @override
  Stream<String> execute() async* {
    for (var index = 0; index < 10; index++) {
      final post = await http.get(
        "https://jsonplaceholder.typicode.com/posts/$index",
      );

      printRunningIsolate("_LocalMethodExample:inside$index:${post.body}");

      yield post.body;
    }
  }
}

Stream<int> streamRandomInts(final int howManyEvents) async* {
  for (var i = 0; i <= howManyEvents; i++) {
    printRunningIsolate("streamRandomInts:inside");

    await Future.delayed(Duration(seconds: 1));

    yield i;
  }
}

Stream<String> failAtCount(
  final int howManyEvents,
  final int failPoint,
) async* {
  for (var i = 0; i <= howManyEvents; i++) {
    printRunningIsolate("failAtCount:inside");

    await Future.delayed(Duration(seconds: 1));

    assert(i != failPoint, "fail point reached");

    yield "${failPoint - i} until fail";
  }
}
