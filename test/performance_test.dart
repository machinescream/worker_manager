import 'dart:math';
import 'package:test/test.dart';
import 'package:worker_manager/worker_manager.dart';

// Actually this test shows that first jsonDecode could spend a lot of time and
// it seems like dart do some optimizations during runtime to decode faster.
Future<void> main() async {
  test("json parsing", () async {
    // final time1 = DateTime.now();
    // for (int a = 0; a < 1000; a++) {
    //   jsonDecode(_bigJsonExample);
    // }
    // final timeSpend1 = DateTime.now().difference(time1);

    // final time2 = DateTime.now();
    // await Future.wait(
    //   List.generate(
    //     1000,
    //     (index) => workerManager.execute(() => jsonDecode(_bigJsonExample)),
    //   ),
    // );
    // final timeSpend2 = DateTime.now().difference(time2);
    // expect(timeSpend1 > timeSpend2, true);
  });

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
    _multiplyMatrix();
    final timeSpend1 = DateTime.now().difference(time1).inMilliseconds;

    final time2 = DateTime.now();
    final results = [
      workerManager.execute(() => _multiplyMatrix()),
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

const _bigJsonExample = '''
{
  "values" : [
	{
		"id": "0001",
		"type": "donut",
		"name": "Cake",
		"ppu": 0.55,
		"batters":
			{
				"batter":
					[
						{ "id": "1001", "type": "Regular" },
						{ "id": "1002", "type": "Chocolate" },
						{ "id": "1003", "type": "Blueberry" },
						{ "id": "1004", "type": "Devil's Food" }
					]
			},
		"topping":
			[
				{ "id": "5001", "type": "None" },
				{ "id": "5002", "type": "Glazed" },
				{ "id": "5005", "type": "Sugar" },
				{ "id": "5007", "type": "Powdered Sugar" },
				{ "id": "5006", "type": "Chocolate with Sprinkles" },
				{ "id": "5003", "type": "Chocolate" },
				{ "id": "5004", "type": "Maple" }
			]
	},
	{
		"id": "0002",
		"type": "donut",
		"name": "Raised",
		"ppu": 0.55,
		"batters":
			{
				"batter":
					[
						{ "id": "1001", "type": "Regular" }
					]
			},
		"topping":
			[
				{ "id": "5001", "type": "None" },
				{ "id": "5002", "type": "Glazed" },
				{ "id": "5005", "type": "Sugar" },
				{ "id": "5003", "type": "Chocolate" },
				{ "id": "5004", "type": "Maple" }
			]
	},
	{
		"id": "0003",
		"type": "donut",
		"name": "Old Fashioned",
		"ppu": 0.55,
		"batters":
			{
				"batter":
					[
						{ "id": "1001", "type": "Regular" },
						{ "id": "1002", "type": "Chocolate" }
					]
			},
		"topping":
			[
				{ "id": "5001", "type": "None" },
				{ "id": "5002", "type": "Glazed" },
				{ "id": "5003", "type": "Chocolate" },
				{ "id": "5004", "type": "Maple" }
			]
	}
]
}''';
