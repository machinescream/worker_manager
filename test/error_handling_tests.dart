import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

void errorHandlingTests() {
  test("error handling from 0 to 1 level", () async {
    final result = await workerManager
        .execute(() => throw Error())
        .thenNext((value) => 0, (error) => error);
    expect(result is Error, true);
  });

  test("error handling from 0 to 2 level", () async {
    final result = await workerManager
        .execute(() => throw Error())
        .thenNext((value) => value)
        .thenNext((value) => value, (error) => error);
    expect(result is Error, true);
  });

  test("error handling from 1 to 1 level immediately", () async {
    final result = await workerManager
        .execute(() => 0)
        .thenNext((value) => throw Error(), (error) => error);
    expect(result is Error, true);
  });

  test("error handling from 1 to 2 level", () async {
    final result = await workerManager
        .execute(() => 0)
        .thenNext((value) => throw Error())
        .thenNext((value) => value, (error) => error);
    expect(result is Error, true);
  });
}
