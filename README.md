# ZenSuite

[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

A collection of opinionated packages for handling data flow in Flutter applications. ZenSuite provides high-performance, type-safe solutions for event-driven architecture and asynchronous state management.

## 📦 Packages

ZenSuite is a monorepo containing the following packages:

### [ZenBus](./packages/zenbus) - High-Performance Event Bus

A blazing-fast event bus implementation with multiple strategies for optimal performance.

**Key Features:**
- 🚀 Multiple implementations (Stream, Alien Signals)
- ⚡ Up to 51x faster than traditional Stream-based implementations
- 🧠 Memory efficient with minimal overhead
- 🎯 Type-safe event handling
- 🔍 Built-in event filtering

**Installation:**
```yaml
dependencies:
  zenbus: ^1.0.0
```

**Quick Example:**
```dart
import 'package:zenbus/zenbus.dart';

// Create a high-performance bus
final bus = ZenBus<String>.alienSignals();

// Listen to events
final subscription = bus.listen((event) {
  print('Received: $event');
});

// Fire events
bus.fire('Hello, ZenBus!');

// Clean up
subscription.cancel();
```

**[📖 Full Documentation](./packages/zenbus/README.md)**

---

### [ZenQuery](./packages/zenquery) - Asynchronous State Management

A powerful wrapper around Riverpod for standardized data-fetching and mutation logic, inspired by TanStack Query.

**Key Features:**
- 📊 Simplified syntax for Stores, Queries, and Mutations
- ♻️ Automatic lifecycle management
- ∞ Infinite scrolling support with `InfinityQuery`
- 🔄 Structured mutations with optimistic updates
- ✏️ Editable queries for local state management

**Installation:**
```yaml
dependencies:
  zenquery: ^0.1.0
```

**Quick Example:**
```dart
import 'package:zenquery/zenquery.dart';

// Create a query
final userQuery = createQuery((ref) async {
  return await api.fetchUser();
});

// Create a mutation
final updateProfileMutation = createMutation<User>((tsx) async {
  return await api.updateProfile(tsx);
});

// Infinite scrolling
final postsQuery = createInfinityQuery<Post, int>(
  fetch: (cursor) async => await api.fetchPosts(page: cursor ?? 0),
  getNextCursor: (lastPage, allPages) => lastPage.isEmpty ? null : allPages.length,
);
```

**[📖 Full Documentation](./packages/zenquery/README.md)**

## 🎯 Why ZenSuite?

ZenSuite packages are designed to work together seamlessly, providing a complete solution for data flow in Flutter applications:

- **ZenBus** handles event-driven communication between components
- **ZenQuery** manages asynchronous state and server interactions

Both packages prioritize:
- ⚡ **Performance** - Optimized for real-world Flutter applications
- 🎨 **Developer Experience** - Clean, intuitive APIs
- 🔒 **Type Safety** - Full Dart type safety with generics
- 📊 **Best Practices** - Opinionated patterns that scale

## 🚀 Getting Started

1. Choose the package(s) you need
2. Add them to your `pubspec.yaml`
3. Follow the package-specific documentation linked above

## 📊 Performance

Both packages include comprehensive benchmarks:

- **ZenBus**: [Performance Report](./packages/zenbus/benchmark/PERFORMANCE_BENCHMARK_REPORT.md) | [Memory Report](./packages/zenbus/benchmark/MEMORY_BENCHMARK_REPORT.md)
- **ZenQuery**: Built on Riverpod's proven performance

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

- 🐛 [Report a bug](https://github.com/definev/zensuite/issues)
- 💡 [Request a feature](https://github.com/definev/zensuite/issues)
- 📖 [View documentation](https://github.com/definev/zensuite)

---

Made with ❤️ by Bui Dai Duong
