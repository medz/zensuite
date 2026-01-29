# Sự kiện (EventBus)

Hệ thống EventBus cung cấp cách để tách biệt **Mutations** (Nhà sản xuất) khỏi **Queries** (Người tiêu dùng).

## Cách hoạt động

Lớp `EventBus<T>` là một wrapper nhẹ xung quanh `StreamController<T>.broadcast()` của Dart.

1.  **Broadcast Stream**: Nó sử dụng broadcast stream cho phép nhiều người nghe (Queries) đăng ký cùng một nguồn sự kiện đồng thời.
2.  **Lọc theo Kiểu (Type Filtering)**: Phương thức `.on<E>()` sử dụng `stream.where((e) => e is E).cast<E>()` để lọc sự kiện. Điều này đảm bảo Query chỉ bị đánh thức bởi các sự kiện cụ thể mà nó quan tâm, bỏ qua tất cả các sự kiện khác.
3.  **Vòng đời (Lifecycle)**: Khi được đăng ký như một Store (`createEventBusStorePersist`), bus sẽ gắn liền với vòng đời của ProviderContainer.

## Tích hợp với Query/Mutation

Trường hợp sử dụng chính là invalidate cache khi một mutation xảy ra.

### Mẫu 1: Query Lắng nghe & Tự Invalidate
Query đăng ký các sự kiện cụ thể và kích hoạt `ref.invalidateSelf()` để lấy lại dữ liệu mới.

```dart
// get_default_calendar.dart
final getDefaultCalendar = createQuery<String?>((ref) async {
  // 1. Đăng ký sự kiện sẽ khiến query này phải refresh
  final sub = ref
      .read(calendarEventBusStore)
      .on<UpdateDefaultCalendar>() // Loại sự kiện
      .listen((event) => ref.invalidateSelf());
  
  // 2. Dọn dẹp subscription khi dispose
  ref.onDispose(sub.cancel);

  // 3. Lấy dữ liệu
  return api.fetchDefaultCalendar();
});
```

### Mẫu 2: Mutation Bắn Sự kiện
Mutation thực hiện hành động của nó và sau đó bắn ra một sự kiện để thông báo cho hệ thống.

```dart
// delete_event.dart
final deleteEvent = createMutationFamily<void, (String, String)>((tsx, params) async {
  final (calendarId, eventId) = params;
  
  // 1. Thực hiện hành động
  await api.deleteEvent(calendarId, eventId);
  
  // 2. Bắn sự kiện (thông qua Store)
  tsx.get(calendarEventBusStore).fire(DeleteCalendarEvent(calendarId, eventId));
});
```
