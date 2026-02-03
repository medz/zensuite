# ZenBus Benchmarks

This directory contains performance and memory benchmarks for ZenBus implementations.

## Quick Start

### Run Performance Benchmarks
```bash
dart run benchmark/zenbus_benchmark.dart
```

### Run Memory Benchmarks
```bash
./benchmark/run_memory_benchmarks.sh
```

## Reports

- 📊 **[Performance Benchmark Report](PERFORMANCE_BENCHMARK_REPORT.md)** - Detailed performance analysis
- 🧠 **[Memory Benchmark Report](MEMORY_BENCHMARK_REPORT.md)** - Detailed memory usage analysis

## Summary Results

### Performance Winner: 🏆 Alien Signal

| Test Scenario | Winner | Performance Advantage |
|--------------|--------|---------------------|
| Fire (no listeners) | Alien Signal | 2.24x faster |
| Listen/subscribe | Stream | 1.03x faster |
| Fire (1 listener) | Alien Signal | 1.22x faster |
| Fire (10 listeners) | Alien Signal | 1.38x faster |
| Fire (100 listeners) | Alien Signal | 1.25x faster |
| Fire (with filter) | Alien Signal | 1.44x faster |

### Memory Winner: 🏆 Alien Signal

| Test Scenario | Winner | Memory Efficiency |
|--------------|--------|------------------|
| Bus creation | Alien Signal | -562KB (GC) |
| Listener registration | Stream | 3.13KB/listener |
| Filtered listeners | Alien Signal | 3.38KB/listener |

## Overall Recommendation

**Use Alien Signal** for:
- ✅ Best overall performance (2-3x faster)
- ✅ Best memory efficiency
- ✅ Excellent scaling with many listeners
- ✅ Production applications

**Use Stream** for:
- ✅ Standard Dart patterns
- ✅ Very few listeners (< 5)
- ✅ Frequent subscription changes

**Use Signal** for:
- ✅ Reactive programming patterns
- ⚠️ Avoid if subscriptions change frequently

## Benchmark Files

### Performance Benchmarks
- `zenbus_benchmark.dart` - Main performance benchmark suite

### Memory Benchmarks (Isolated)
- `memory_bus_creation.dart` - Bus creation memory test
- `memory_listeners.dart` - Listener registration memory test
- `memory_filtered_listeners.dart` - Filtered listener memory test
- `run_memory_benchmarks.sh` - Run all memory benchmarks

## Key Findings

### Alien Signal Advantages
1. **5.46M ops/s** - Fastest event firing (no listeners)
2. **8.62M ops/s** - Fastest with 100 listeners (51x faster than Stream!)
3. **3.38KB/listener** - Excellent memory efficiency
4. **Consistent performance** - Scales linearly with listener count

### Stream Disadvantages
1. **168K ops/s** - Collapses with 100 listeners (51x slower!)
2. **18.21KB/instance** - High memory per bus instance
3. **Poor scaling** - O(n) performance degradation

### Signal Disadvantages
1. **186K ops/s** - Very slow subscription (5.92x slower than Stream)
2. **8.31KB/listener** - High memory per listener
3. **Not suitable** for frequent subscription changes

## Running Individual Tests

### Performance Test
```bash
# Run all performance tests
dart run benchmark/zenbus_benchmark.dart

# With memory benchmarks (requires --observe)
dart run --observe benchmark/zenbus_benchmark.dart
```

### Memory Tests (Isolated)
```bash
# Run all memory tests
./benchmark/run_memory_benchmarks.sh

# Or run individually
dart run --observe benchmark/memory_bus_creation.dart
dart run --observe benchmark/memory_listeners.dart
dart run --observe benchmark/memory_filtered_listeners.dart
```

## Interpreting Results

### Performance Metrics
- **ops/s** - Operations per second (higher is better)
- **µs** - Microseconds for 10,000 operations (lower is better)
- **Relative Performance** - Comparison to baseline (higher is better)

### Memory Metrics
- **Before/After** - Heap usage before and after allocation
- **Delta** - Memory increase (lower is better)
- **Per instance/listener** - Average memory per object (lower is better)
- **Negative delta** - GC occurred during measurement

## Configuration

### Performance Benchmark Config
```dart
BenchmarkConfig(
  warmupIterations: 100,    // Warmup runs
  iterations: 10000,        // Actual benchmark runs
)
```

### Memory Benchmark Config
- **Test size:** 1000 instances/listeners
- **GC delay:** 200ms between tests
- **Isolation:** Each test runs in separate process

## Notes

- Memory benchmarks require `--observe` flag
- Negative memory deltas indicate GC occurred during measurement
- Results may vary based on VM state and system load
- All tests run in isolation to prevent interference

---

**Last Updated:** 2026-02-03
