import 'dart:math';
import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

Future<void> main() async {
  test("_fibonacci calculation", () async {
    final time1 = DateTime.now();
    final _ = [_fib(40), _fib(40), _fib(40), _fib(40)];
    final timeSpend1 = DateTime.now().difference(time1).inMilliseconds;
    final time2 = DateTime.now();
    final results = [
      workerManager.execute(() => _fib(40)),
      workerManager.execute(() => _fib(40)),
      workerManager.execute(() => _fib(40)),
      workerManager.execute(() => _fib(40)),
    ];
    await Future.wait(results);
    final timeSpend2 = DateTime.now().difference(time2).inMilliseconds;
    expect(timeSpend1 > timeSpend2, true);
  });

  test("matrix multiplication", () async {
    final time1 = DateTime.now();
    _multiplyMatrix();
    _multiplyMatrix();
    _multiplyMatrix();
    final timeSpend1 = DateTime.now().difference(time1).inMilliseconds;

    final time2 = DateTime.now();
    final results = [
      workerManager.execute(() => _multiplyMatrix()),
      workerManager.execute(() => _multiplyMatrix()),
      workerManager.execute(() => _multiplyMatrix()),
    ];
    await Future.wait(results);
    final timeSpend2 = DateTime.now().difference(time2).inMilliseconds;
    expect(timeSpend1 > timeSpend2, true);
  });
}

int _fib(int n) {
  if (n < 2) {
    return n;
  }
  return _fib(n - 2) + _fib(n - 1);
}

void _multiplyMatrix() {
  int size = 1000;
  final random = Random();

  List<List<double>> matrix1 = List.generate(
    size,
    (_) => List.generate(size, (_) => random.nextDouble()),
  );
  List<List<double>> matrix2 = List.generate(
    size,
    (_) => List.generate(size, (_) => random.nextDouble()),
  );

  final result = List.generate(size, (_) => List.filled(size, 0.0));
  for (int i = 0; i < size; i++) {
    for (int j = 0; j < size; j++) {
      double sum = 0.0;
      for (int k = 0; k < size; k++) {
        sum += matrix1[i][k] * matrix2[k][j];
      }
      result[i][j] = sum;
    }
  }
}