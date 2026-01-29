# Feature-Based Configuration

The configuration system provides a modular, type-safe way to manage feature-specific settings using compile-time environment variables. Each feature module defines its own configuration class and store, ensuring clean separation of concerns and independent configuration management.

## Core Concepts

### Modular Configuration Pattern

Instead of having a single monolithic configuration, each feature module defines its own `{Feature}Config` class and corresponding store. This approach:

- **Isolates feature settings**: Each feature manages its own configuration
- **Type-safe**: Compile-time checking of configuration values
- **Independent**: Features don't need to know about other features' configs
- **Scalable**: Easy to add new features without modifying core config

### Pattern Structure

Each feature follows this pattern:

1. **Define a config class**: `{Feature}Config` with feature-specific properties
2. **Create a store**: `{feature}ConfigStore` using `createStorePersist`
3. **Load from environment**: Use `String.fromEnvironment()` for values

### Example: CoreConfig

The core module provides a minimal example of this pattern:

```dart
class CoreConfig {
  const CoreConfig({required this.appVersion, required this.appName});

  final String appVersion;
  final String appName;
}

final coreConfigStore = createStorePersist<CoreConfig>(
  (ref) => CoreConfig(
    appVersion: const String.fromEnvironment('VERSION'),
    appName: const String.fromEnvironment('APP_NAME'),
  ),
);
```

**Properties**:
- `appVersion`: The semantic version of the application (e.g., "1.0.0")
- `appName`: The display name of the application

The configuration values are loaded from compile-time environment variables using `String.fromEnvironment()`.

## Creating Feature Configurations

### Step 1: Define the Config Class

Create a config class for your feature with all necessary settings:

**Example: Authentication feature**

```dart
// packages/auth/lib/src/config/config.dart
class AuthConfig {
  const AuthConfig({
    required this.apiUrl,
    required this.apiKey,
    required this.enableBiometric,
    required this.sessionTimeout,
  });

  final String apiUrl;
  final String apiKey;
  final bool enableBiometric;
  final int sessionTimeout; // in minutes
}
```

**Example: Analytics feature**

```dart
// packages/analytics/lib/src/config/config.dart
class AnalyticsConfig {
  const AnalyticsConfig({
    required this.enabled,
    required this.trackingId,
    required this.debugMode,
  });

  final bool enabled;
  final String trackingId;
  final bool debugMode;
}
```

### Step 2: Create the Config Store

Create a persistent store for your config using `createStorePersist`:

**Example: Authentication store**

```dart
// packages/auth/lib/src/config/config.dart
final authConfigStore = createStorePersist<AuthConfig>(
  (ref) => AuthConfig(
    apiUrl: const String.fromEnvironment('AUTH_API_URL'),
    apiKey: const String.fromEnvironment('AUTH_API_KEY'),
    enableBiometric: const bool.fromEnvironment('AUTH_BIOMETRIC', defaultValue: true),
    sessionTimeout: const int.fromEnvironment('AUTH_SESSION_TIMEOUT', defaultValue: 30),
  ),
);
```

**Example: Analytics store**

```dart
// packages/analytics/lib/src/config/config.dart
final analyticsConfigStore = createStorePersist<AnalyticsConfig>(
  (ref) => AnalyticsConfig(
    enabled: const bool.fromEnvironment('ANALYTICS_ENABLED', defaultValue: false),
    trackingId: const String.fromEnvironment('ANALYTICS_TRACKING_ID'),
    debugMode: const bool.fromEnvironment('ANALYTICS_DEBUG', defaultValue: false),
  ),
);
```

### Step 3: Export from Feature Module

Make the config accessible from your feature's public API:

```dart
// packages/auth/lib/auth.dart
library;

export 'src/config/config.dart';
// ... other exports
```

## Setting Environment Variables

Environment variables are provided at build/run time using the `--dart-define` flag.

### During Development (Flutter Run)

```bash
flutter run \
  --dart-define=VERSION=1.0.0 \
  --dart-define=APP_NAME="My App"
```

### During Build

**Android:**
```bash
flutter build apk \
  --dart-define=VERSION=1.2.3 \
  --dart-define=APP_NAME="My App"
```

**iOS:**
```bash
flutter build ios \
  --dart-define=VERSION=1.2.3 \
  --dart-define=APP_NAME="My App"
```

**Web:**
```bash
flutter build web \
  --dart-define=VERSION=1.2.3 \
  --dart-define=APP_NAME="My App"
```

### Using a Configuration File

For convenience, you can store your environment variables in a file and load them during build:

**1. Create a config file** (e.g., `config/dev.env`):
```
VERSION=1.0.0-dev
APP_NAME=My App Dev
```

**2. Load it with --dart-define-from-file** (Flutter 3.7+):
```bash
flutter run --dart-define-from-file=config/dev.env
```

**Or use a script to load it**:
```bash
# build.sh
flutter run \
  $(cat config/dev.env | xargs -I {} echo "--dart-define={}")
```

## Accessing Feature Configuration

Each feature's configuration is accessed through its own store. Features should only access their own config, maintaining independence.

### In Feature Widgets

Use the feature's config store directly:

```dart
// In auth feature widget
class LoginWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authConfig = ref.watch(authConfigStore);
    
    return LoginForm(
      apiUrl: authConfig.apiUrl,
      enableBiometric: authConfig.enableBiometric,
    );
  }
}

// In analytics feature widget
class AnalyticsDebugPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsConfig = ref.watch(analyticsConfigStore);
    
    if (!analyticsConfig.debugMode) return SizedBox();
    
    return DebugPanel(
      trackingId: analyticsConfig.trackingId,
      enabled: analyticsConfig.enabled,
    );
  }
}
```

### In Feature Providers

Access config from within the feature's providers:

```dart
// In auth feature
final authServiceProvider = Provider((ref) {
  final config = ref.watch(authConfigStore);
  
  return AuthService(
    apiUrl: config.apiUrl,
    apiKey: config.apiKey,
    sessionTimeout: Duration(minutes: config.sessionTimeout),
  );
});

// In analytics feature
final analyticsClientProvider = Provider((ref) {
  final config = ref.watch(analyticsConfigStore);
  
  if (!config.enabled) return NoOpAnalyticsClient();
  
  return AnalyticsClient(
    trackingId: config.trackingId,
    debugMode: config.debugMode,
  );
});
```

### Cross-Feature Access (When Necessary)

If one feature needs another feature's config (use sparingly):

```dart
// In feature A that needs to know about feature B's config
final featureAProvider = Provider((ref) {
  final featureAConfig = ref.watch(featureAConfigStore);
  final featureBConfig = ref.watch(featureBConfigStore);
  
  return FeatureAService(
    ownConfig: featureAConfig,
    dependencyBaseUrl: featureBConfig.apiUrl, // Only if truly needed
  );
});
```

### Accessing Core Config

All features can access the core config for app-wide values:

```dart
// Any feature can access core config
final myFeatureProvider = Provider((ref) {
  final coreConfig = ref.watch(coreConfigStore);
  final myConfig = ref.watch(myFeatureConfigStore);
  
  return MyFeatureService(
    appVersion: coreConfig.appVersion, // App-wide value
    featureSpecificUrl: myConfig.apiUrl, // Feature-specific value
  );
});
```

## Real-World Feature Examples

### Calendar Feature Configuration

```dart
// packages/calendar/lib/src/config/config.dart
class CalendarConfig {
  const CalendarConfig({
    required this.syncEnabled,
    required this.syncInterval,
    required this.calendarProvider,
    required this.defaultView,
  });

  final bool syncEnabled;
  final int syncInterval; // in minutes
  final String calendarProvider; // 'google', 'apple', 'microsoft'
  final String defaultView; // 'month', 'week', 'day'
}

final calendarConfigStore = createStorePersist<CalendarConfig>(
  (ref) => CalendarConfig(
    syncEnabled: const bool.fromEnvironment('CALENDAR_SYNC_ENABLED', defaultValue: true),
    syncInterval: const int.fromEnvironment('CALENDAR_SYNC_INTERVAL', defaultValue: 15),
    calendarProvider: const String.fromEnvironment('CALENDAR_PROVIDER', defaultValue: 'google'),
    defaultView: const String.fromEnvironment('CALENDAR_DEFAULT_VIEW', defaultValue: 'month'),
  ),
);
```

**Environment variables:**
```bash
flutter run \
  --dart-define=CALENDAR_SYNC_ENABLED=true \
  --dart-define=CALENDAR_SYNC_INTERVAL=15 \
  --dart-define=CALENDAR_PROVIDER=google \
  --dart-define=CALENDAR_DEFAULT_VIEW=month
```

### Payment Feature Configuration

```dart
// packages/payment/lib/src/config/config.dart
class PaymentConfig {
  const PaymentConfig({
    required this.stripePublishableKey,
    required this.environment,
    required this.enableApplePay,
    required this.enableGooglePay,
  });

  final String stripePublishableKey;
  final String environment; // 'test', 'live'
  final bool enableApplePay;
  final bool enableGooglePay;
  
  bool get isLive => environment == 'live';
}

final paymentConfigStore = createStorePersist<PaymentConfig>(
  (ref) => PaymentConfig(
    stripePublishableKey: const String.fromEnvironment('STRIPE_PUBLISHABLE_KEY'),
    environment: const String.fromEnvironment('PAYMENT_ENV', defaultValue: 'test'),
    enableApplePay: const bool.fromEnvironment('ENABLE_APPLE_PAY', defaultValue: false),
    enableGooglePay: const bool.fromEnvironment('ENABLE_GOOGLE_PAY', defaultValue: false),
  ),
);
```

### Notification Feature Configuration

```dart
// packages/notifications/lib/src/config/config.dart
class NotificationConfig {
  const NotificationConfig({
    required this.firebaseApiKey,
    required this.enablePushNotifications,
    required this.enableInAppNotifications,
    required this.sound,
  });

  final String firebaseApiKey;
  final bool enablePushNotifications;
  final bool enableInAppNotifications;
  final String sound; // 'default', 'silent', 'custom'
}

final notificationConfigStore = createStorePersist<NotificationConfig>(
  (ref) => NotificationConfig(
    firebaseApiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
    enablePushNotifications: const bool.fromEnvironment('ENABLE_PUSH_NOTIF', defaultValue: true),
    enableInAppNotifications: const bool.fromEnvironment('ENABLE_INAPP_NOTIF', defaultValue: true),
    sound: const String.fromEnvironment('NOTIF_SOUND', defaultValue: 'default'),
  ),
);
```

## Environment-Specific Configuration

Organize different configurations for different environments (dev, staging, production).

### Directory Structure

```
config/
├── dev.env
├── staging.env
└── production.env
```

**dev.env:**
```
VERSION=1.0.0-dev
APP_NAME=My App Dev
API_URL=https://dev-api.example.com
ENABLE_ANALYTICS=false
```

**staging.env:**
```
VERSION=1.0.0-staging
APP_NAME=My App Staging
API_URL=https://staging-api.example.com
ENABLE_ANALYTICS=true
```

**production.env:**
```
VERSION=1.0.0
APP_NAME=My App
API_URL=https://api.example.com
ENABLE_ANALYTICS=true
```

### Build Scripts

Create helper scripts to build for different environments:

**build_dev.sh:**
```bash
#!/bin/bash
flutter build apk --dart-define-from-file=config/dev.env
```

**build_staging.sh:**
```bash
#!/bin/bash
flutter build apk --dart-define-from-file=config/staging.env
```

**build_production.sh:**
```bash
#!/bin/bash
flutter build apk --dart-define-from-file=config/production.env
```

## Best Practices

### 1. Provide Default Values

Always provide sensible defaults for environment variables:

```dart
final coreConfigStore = createStorePersist<CoreConfig>(
  (ref) => CoreConfig(
    appVersion: const String.fromEnvironment('VERSION', defaultValue: '0.0.0'),
    appName: const String.fromEnvironment('APP_NAME', defaultValue: 'App'),
  ),
);
```

### 2. Validate Configuration

Add validation in your config constructor:

```dart
class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.apiKey,
  }) : assert(apiUrl.isNotEmpty, 'API_URL must not be empty'),
       assert(apiKey.isNotEmpty, 'API_KEY must not be empty');

  final String apiUrl;
  final String apiKey;
}
```

### 3. Keep Secrets Out of Version Control

Add your `.env` files to `.gitignore`:

```gitignore
# .gitignore
config/*.env
!config/*.env.example
```

Provide example files:

**config/dev.env.example:**
```
VERSION=1.0.0-dev
APP_NAME=My App Dev
API_URL=https://dev-api.example.com
API_KEY=your-api-key-here
```

### 4. Document Required Variables

Create a README in your config directory:

**config/README.md:**
```markdown
# Configuration

Required environment variables:

- `VERSION`: Semantic version (e.g., 1.0.0)
- `APP_NAME`: Application display name
- `API_URL`: Backend API endpoint
- `API_KEY`: API authentication key

Copy `dev.env.example` to `dev.env` and fill in the values.
```

### 5. Use Type-Safe Values

Leverage Dart's compile-time constant system:

```dart
class FeatureFlags {
  const FeatureFlags({
    required this.enableNewUI,
    required this.enableBetaFeatures,
  });

  final bool enableNewUI;
  final bool enableBetaFeatures;
}

final featureFlagsStore = createStorePersist<FeatureFlags>(
  (ref) => FeatureFlags(
    enableNewUI: const bool.fromEnvironment('ENABLE_NEW_UI', defaultValue: false),
    enableBetaFeatures: const bool.fromEnvironment('ENABLE_BETA', defaultValue: false),
  ),
);
```

### 6. Separate Build-Time and Runtime Config

Use compile-time environment variables for values that don't change after build:
- App version
- App name
- API endpoints
- Feature flags

Use runtime configuration (e.g., remote config, local storage) for values that can change:
- User preferences
- A/B test variants
- Dynamic feature toggles

## Common Patterns

### Multi-Flavor Configuration

```dart
enum AppFlavor { dev, staging, production }

class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appVersion,
    required this.apiUrl,
  });

  final AppFlavor flavor;
  final String appVersion;
  final String apiUrl;
  
  bool get isDev => flavor == AppFlavor.dev;
  bool get isProduction => flavor == AppFlavor.production;
}

final appConfigStore = createStorePersist<AppConfig>(
  (ref) {
    final flavorString = const String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    final flavor = AppFlavor.values.firstWhere(
      (f) => f.name == flavorString,
      orElse: () => AppFlavor.dev,
    );
    
    return AppConfig(
      flavor: flavor,
      appVersion: const String.fromEnvironment('VERSION', defaultValue: '0.0.0'),
      apiUrl: const String.fromEnvironment('API_URL'),
    );
  },
);
```

### Region-Specific Configuration

```dart
class RegionalConfig {
  const RegionalConfig({
    required this.region,
    required this.currency,
    required this.dateFormat,
  });

  final String region;
  final String currency;
  final String dateFormat;
}

final regionalConfigStore = createStorePersist<RegionalConfig>(
  (ref) => RegionalConfig(
    region: const String.fromEnvironment('REGION', defaultValue: 'US'),
    currency: const String.fromEnvironment('CURRENCY', defaultValue: 'USD'),
    dateFormat: const String.fromEnvironment('DATE_FORMAT', defaultValue: 'MM/dd/yyyy'),
  ),
);
```

## Testing with Configuration

### Override Configuration in Tests

```dart
void main() {
  test('should use test configuration', () {
    final container = ProviderContainer(
      overrides: [
        coreConfigStore.overrideWith((ref) => CoreConfig(
          appVersion: '0.0.0-test',
          appName: 'Test App',
        )),
      ],
    );

    final config = container.read(coreConfigStore);
    expect(config.appVersion, '0.0.0-test');
  });
}
```

### Integration Tests with Environment

```bash
# Run integration tests with test config
flutter test integration_test \
  --dart-define=VERSION=0.0.0-test \
  --dart-define=APP_NAME="Test App" \
  --dart-define=API_URL=https://test-api.example.com
```

## Related Documentation

- **Dependency Injection (DI) Pattern** - Learn about the provider system used for configuration
- **Queries, Mutations & Stores** - Understand how `createStorePersist` works

## Summary

The configuration system provides:

- ✅ **Type-safe**: Compile-time checking of configuration values
- ✅ **Immutable**: Configuration values can't be accidentally changed at runtime
- ✅ **Environment-specific**: Different configs for dev, staging, production
- ✅ **Testable**: Easy to override in tests
- ✅ **Extensible**: Simple to add custom configuration fields
- ✅ **Integrated**: Works seamlessly with the DI system
