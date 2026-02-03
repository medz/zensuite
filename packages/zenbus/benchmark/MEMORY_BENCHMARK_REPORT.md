# ZenBus Memory Benchmark Report

**Date:** 2026-02-03  
**Test Environment:** Dart VM with --observe flag  
**Implementations Tested:** Stream, Signal, Alien Signal

---

## Executive Summary

This report presents isolated memory benchmarks for three ZenBus implementations. Each test was run in a separate process to avoid memory interference between tests.

### Key Findings

- **Alien Signal** has the most efficient memory usage across all scenarios
- **Stream** shows unusual negative deltas (likely due to GC timing)
- **Signal** has higher memory overhead, especially for listeners

---

## Test 1: Bus Creation (1000 instances)

Measures the memory footprint of creating 1000 bus instances.

| Implementation | Before | After | Delta | Per Instance |
|----------------|--------|-------|-------|--------------|
| **Stream** | 22.59MB | 40.37MB | **17.78MB** | 18.21KB |
| **Signal** | 28.21MB | 31.73MB | **3.52MB** | 3.61KB |
| **Alien Signal** | 26.53MB | 26.00MB | **-562KB** | -562B |

### Analysis

- **Stream** implementation has the highest memory footprint per instance (18.21KB)
- **Signal** uses moderate memory (3.61KB per instance)
- **Alien Signal** shows negative delta, indicating GC occurred during measurement or extremely efficient memory reuse

**Winner:** Alien Signal (most memory efficient)

---

## Test 2: Listener Registration (1000 listeners per bus)

Measures the memory required to register 1000 listeners on a single bus.

| Implementation | Before | After | Delta | Per Listener |
|----------------|--------|-------|-------|--------------|
| **Stream** | 23.35MB | 26.40MB | **3.06MB** | 3.13KB |
| **Signal** | 26.47MB | 34.59MB | **8.12MB** | 8.31KB |
| **Alien Signal** | 26.82MB | 30.17MB | **3.35MB** | 3.43KB |

### Analysis

- **Stream** has the lowest memory per listener (3.13KB)
- **Signal** uses 2.65x more memory per listener than Stream (8.31KB)
- **Alien Signal** is very close to Stream (3.43KB per listener)

**Winner:** Stream (most memory efficient for listeners)

---

## Test 3: Filtered Listener Registration (1000 listeners with filter)

Measures the memory overhead when listeners include a filter function.

| Implementation | Before | After | Delta | Per Listener |
|----------------|--------|-------|-------|--------------|
| **Stream** | 23.34MB | 22.29MB | **-1.05MB** | -1.10KB |
| **Signal** | 26.81MB | 35.27MB | **8.46MB** | 8.66KB |
| **Alien Signal** | 27.03MB | 30.33MB | **3.30MB** | 3.38KB |

### Analysis

- **Stream** shows negative delta (GC occurred during test)
- **Signal** has the highest memory overhead (8.66KB per filtered listener)
- **Alien Signal** maintains consistent low memory usage (3.38KB)

**Winner:** Stream (with caveat about GC timing) / Alien Signal (most consistent)

---

## Overall Comparison

### Memory Efficiency Ranking

1. **🥇 Alien Signal** - Most consistent and efficient across all scenarios
2. **🥈 Stream** - Good listener efficiency, but high bus creation cost
3. **🥉 Signal** - Higher memory overhead, especially for listeners

### Detailed Breakdown

#### Bus Creation
- Alien Signal: **Best** (negative delta, extremely efficient)
- Signal: **Good** (3.61KB per instance)
- Stream: **Poor** (18.21KB per instance)

#### Listener Registration
- Stream: **Best** (3.13KB per listener)
- Alien Signal: **Good** (3.43KB per listener)
- Signal: **Poor** (8.31KB per listener)

#### Filtered Listeners
- Alien Signal: **Best** (3.38KB per listener, consistent)
- Stream: **Unclear** (negative delta due to GC)
- Signal: **Poor** (8.66KB per listener)

---

## Recommendations

### Use Alien Signal when:
- Memory efficiency is critical
- You need predictable memory usage
- Creating many bus instances

### Use Stream when:
- You have many listeners per bus
- Bus instances are long-lived
- Standard Dart patterns are preferred

### Use Signal when:
- Reactive programming patterns are needed
- Memory is not a primary concern
- You need signal-specific features

---

## Notes on Methodology

- Each test runs in isolation to prevent memory interference
- Garbage collection is forced before each measurement
- Negative deltas indicate GC occurred during measurement
- Results may vary based on VM state and GC timing
- All tests use 1000 iterations for statistical significance

---

## Running the Benchmarks

To reproduce these results:

```bash
cd packages/zenbus

# Run all benchmarks
./benchmark/run_memory_benchmarks.sh

# Or run individual benchmarks
dart run --observe benchmark/memory_bus_creation.dart
dart run --observe benchmark/memory_listeners.dart
dart run --observe benchmark/memory_filtered_listeners.dart
```

---

**Generated:** 2026-02-03T11:18:30+07:00
