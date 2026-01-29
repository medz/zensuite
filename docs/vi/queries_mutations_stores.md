# Hướng dẫn API Query, Mutation, Store

Kiến trúc này tuân thủ một mô hình kiến trúc nghiêm ngặt sử dụng Riverpod. Nó tách biệt trạng thái ứng dụng thành ba thành phần nguyên thủy riêng biệt: **Query** (Truy vấn), **Mutation** (Thay đổi/Tác vụ), và **Store** (Kho chứa).

Sự tách biệt này đảm bảo tính dự đoán:
- **Query**: Lấy và lưu trữ dữ liệu (tương đương GET).
- **Mutation**: Thay đổi dữ liệu & thực hiện side effects (tương đương POST/PUT/DELETE).
- **Store**: Các phụ thuộc đồng bộ & trạng thái dẫn xuất.

## 1. Quy ước Đặt tên & Factory

Tất cả các thành phần nguyên thủy đều được tạo bằng các hàm factory toàn cục.

| Factory | Vòng đời | Trường hợp sử dụng |
| :--- | :--- | :--- |
| `create[Type]` | **AutoDispose** | Màn hình tạm thời, kết quả tìm kiếm. Tự động dọn dẹp khi không sử dụng. |
| `create[Type]Persist` | **KeepAlive** | Dữ liệu cần được lưu cache lâu dài (ví dụ: Hồ sơ người dùng). |
| `create[Type]Family` | **Parameterized** | Lấy dữ liệu theo ID, Tìm kiếm với tham số. |

---

## 2. Queries (`query.dart`)

Query dùng để **đọc dữ liệu bất đồng bộ**. Chúng bao bọc `FutureProvider` hoặc `AsyncNotifierProvider` chuẩn.

### A. Query Chuẩn (`createQuery`)
Sử dụng để lấy dữ liệu đơn giản khi bạn chỉ cần đọc giá trị.

```dart
// Định nghĩa
final userProfileQuery = createQuery<UserProfile>((ref) async {
  return ref.read(apiStore).users.me();
});

// Sử dụng
class UserProfileWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Theo dõi query
    final userAsync = ref.watch(userProfileQuery);

    // 2. Xử lý loading/error/data
    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Thất bại: $err'),
    );
  }
}
```

### B. Editable Query (`createQueryEditable`)
Sử dụng khi bạn cần **tự sửa đổi** cache sau khi lấy dữ liệu, ví dụ cho **Cập nhật Lạc quan (Optimistic Updates)**.

Nó cung cấp một notifier `QueryEditable<T>` với các phương thức:
- `setValue(T)`: đặt trạng thái dữ liệu.
- `setLoading()`: đặt trạng thái đang tải.
- `setError(e, s)`: đặt trạng thái lỗi.

```dart
// Định nghĩa
final todosQuery = createQueryEditable<List<Todo>>((ref) async {
  return api.fetchTodos();
});

// Cập nhật Lạc quan
void addTodo(WidgetRef ref, Todo newTodo) {
  final notifier = ref.read(todosQuery.notifier);
  
  // 1. Lấy dữ liệu hiện tại (nếu có)
  final previousTodos = ref.read(todosQuery).valueOrNull ?? [];
  
  // 2. Cập nhật lạc quan
  notifier.setValue([...previousTodos, newTodo]);
  
  // 3. Thực hiện request mạng (logic thường nằm trong Mutation)
}
```

---

## 3. Mutations (`mutation.dart`)

Mutation dùng để **ghi dữ liệu** hoặc thực hiện các side effects. Chúng bao bọc lớp `MutationAction`.

**Khác biệt chính so với Query**:
- Query chạy tự động khi được watch.
- Mutation **chỉ chạy khi gọi `.run()`**.

### Cấu trúc
Một provider mutation trả về đối tượng `MutationAction` chứa:
- `run()`: Hàm để thực thi logic.
- `state`: Đối tượng `Mutation<T>` giữ trạng thái hiện tại (`data`, `error`, `loading`).
- `reset()`: Đặt lại trạng thái về idle.

### Định nghĩa Mutation

```dart
final loginMutation = createMutationFamily<User, LoginCredentials>((tsx, credentials) async {
  // 'tsx' là MutationTransaction. Dùng tsx.get() để truy cập các store khác.
  return tsx.get(authApiStore).login(credentials);
});
```

### Sử dụng Mutation (Mẫu Quan trọng)

Bạn cần watch **hai** thứ: action (để chạy) và state (để hiển thị spinner).

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // 1. WATCH ACTION: Cần thiết để lấy phương thức .run()
  final action = ref.watch(loginMutation(myCredentials));

  // 2. WATCH STATE: Cần thiết để phản ứng với thay đổi loading/error
  final state = ref.watch(action.state);

  return Column(
    children: [
      if (state.hasError) Text(state.error.toString()),
      
      ElevatedButton(
        // Vô hiệu hóa nút khi đang tải
        onPressed: state.isLoading 
            ? null 
            : () async {
                await action.run();
                if (context.mounted) {
                   Navigator.of(context).pushReplacementNamed('/home');
                }
              }, 
        child: state.isLoading 
            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator()) 
            : const Text('Đăng nhập'),
      ),
    ],
  );
}
```

### MutationTransaction (`tsx`)
Tham số `transaction` (thường đặt tên là `tsx`) trong `createMutation` cho phép bạn truy cập các provider khác.

```dart
final updateEventMutation = createMutation<void>((tsx) async {
  // Dùng tsx.get() để tương tác với các store khác
  tsx.get(analyticsStore).logEvent('update_started');
  
  // Dùng tsx.get() để tương tác với các query khác
  final event = await tsx.get(eventQuery.future);
  
  await api.update(event.copyWith(updatedAt: DateTime.now()));
  
  tsx.get(eventBusStore).fire(EventUpdated());
});
```

---

## 4. Stores (`store.dart`)

Store dành cho các phụ thuộc **Đồng bộ**. Chúng chỉ là wrapper đơn giản quanh `Provider`.
Sử dụng cho:
- Dependency Injection (Repositories, APIs).
- Trạng thái dẫn xuất không cần xử lý bất đồng bộ.
- Event Buses / Controllers.

```dart
// Định nghĩa
final authRepositoryStore = createStore<AuthRepository>((ref) {
  return AuthRepository(client: ref.watch(httpClientStore));
});

// Sử dụng
final repo = ref.watch(authRepositoryStore);
```

---

## Thực hành Tốt nhất

1.  **Cấu trúc File**:
    ```
    feature/
      queries/
        get_user.dart
        list_items.dart
        update_user.dart
        delete_item.dart
        queries.dart
      ui/
        user_page.dart
    ```

2.  **File Barrel**: Một file `queries.dart` barrel nên export tất cả các file bên trong `queries/` để import gọn gàng hơn trong UI.
    ```dart
    library;
    
    export 'get_user.dart';
    export 'list_items.dart';
    export 'update_user.dart';
    export 'delete_item.dart';
    ```

3.  **Tách biệt Side Effects**: Không đặt side effects (điều hướng, hiển thị thông báo) bên trong định nghĩa mutation nếu chúng thuộc về UI. Hãy sử dụng `await action.run()` trong UI handler (như `onPressed`) để thực hiện sau khi thành công.

4.  **Sử dụng `tsx`**: Khi ở trong một mutation, ưu tiên sử dụng đối tượng `transaction` nếu được cung cấp để có ngữ nghĩa giao dịch tốt hơn (future proofing).

5.  **Điều hướng cho AI**: Giữ tất cả logic trong thư mục `queries/` cho phép các AI Agent dễ dàng liệt kê thư mục và hiểu mọi khả năng của tính năng (API) chỉ bằng cách đọc tên file mô tả.


