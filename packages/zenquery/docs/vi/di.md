# Mô hình Dependency Injection (DI)

Dự án sử dụng [Riverpod](https://riverpod.dev/) làm giải pháp Dependency Injection (DI), được quản lý thông qua một `ProviderContainer` toàn cục. Cách tiếp cận này cho phép truy cập các provider cả bên trong và bên ngoài cây widget (ví dụ: trong Router, Event Logic, hoặc các initialization scripts).

## Các khái niệm cốt lõi

### 1. `ProviderContainer` toàn cục

Thay vì chỉ dựa vào `ProviderScope` để tạo một container ngầm định, chúng ta khởi tạo và quản lý thủ công một `ProviderContainer` toàn cục. Điều này cho phép:
- Truy cập các provider trong `main.dart` trước khi chạy `runApp`.
- Truy cập các provider trong các class không phải widget (như Coordinator hoặc Repository).
- Kiểm soát thứ tự khởi tạo.

### 2. Initialize Provider

Provider `initialize` là một query persistent chạy một lần khi ứng dụng khởi động. Nó được thiết kế cho các tác vụ khởi tạo bất đồng bộ như:
- Tải user preferences
- Thiết lập analytics
- Khởi tạo database
- Cấu hình các SDK bên thứ ba

#### Provider `initialize`

`qmse` export một provider `initialize` mặc định mà bạn có thể override trong ứng dụng:

```dart
// Trong DI setup của app (ví dụ: lib/di/instance.dart)
final initialize = createQueryPersist((ref) async {
  // Chạy logic khởi tạo ở đây
  await ref.read(databaseStore).initialize();
  await ref.read(analyticsStore).configure();
  
  // Bạn có thể truy cập các provider khác
  final user = await ref.read(userProfileQuery.future);
  print('Initialized for user: ${user.name}');
});
```

#### Widget `InitializeDI`

`InitializeDI` là một widget theo dõi provider `initialize` và hiển thị các trạng thái UI khác nhau:

**Tham số:**
- `builder`: Widget hiển thị khi khởi tạo hoàn tất thành công
- `loadingBuilder` (tùy chọn): Widget hiển thị trong quá trình khởi tạo (mặc định là empty)
- `errorBuilder` (tùy chọn): Widget hiển thị nếu khởi tạo thất bại (mặc định là empty)

**Sử dụng cơ bản:**

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
              child: Text('Không thể khởi tạo ứng dụng'),
            ),
          ),
        ),
      ),
    ),
  );
}
```

**Ví dụ nâng cao với Custom Initialization:**

```dart
// lib/di/instance.dart
import 'package:riverpod/riverpod.dart';
import 'package:qmse/qmse.dart';

Future<ProviderContainer> createProviderContainer() async {
  final overrides = <Override>[];
  
  // Override provider initialize từ qmse
  overrides.add(
    initialize.overrideWith((ref) async {
      // Khởi tạo database
      final db = ref.read(databaseStore);
      await db.open();
      
      // Tải app config
      final config = await ref.read(appConfigQuery.future);
      
      // Thiết lập analytics
      if (config.analyticsEnabled) {
        await ref.read(analyticsStore).initialize(
          apiKey: config.analyticsKey,
        );
      }
      
      // Preload dữ liệu quan trọng
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

## Hướng dẫn triển khai

### Bước 1: Định nghĩa Container

Tạo một file (ví dụ: `lib/di/instance.dart`) để giữ biến container toàn cục và một hàm factory để tạo nó.

```dart
// lib/di/instance.dart
import 'package:riverpod/riverpod.dart';
import 'package:qmse/qmse.dart';
import 'package:zenories_app/router/coordinator.dart';

// 1. Hàm factory để khởi tạo container và áp dụng overrides
Future<ProviderContainer> createProviderContainer() async {
  final overrides = <Override>[];
  
  // Ví dụ: Override Coordinator Provider với implementation cụ thể
  overrides.addAll([
    coordinatorProvider.overrideWithValue(AppCoordinatorImpl()),
  ]);

  return ProviderContainer(
    overrides: overrides,
    retry: (retryCount, error) => null,
  );
}
```

### Bước 2: Khởi tạo trong `main.dart`

Khởi tạo container trước khi `runApp` và inject nó sử dụng `UncontrolledProviderScope`.

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';
import 'package:zenories_app/di/instance.dart'; // Import định nghĩa container của bạn

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Tạo container
  container = await createProviderContainer();

  // 2. Chạy App với UncontrolledProviderScope
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

### Bước 3: Sử dụng

#### Trong Widget
Sử dụng `ConsumerWidget` hoặc `ConsumerStatefulWidget` như bình thường.

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(myProvider);
    return Text(value);
  }
}
```

#### Ngoài Widget
Sử dụng biến `container` toàn cục.

```dart
void someFunction() {
  final value = container.read(myProvider);
  // Thực hiện logic
}
```

## Testing

Để testing, bạn có thể tạo một container riêng biệt với các overrides khác nhau cho mocks.

```dart
final testContainer = ProviderContainer(
  overrides: [
    myProvider.overrideWith((ref) => MockService()),
  ],
);
```
