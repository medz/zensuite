# Cấu hình theo tính năng (Feature-Based Configuration)

Hệ thống cấu hình cung cấp cách modular, type-safe để quản lý các thiết lập cụ thể cho từng tính năng sử dụng biến môi trường compile-time. Mỗi module tính năng định nghĩa class cấu hình và store riêng của nó, đảm bảo tách biệt rõ ràng các mối quan tâm và quản lý cấu hình độc lập.

## Các khái niệm cốt lõi

### Mô hình cấu hình Modular

Thay vì có một cấu hình nguyên khối duy nhất, mỗi module tính năng định nghĩa class `{Feature}Config` và store tương ứng riêng của nó. Cách tiếp cận này:

- **Cô lập thiết lập tính năng**: Mỗi tính năng quản lý cấu hình riêng của nó
- **Type-safe**: Kiểm tra compile-time cho các giá trị cấu hình
- **Độc lập**: Các tính năng không cần biết về config của tính năng khác
- **Scalable**: Dễ dàng thêm tính năng mới mà không cần sửa đổi config cốt lõi

### Cấu trúc mô hình

Mỗi tính năng tuân theo mô hình này:

1. **Định nghĩa class config**: `{Feature}Config` với các thuộc tính cụ thể cho tính năng
2. **Tạo store**: `{feature}ConfigStore` sử dụng `createStorePersist`
3. **Tải từ môi trường**: Sử dụng `String.fromEnvironment()` cho các giá trị

### Ví dụ: CoreConfig

Module core cung cấp một ví dụ tối thiểu của mô hình này:

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

**Thuộc tính**:
- `appVersion`: Phiên bản semantic của ứng dụng (ví dụ: "1.0.0")
- `appName`: Tên hiển thị của ứng dụng

Các giá trị cấu hình được tải từ biến môi trường compile-time sử dụng `String.fromEnvironment()`.

## Tạo cấu hình tính năng

### Bước 1: Định nghĩa Class Config

Tạo class config cho tính năng của bạn với tất cả các thiết lập cần thiết:

**Ví dụ: Tính năng Authentication**

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
  final int sessionTimeout; // tính bằng phút
}
```

**Ví dụ: Tính năng Analytics**

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

### Bước 2: Tạo Config Store

Tạo persistent store cho config của bạn sử dụng `createStorePersist`:

**Ví dụ: Authentication store**

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

**Ví dụ: Analytics store**

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

### Bước 3: Export từ module tính năng

Làm cho config có thể truy cập được từ API công khai của tính năng:

```dart
// packages/auth/lib/auth.dart
library;

export 'src/config/config.dart';
// ... các export khác
```

## Thiết lập biến môi trường

Biến môi trường được cung cấp tại thời điểm build/run sử dụng flag `--dart-define`.

### Trong quá trình phát triển (Flutter Run)

```bash
flutter run \
  --dart-define=VERSION=1.0.0 \
  --dart-define=APP_NAME="My App"
```

### Trong quá trình Build

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

### Sử dụng file cấu hình

Để thuận tiện, bạn có thể lưu trữ các biến môi trường trong một file và tải chúng trong quá trình build:

**1. Tạo file config** (ví dụ: `config/dev.env`):
```
VERSION=1.0.0-dev
APP_NAME=My App Dev
```

**2. Tải nó với --dart-define-from-file** (Flutter 3.7+):
```bash
flutter run --dart-define-from-file=config/dev.env
```

**Hoặc sử dụng script để tải nó**:
```bash
# build.sh
flutter run \
  $(cat config/dev.env | xargs -I {} echo "--dart-define={}")
```

## Truy cập cấu hình tính năng

Cấu hình của mỗi tính năng được truy cập thông qua store riêng của nó. Các tính năng chỉ nên truy cập config của chính nó, duy trì tính độc lập.

### Trong Widget tính năng

Sử dụng config store của tính năng trực tiếp:

```dart
// Trong widget tính năng auth
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

// Trong widget tính năng analytics
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

### Trong Provider tính năng

Truy cập config từ bên trong provider của tính năng:

```dart
// Trong tính năng auth
final authServiceProvider = Provider((ref) {
  final config = ref.watch(authConfigStore);
  
  return AuthService(
    apiUrl: config.apiUrl,
    apiKey: config.apiKey,
    sessionTimeout: Duration(minutes: config.sessionTimeout),
  );
});

// Trong tính năng analytics
final analyticsClientStore = createStorePersist((ref) {
  final config = ref.watch(analyticsConfigStore);
  
  if (!config.enabled) return NoOpAnalyticsClient();
  
  return AnalyticsClient(
    trackingId: config.trackingId,
    debugMode: config.debugMode,
  );
});
```

### Truy cập Cross-Feature (Khi cần thiết)

Nếu một tính năng cần config của tính năng khác (sử dụng tiết kiệm):

```dart
// Trong feature A cần biết về config của feature B
final featureAStore = createStorePersist((ref) {
  final featureAConfig = ref.watch(featureAConfigStore);
  final featureBConfig = ref.watch(featureBConfigStore);
  
  return FeatureAService(
    ownConfig: featureAConfig,
    dependencyBaseUrl: featureBConfig.apiUrl, // Chỉ khi thực sự cần
  );
});
```

### Truy cập Core Config

Tất cả các tính năng có thể truy cập core config cho các giá trị toàn ứng dụng:

```dart
// Bất kỳ tính năng nào cũng có thể truy cập core config
final myFeatureStore = createStorePersist((ref) {
  final coreConfig = ref.watch(coreConfigStore);
  final myConfig = ref.watch(myFeatureConfigStore);
  
  return MyFeatureService(
    appVersion: coreConfig.appVersion, // Giá trị toàn ứng dụng
    featureSpecificUrl: myConfig.apiUrl, // Giá trị cụ thể tính năng
  );
});
```

## Ví dụ tính năng thực tế

### Cấu hình tính năng Calendar

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
  final int syncInterval; // tính bằng phút
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

**Biến môi trường:**
```bash
flutter run \
  --dart-define=CALENDAR_SYNC_ENABLED=true \
  --dart-define=CALENDAR_SYNC_INTERVAL=15 \
  --dart-define=CALENDAR_PROVIDER=google \
  --dart-define=CALENDAR_DEFAULT_VIEW=month
```

### Cấu hình tính năng Payment

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

### Cấu hình tính năng Notification

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

## Cấu hình theo môi trường

Tổ chức các cấu hình khác nhau cho các môi trường khác nhau (dev, staging, production).

### Cấu trúc thư mục

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

Tạo các helper script để build cho các môi trường khác nhau:

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

## Các phương pháp tốt nhất

### 1. Cung cấp giá trị mặc định

Luôn cung cấp giá trị mặc định hợp lý cho các biến môi trường:

```dart
final coreConfigStore = createStorePersist<CoreConfig>(
  (ref) => CoreConfig(
    appVersion: const String.fromEnvironment('VERSION', defaultValue: '0.0.0'),
    appName: const String.fromEnvironment('APP_NAME', defaultValue: 'App'),
  ),
);
```

### 2. Xác thực cấu hình

Thêm validation trong constructor config của bạn:

```dart
class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.apiKey,
  }) : assert(apiUrl.isNotEmpty, 'API_URL không được để trống'),
       assert(apiKey.isNotEmpty, 'API_KEY không được để trống');

  final String apiUrl;
  final String apiKey;
}
```

### 3. Giữ bí mật ngoài Version Control

Thêm các file `.env` của bạn vào `.gitignore`:

```gitignore
# .gitignore
config/*.env
!config/*.env.example
```

Cung cấp các file ví dụ:

**config/dev.env.example:**
```
VERSION=1.0.0-dev
APP_NAME=My App Dev
API_URL=https://dev-api.example.com
API_KEY=your-api-key-here
```

### 4. Tài liệu hóa các biến bắt buộc

Tạo README trong thư mục config của bạn:

**config/README.md:**
```markdown
# Configuration

Các biến môi trường bắt buộc:

- `VERSION`: Phiên bản semantic (ví dụ: 1.0.0)
- `APP_NAME`: Tên hiển thị ứng dụng
- `API_URL`: Endpoint API backend
- `API_KEY`: Khóa xác thực API

Copy `dev.env.example` thành `dev.env` và điền các giá trị.
```

### 5. Sử dụng giá trị Type-Safe

Tận dụng hệ thống constant compile-time của Dart:

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

### 6. Tách biệt cấu hình Build-Time và Runtime

Sử dụng biến môi trường compile-time cho các giá trị không thay đổi sau khi build:
- Phiên bản app
- Tên app
- API endpoints
- Feature flags

Sử dụng cấu hình runtime (ví dụ: remote config, local storage) cho các giá trị có thể thay đổi:
- User preferences
- A/B test variants
- Dynamic feature toggles

## Testing với cấu hình

### Override cấu hình trong Tests

```dart
void main() {
  test('nên sử dụng cấu hình test', () {
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

### Integration Tests với môi trường

```bash
# Chạy integration tests với test config
flutter test integration_test \
  --dart-define=VERSION=0.0.0-test \
  --dart-define=APP_NAME="Test App" \
  --dart-define=API_URL=https://test-api.example.com
```

## Tài liệu liên quan

- **Dependency Injection (DI) Pattern** - Tìm hiểu về hệ thống provider được sử dụng cho cấu hình
- **Queries, Mutations & Stores** - Hiểu cách `createStorePersist` hoạt động

## Tóm tắt

Hệ thống cấu hình cung cấp:

- ✅ **Type-safe**: Kiểm tra compile-time cho các giá trị cấu hình
- ✅ **Immutable**: Các giá trị cấu hình không thể bị thay đổi vô tình tại runtime
- ✅ **Theo môi trường**: Các config khác nhau cho dev, staging, production
- ✅ **Testable**: Dễ dàng override trong tests
- ✅ **Extensible**: Đơn giản để thêm các trường cấu hình tùy chỉnh
- ✅ **Tích hợp**: Hoạt động liền mạch với hệ thống DI
