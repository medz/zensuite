# Dependency Injection (DI) Pattern

The project uses [Riverpod](https://riverpod.dev/) as the Dependency Injection (DI) solution, managed via a global `ProviderContainer`. This approach allows accessing providers both inside and outside the widget tree (e.g., in the Router, Event Logic, or Initialization scripts).

## Core Concepts

### 1. Global `ProviderContainer`

Instead of relying solely on `ProviderScope` to create an implicit container, we manually create and manage a global `ProviderContainer`. This allows us to:
- Access providers in `main.dart` before `runApp`.
- Access providers in non-widget classes (like Coordinators or Repositories).
- Control the initialization order.

### 2. Initialize Provider

The `initialize` provider is a persistent query that runs once when the app starts. It's designed for async initialization tasks like:
- Loading user preferences
- Setting up analytics
- Initializing databases
- Configuring third-party SDKs

#### The `initialize` Provider

`qmse` exports a default `initialize` provider that you can override in your app:

```dart
// In your app's DI setup (e.g., lib/di/instance.dart)
final initialize = createQueryPersist((ref) async {
  // Run initialization logic here
  await ref.read(databaseStore).initialize();
  await ref.read(analyticsStore).configure();
  
  // You can access other providers
  final user = await ref.read(userProfileQuery.future);
  print('Initialized for user: ${user.name}');
});
```

#### The `InitializeDI` Widget

`InitializeDI` is a widget that watches the `initialize` provider and shows different UI states:

**Parameters:**
- `builder`: Widget to show when initialization completes successfully
- `loadingBuilder` (optional): Widget to show during initialization (defaults to empty)
- `errorBuilder` (optional): Widget to show if initialization fails (defaults to empty)

**Basic Usage:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  container = await createProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: InitializeDI(
        builder: (context) => const MyApp(),
        loadingBuilder: (context) => const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
        errorBuilder: (context) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text('Failed to initialize app'),
            ),
          ),
        ),
      ),
    ),
  );
}
```

**Advanced Example with Custom Initialization:**

```dart
// lib/di/instance.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qmse/qmse.dart';

Future<ProviderContainer> createProviderContainer() async {
  final overrides = <Override>[];
  
  // Override the initialize provider from qmse
  overrides.add(
    initialize.overrideWith((ref) async {
      // Initialize database
      final db = ref.read(databaseStore);
      await db.open();
      
      // Load app config
      final config = await ref.read(appConfigQuery.future);
      
      // Setup analytics
      if (config.analyticsEnabled) {
        await ref.read(analyticsStore).initialize(
          apiKey: config.analyticsKey,
        );
      }
      
      // Preload critical data
      await ref.read(userPreferencesQuery.future);
    }),
  );

  return ProviderContainer(
    overrides: overrides,
  );
}

// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  container = await createProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: InitializeDI(
        builder: (context) => const MyApp(),
        loadingBuilder: (context) => const SplashScreen(),
        errorBuilder: (context) => const InitializationErrorScreen(),
      ),
    ),
  );
}
```

## Implementation Guide

### Step 1: Define the Container

Create a file (e.g., `lib/di/instance.dart`) to hold the global container variable and a factory function to create it.

```dart
// lib/di/instance.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qmse/qmse.dart';
import 'package:zenories_app/router/coordinator.dart';

// 1. Factory function to initialize the container and apply overrides
Future<ProviderContainer> createProviderContainer() async {
  final overrides = <Override>[];
  
  // Example: Override the Coordinator Provider with implementation
  overrides.addAll([
    coordinatorProvider.overrideWithValue(AppCoordinatorImpl()),
  ]);

  return ProviderContainer(
    overrides: overrides,
    observers: [], // Add observers if needed
  );
}
```

### Step 2: Initialize in `main.dart`

Initialize the container before `runApp` and inject it using `UncontrolledProviderScope`.

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenories_app/di/instance.dart'; // Import your container definition

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Create the container
  container = await createProviderContainer();

  // 2. Run App with UncontrolledProviderScope
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: InitializeDI(
        builder: (context) => const MyApp(),
      ),
    ),
  );
}
```

### Step 3: Usage

#### Inside Widgets
Use `ConsumerWidget` or `ConsumerStatefulWidget` as usual.

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(myProvider);
    return Text(value);
  }
}
```

#### Outside Widgets
Use the global `container` variable.

```dart
void someFunction() {
  final value = container.read(myProvider);
  // Do logic
}
```

## Testing

For testing, you can create a separate container with different overrides for mocks.

```dart
final testContainer = ProviderContainer(
  overrides: [
    myProvider.overrideWith((ref) => MockService()),
  ],
);
```
