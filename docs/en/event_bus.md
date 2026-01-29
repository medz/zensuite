# Events (EventBus)

The EventBus system provides a way to decouple **Mutations** (Producers) from **Queries** (Consumers).

## How It Works

The `EventBus<T>` class is a lightweight wrapper around a Dart `StreamController<T>.broadcast()`.

1.  **Broadcast Stream**: It uses a broadcast stream allowing multiple listeners (Queries) to subscribe to the same event source simultaneously.
2.  **Type Filtering**: The `.on<E>()` method uses `stream.where((e) => e is E).cast<E>()` to filter events. This ensures that a Query only wakes up for the specific events it cares about, ignoring all others.
3.  **Lifecycle**: When registered as a Store (`createEventBusStorePersist`), the bus is bound to the ProviderContainer's lifecycle.

## Integrate with Query/Mutation

The primary use case is invalidating cache when a mutation occurs.

### Pattern 1: Queries Listen & Invalidate Self
Queries subscribe to specific events and trigger `ref.invalidateSelf()` to re-fetch data.

```dart
// get_default_calendar.dart
final getDefaultCalendar = createQuery<String?>((ref) async {
  // 1. Subscribe to events that should cause this query to refresh
  final sub = ref
      .read(calendarEventBusStore)
      .on<UpdateDefaultCalendar>() // Event Type
      .listen((event) => ref.invalidateSelf());
  
  // 2. Cleanup subscription on dispose
  ref.onDispose(sub.cancel);

  // 3. Fetch data
  return api.fetchDefaultCalendar();
});
```

### Pattern 2: Mutations Fire Events
Mutations perform their action and then fire an event to notify the system.

```dart
// delete_event.dart
final deleteEvent = createMutationFamily<void, (String, String)>((tsx, params) async {
  final (calendarId, eventId) = params;
  
  // 1. Perform Action
  await api.deleteEvent(calendarId, eventId);
  
  // 2. Fire Event (via Store)
  tsx.get(calendarEventBusStore).fire(DeleteCalendarEvent(calendarId, eventId));
});
```
