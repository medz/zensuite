// ignore_for_file: avoid_print

import 'dart:async';

import 'package:zenbus/src/bus.dart';

/// Define your implementations here - just add name and constructor
final List<ZenBusImplementation<int>> implementations = [
  ZenBusImplementation('Stream', ZenBus.stream),
  ZenBusImplementation('Alien Signal', ZenBus.alienSignals),
];

/// Implementation definition - name + no-param constructor
class ZenBusImplementation<T> {
  final String name;
  final ZenBus<T> Function() create;

  ZenBusImplementation(this.name, this.create);
}

/// Benchmark result for a single test
class BenchmarkResult {
  final String implName;
  final String testName;
  final Duration duration;
  final int operations;

  BenchmarkResult({
    required this.implName,
    required this.testName,
    required this.duration,
    required this.operations,
  });

  double get operationsPerSecond =>
      operations / duration.inMicroseconds * 1000000;

  String get fullName => '$implName - $testName';

  @override
  String toString() {
    return '$fullName: ${duration.inMicroseconds}µs for $operations ops (${operationsPerSecond.toStringAsFixed(2)} ops/s)';
  }
}

/// Benchmark configuration
class BenchmarkConfig {
  final int warmupIterations;
  final int iterations;

  const BenchmarkConfig({
    this.warmupIterations = 100,
    this.iterations = 10000,
  });
}

/// Individual benchmark test definition
typedef BenchmarkTest<T> = Future<void> Function(ZenBus<T> bus);

/// Benchmark test suite
class ZenBusBenchmarkSuite<T> {
  final List<ZenBusImplementation<T>> implementations;
  final BenchmarkConfig config;
  final List<BenchmarkResult> results = [];

  ZenBusBenchmarkSuite(this.implementations, {this.config = const BenchmarkConfig()});

  /// Run a single benchmark
  Future<BenchmarkResult> _runBenchmark(
    String implName,
    String testName,
    Future<void> Function() benchmark,
  ) async {
    // Warmup
    for (int i = 0; i < config.warmupIterations; i++) {
      await benchmark();
    }

    // Actual benchmark
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < config.iterations; i++) {
      await benchmark();
    }
    stopwatch.stop();

    return BenchmarkResult(
      implName: implName,
      testName: testName,
      duration: stopwatch.elapsed,
      operations: config.iterations,
    );
  }

  /// Run a test across all implementations
  Future<void> runTest(
    String testName,
    Future<void> Function(ZenBus<T> bus) setup,
    Future<void> Function(ZenBus<T> bus) test,
    Future<void> Function(ZenBus<T> bus) teardown,
  ) async {
    print('  📌 $testName');
    for (final impl in implementations) {
      final bus = impl.create();
      await setup(bus);
      final result = await _runBenchmark(
        impl.name,
        testName,
        () => test(bus),
      );
      await teardown(bus);
      results.add(result);
    }
  }

  /// Fire performance (no listeners)
  Future<void> benchmarkFire() async {
    await runTest(
      'fire (no listeners)',
      (_) async {},
      (bus) async => bus.fire(42 as T),
      (_) async {},
    );
  }

  /// Listen/subscribe performance
  Future<void> benchmarkListen() async {
    for (final impl in implementations) {
      print('  📌 listen/subscribe');
      final result = await _runBenchmark(
        impl.name,
        'listen/subscribe',
        () async {
          final bus = impl.create();
          final sub = bus.listen((event) {});
          sub.cancel();
        },
      );
      results.add(result);
    }
  }

  /// Fire with single listener
  Future<void> benchmarkFireWithListener() async {
    late ZenBusSubscription<T> sub;
    await runTest(
      'fire (1 listener)',
      (bus) async => sub = bus.listen((event) {}),
      (bus) async => bus.fire(42 as T),
      (_) async => sub.cancel(),
    );
  }

  /// Fire with multiple listeners
  Future<void> benchmarkFireWithListeners(int count) async {
    final subs = <ZenBusSubscription<T>>[];
    await runTest(
      'fire ($count listeners)',
      (bus) async {
        for (int i = 0; i < count; i++) {
          subs.add(bus.listen((event) {}));
        }
      },
      (bus) async => bus.fire(42 as T),
      (_) async {
        for (final sub in subs) {
          sub.cancel();
        }
        subs.clear();
      },
    );
  }

  /// Fire with filter
  Future<void> benchmarkFireWithFilter() async {
    late ZenBusSubscription<T> sub;
    await runTest(
      'fire (with filter)',
      (bus) async => sub = bus.listen(
        (event) {},
        where: (event) => true,
      ),
      (bus) async => bus.fire(42 as T),
      (_) async => sub.cancel(),
    );
  }

  /// Run all benchmarks
  Future<void> runAll() async {
    print('\n1️⃣  Fire performance (no listeners)');
    await benchmarkFire();

    print('\n2️⃣  Listen/subscribe performance');
    await benchmarkListen();

    print('\n3️⃣  Fire with single listener');
    await benchmarkFireWithListener();

    print('\n4️⃣  Fire with 10 listeners');
    await benchmarkFireWithListeners(10);

    print('\n5️⃣  Fire with 100 listeners');
    await benchmarkFireWithListeners(100);

    print('\n6️⃣  Fire with filter');
    await benchmarkFireWithFilter();
  }

  /// Print results summary
  void printSummary() {
    print('');
    print('=' * 70);
    print('📈 RESULTS SUMMARY');
    print('=' * 70);
    print('');

    for (final result in results) {
      print(result);
    }
  }

  /// Print comparison table
  void printComparisonTable() {
    print('');
    print('=' * 70);
    print('📊 COMPARISON TABLE');
    print('=' * 70);
    print('');

    // Get unique test names
    final testNames = results.map((r) => r.testName).toSet().toList();

    // Build header
    final implNames = implementations.map((i) => i.name).toList();
    final header = ['Test', ...implNames.map((n) => '$n (ops/s)'), 'Winner'].join(' | ');
    final separator = header.split('|').map((s) => '-' * s.length).join('|');

    print('| $header |');
    print('|$separator|');

    // Build rows
    for (final testName in testNames) {
      final testResults = results.where((r) => r.testName == testName).toList();
      
      // Find winner
      BenchmarkResult? winner;
      for (final result in testResults) {
        if (winner == null || result.operationsPerSecond > winner.operationsPerSecond) {
          winner = result;
        }
      }

      // Calculate ratio
      final secondBest = testResults
          .where((r) => r != winner)
          .reduce((a, b) => a.operationsPerSecond > b.operationsPerSecond ? a : b);
      final ratio = winner!.operationsPerSecond / secondBest.operationsPerSecond;

      // Build row
      final row = [
        testName,
        ...implNames.map((name) {
          final result = testResults.firstWhere((r) => r.implName == name);
          return result.operationsPerSecond.toStringAsFixed(0);
        }),
        '${winner.implName} (${ratio.toStringAsFixed(2)}x)',
      ].join(' | ');

      print('| $row |');
    }
  }
}

Future<void> main() async {
  print('=' * 70);
  print('ZenBus Benchmark: Comparing ${implementations.length} Implementations');
  print('Implementations: ${implementations.map((i) => i.name).join(', ')}');
  print('=' * 70);

  final suite = ZenBusBenchmarkSuite<int>(implementations);

  print('\n📊 Running performance benchmarks...');
  await suite.runAll();

  suite.printSummary();
  suite.printComparisonTable();

  print('');
  print('✅ Benchmark complete!');
  print('');
  print('💡 For memory benchmarks, run:');
  print('   ./benchmark/run_memory_benchmarks.sh');
}
