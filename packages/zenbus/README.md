# ZenBus

[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

A high-performance, flexible event bus for Flutter applications with multiple implementation strategies. Choose the implementation that best fits your performance requirements.

## ✨ Features

- 🚀 **Multiple Implementations** - Choose between Stream or Alien Signals based on your needs
- ⚡ **High Performance** - Up to 51x faster than traditional Stream-based implementations
- 🧠 **Memory Efficient** - Optimized memory usage with minimal overhead
- 🎯 **Type Safe** - Full Dart type safety with generics
- 🔍 **Event Filtering** - Built-in support for conditional event handling
- 📊 **Benchmarked** - Comprehensive performance and memory benchmarks included
- 🎨 **Simple API** - Clean, intuitive API that's easy to learn and use

## 📦 Installation

Add ZenBus to your `pubspec.yaml`:

```yaml
dependencies:
  zenbus: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## 🚀 Quick Start

### Basic Usage

```dart
import 'package:zenbus/zenbus.dart';

// Create a bus (choose your implementation)
final bus = ZenBus<String>.alienSignals(); // Recommended for best performance

// Listen to events
final subscription = bus.listen((event) {
  print('Received: $event');
});

// Fire events
bus.fire('Hello, ZenBus!');

// Clean up
subscription.cancel();
```

### With Event Filtering

```dart
final bus = ZenBus<int>.alienSignals();

// Only receive even numbers
final subscription = bus.listen(
  (number) => print('Even number: $number'),
  where: (number) => number % 2 == 0,
);

bus.fire(1); // Ignored
bus.fire(2); // Prints: "Even number: 2"
bus.fire(3); // Ignored
bus.fire(4); // Prints: "Even number: 4"

subscription.cancel();
```

## 🎯 Choosing an Implementation

ZenBus provides two implementations, each optimized for different scenarios:

### 1. Alien Signals (Recommended) 🏆

```dart
final bus = ZenBus<T>.alienSignals();
```

**Best for:**
- ✅ High-performance applications
- ✅ Many listeners per bus (10+)
- ✅ High event throughput
- ✅ Production applications
- ✅ Memory-constrained environments

**Performance:**
- 🚀 **5.5M ops/s** - Event firing (no listeners)
- 🚀 **8.6M ops/s** - Event firing (100 listeners)
- 🧠 **3.4KB/listener** - Memory usage
- 📈 **Excellent scaling** - Performance stays consistent with many listeners

### 2. Stream

```dart
final bus = ZenBus<T>.stream();
```

**Best for:**
- ✅ Standard Dart async patterns
- ✅ Very few listeners (< 5)
- ✅ Frequent subscription changes
- ✅ Familiarity with Dart Streams

**Performance:**
- 🐌 **1.9M ops/s** - Event firing (no listeners)
- ⚠️ **169K ops/s** - Event firing (100 listeners) - 51x slower!
- 🧠 **3.1KB/listener** - Memory usage
- ⚠️ **Poor scaling** - Performance degrades significantly with many listeners

## 📚 Usage Examples

### Example 1: Simple Event Bus

```dart
import 'package:zenbus/zenbus.dart';

void main() {
  // Create a bus for string messages
  final messageBus = ZenBus<String>.alienSignals();
  
  // Subscribe to messages
  final subscription = messageBus.listen((message) {
    print('📨 $message');
  });
  
  // Send messages
  messageBus.fire('Hello!');
  messageBus.fire('How are you?');
  
  // Clean up
  subscription.cancel();
}
```

### Example 2: Multiple Listeners

```dart
final bus = ZenBus<String>.alienSignals();

// Add multiple listeners
final sub1 = bus.listen((msg) => print('Listener 1: $msg'));
final sub2 = bus.listen((msg) => print('Listener 2: $msg'));
final sub3 = bus.listen((msg) => print('Listener 3: $msg'));

// All listeners receive the event
bus.fire('Broadcast message');
// Output:
// Listener 1: Broadcast message
// Listener 2: Broadcast message
// Listener 3: Broadcast message

// Cancel all subscriptions
sub1.cancel();
sub2.cancel();
sub3.cancel();
```

### Example 3: Typed Events

```dart
// Define your event types
class UserLoggedIn {
  final String username;
  UserLoggedIn(this.username);
}

class UserLoggedOut {
  final String username;
  UserLoggedOut(this.username);
}

// Create typed buses
final loginBus = ZenBus<UserLoggedIn>.alienSignals();
final logoutBus = ZenBus<UserLoggedOut>.alienSignals();

// Subscribe to login events
loginBus.listen((event) {
  print('👤 ${event.username} logged in');
});

// Subscribe to logout events
logoutBus.listen((event) {
  print('👋 ${event.username} logged out');
});

// Fire events
loginBus.fire(UserLoggedIn('alice'));
logoutBus.fire(UserLoggedOut('bob'));
```

### Example 4: Event Filtering

```dart
enum Priority { low, medium, high, critical }

class Task {
  final String name;
  final Priority priority;
  
  Task(this.name, this.priority);
}

final taskBus = ZenBus<Task>.alienSignals();

// Only handle critical tasks
final criticalSub = taskBus.listen(
  (task) => print('🚨 CRITICAL: ${task.name}'),
  where: (task) => task.priority == Priority.critical,
);

// Only handle high priority or above
final highPrioritySub = taskBus.listen(
  (task) => print('⚠️  HIGH: ${task.name}'),
  where: (task) => task.priority == Priority.high || 
                    task.priority == Priority.critical,
);

// Fire various tasks
taskBus.fire(Task('Update docs', Priority.low));        // No output
taskBus.fire(Task('Fix bug', Priority.medium));         // No output
taskBus.fire(Task('Security patch', Priority.high));    // ⚠️  HIGH: Security patch
taskBus.fire(Task('Server down', Priority.critical));   // 🚨 CRITICAL: Server down
                                                         // ⚠️  HIGH: Server down
```

### Example 5: Flutter Integration

```dart
import 'package:flutter/material.dart';
import 'package:zenbus/zenbus.dart';

// Global event bus
final appEventBus = ZenBus<AppEvent>.alienSignals();

abstract class AppEvent {}
class ThemeChanged extends AppEvent {
  final bool isDark;
  ThemeChanged(this.isDark);
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ZenBusSubscription<AppEvent> _subscription;
  bool _isDarkMode = false;
  
  @override
  void initState() {
    super.initState();
    
    // Listen to theme changes
    _subscription = appEventBus.listen((event) {
      event = event as ThemeChanged;
      setState(() => _isDarkMode = event.isDark);
    },
    where: (event) => event is ThemeChanged,
    );
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(),
    );
  }
}

// Somewhere in your app
ElevatedButton(
  onPressed: () {
    appEventBus.fire(ThemeChanged(true));
  },
  child: Text('Enable Dark Mode'),
);
```

## 📊 Performance Benchmarks

Comprehensive benchmarks comparing both implementations:

### Event Firing Performance

| Scenario | Stream | Alien Signals | Winner |
|----------|--------|---------------|--------|
| No listeners | 1.9M ops/s | **5.5M ops/s** | Alien Signals (2.9x) |
| 1 listener | 1.9M ops/s | **6.9M ops/s** | Alien Signals (3.6x) |
| 10 listeners | 1.3M ops/s | **7.4M ops/s** | Alien Signals (5.8x) |
| 100 listeners | 169K ops/s ⚠️ | **8.6M ops/s** | Alien Signals (51x) |
| With filter | 2.5M ops/s | **9.0M ops/s** | Alien Signals (3.5x) |

### Memory Usage

| Scenario | Stream | Alien Signals | Winner |
|----------|--------|---------------|--------|
| Bus creation (1000 instances) | 18.2KB/bus | **-562B/bus** | Alien Signals |
| Listener registration | **3.1KB/listener** | 3.4KB/listener | Stream |
| Filtered listeners | -1.1KB/listener | **3.4KB/listener** | Alien Signals |

### Run Benchmarks Yourself

```bash
cd packages/zenbus

# Performance benchmarks
dart run benchmark/zenbus_benchmark.dart

# Memory benchmarks (requires --observe flag)
./benchmark/run_memory_benchmarks.sh
```

See detailed reports:
- [Performance Benchmark Report](benchmark/PERFORMANCE_BENCHMARK_REPORT.md)
- [Memory Benchmark Report](benchmark/MEMORY_BENCHMARK_REPORT.md)

## 🎨 API Reference

### ZenBus<T>

The main event bus class.

#### Constructors

```dart
// Create a Stream-based bus
ZenBus<T>.stream()

// Create an Alien Signals-based bus (recommended)
ZenBus<T>.alienSignals()
```

#### Methods

```dart
// Fire an event to all listeners
void fire(T event)

// Subscribe to events
ZenBusSubscription<T> listen(
  void Function(T event) listener, {
  bool Function(T event)? where,
})
```

### ZenBusSubscription<T>

Represents an active subscription to a bus.

#### Methods

```dart
// Cancel the subscription
void cancel()
```

## 🤔 FAQ

### When should I use ZenBus over other event bus solutions?

Use ZenBus when:
- You need high performance event handling
- You have many listeners per event type
- You want flexibility to choose implementation strategies
- Memory efficiency is important
- You need type-safe event handling

### Which implementation should I choose?

**For most applications:** Use `ZenBus.alienSignals()` - it offers the best overall performance and memory efficiency.

**Use Stream if:**
- You have very few listeners (< 5)
- You frequently add/remove subscriptions
- You prefer standard Dart patterns

### Can I use multiple implementations in the same app?

Yes! You can mix and match implementations based on your needs:

```dart
// High-traffic bus with many listeners
final messageBus = ZenBus<Message>.alienSignals();

// Low-traffic bus with few listeners
final settingsBus = ZenBus<Settings>.stream();
```

### How do I handle errors in listeners?

Wrap your listener code in try-catch:

```dart
bus.listen((event) {
  try {
    // Your event handling code
    processEvent(event);
  } catch (e) {
    print('Error handling event: $e');
  }
});
```

### Is ZenBus thread-safe?

ZenBus follows Dart's single-threaded model. All events are fired synchronously on the same isolate. For multi-isolate communication, use Dart's `SendPort`/`ReceivePort` mechanism.

## 🛠️ Best Practices

### 1. Always Cancel Subscriptions

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late ZenBusSubscription _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = bus.listen((event) { /* ... */ });
  }
  
  @override
  void dispose() {
    _subscription.cancel(); // ✅ Always cancel!
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) => Container();
}
```

### 2. Use Type-Safe Events

```dart
// ❌ Bad: Using dynamic or Object
final bus = ZenBus<dynamic>.alienSignals();

// ✅ Good: Use specific types
final bus = ZenBus<UserEvent>.alienSignals();
```

### 3. Keep Listeners Lightweight

```dart
// ❌ Bad: Heavy processing in listener
bus.listen((event) {
  performExpensiveOperation();
  updateDatabase();
  callApi();
});

// ✅ Good: Offload heavy work
bus.listen((event) async {
  // Quick synchronous work
  updateUI();
  
  // Heavy work in background
  await Future.microtask(() {
    performExpensiveOperation();
  });
});
```

### 4. Use Filtering for Conditional Logic

```dart
// ❌ Bad: Filtering in listener
bus.listen((event) {
  if (event.priority == Priority.high) {
    handleHighPriority(event);
  }
});

// ✅ Good: Use where parameter
bus.listen(
  (event) => handleHighPriority(event),
  where: (event) => event.priority == Priority.high,
);
```

### 5. Consider Using a Service Locator

```dart
// services/event_bus_service.dart
class EventBusService {
  static final messages = ZenBus<String>.alienSignals();
  static final users = ZenBus<UserEvent>.alienSignals();
  static final navigation = ZenBus<NavigationEvent>.alienSignals();
}

// Usage
EventBusService.messages.fire('Hello!');
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [alien_signals](https://pub.dev/packages/alien_signals)
- Inspired by various event bus implementations in the Flutter ecosystem

## 📞 Support

- 🐛 [Report a bug](https://github.com/definev/zenquery/issues)
- 💡 [Request a feature](https://github.com/definev/zenquery/issues)
- 📖 [View documentation](https://github.com/definev/zenquery/tree/main/packages/zenbus)

---

Made with ❤️ by Bui Dai Duong
