# Query, Mutation, Store API Guide

This architecture enforces a strict patterns using Riverpod. It separates application state into three distinct primitives: **Queries**, **Mutations**, and **Stores**. 

This separation ensures predictablity:
- **Queries**: Fetching & caching data (GET).
- **Mutations**: Changing data & side effects (POST/PUT/DELETE).
- **Stores**: Synchronous dependencies & derived state.

## 1. Naming & Factory Conventions

All primitives are created using global factory functions.

| Factory | Lifecycle | Use Case |
| :--- | :--- | :--- |
| `create[Type]` | **AutoDispose** | Ephemeral screens, search results. Cleans up when unused. |
| `create[Type]Persist` | **KeepAlive** | data that should remain cached (e.g. User Profile). |
| `create[Type]Family` | **Parameterized** | Fetching by ID, Search with query params. |

---

## 2. Queries (`query.dart`)

Queries are for **reading asynchronous data**. They wrap standard `FutureProvider` or `AsyncNotifierProvider`.

### A. Standard Query (`createQuery`)
Use for simple data fetching where you just need to read the value.

```dart
// Definition
final userProfileQuery = createQuery<UserProfile>((ref) async {
  return ref.read(apiStore).users.me();
});

// Usage
class UserProfileWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the query
    final userAsync = ref.watch(userProfileQuery);

    // 2. Handle loading/error/data
    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Failed: $err'),
    );
  }
}
```

### B. Editable Query (`createQueryEditable`)
Use when you need to **manually modify** the cache after fetching, for example, for **Optimistic Updates**.

It exposes a `QueryEditable<T>` notifier with methods:
- `setValue(T)`: force data state.
- `setLoading()`: force loading state.
- `setError(e, s)`: force error state.

```dart
// Definition
final todosQuery = createQueryEditable<List<Todo>>((ref) async {
  return api.fetchTodos();
});

// Optimistic Update usage
void addTodo(WidgetRef ref, Todo newTodo) {
  final notifier = ref.read(todosQuery.notifier);
  
  // 1. Get current data (if available)
  final previousTodos = ref.read(todosQuery).valueOrNull ?? [];
  
  // 2. Optimistically update
  notifier.setValue([...previousTodos, newTodo]);
  
  // 3. Perform network request (logic usually lives in a Mutation)
}
```

---

## 3. Mutations (`mutation.dart`)

Mutations are for **writing data** or performing side effects. They wrap a `MutationAction` class.

**Key Difference from Queries**:
- Queries run automatically when watched.
- Mutations **only run when `.run()` is called**.

### Structure
A mutation provider returns a `MutationAction` object which contains:
- `run()`: The function to execute the logic.
- `state`: A `Mutation<T>` object holding the current status (`data`, `error`, `loading`).
- `reset()`: Resets state to idle.

### Defining a Mutation

```dart
final loginMutation = createMutationFamily<User, LoginCredentials>((tsx, credentials) async {
  // 'tsx' is a MutationTransaction. Use tsx.get() to access other providers.
  return tsx.get(authApiStore).login(credentials);
});
```

### Consuming a Mutation (Critical Pattern)

You must watch **two** things: the action (to run it) and the state (to show spinner).

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // 1. WATCH THE ACTION: Needed to get the .run() method
  final action = ref.watch(loginMutation(myCredentials));

  // 2. WATCH THE STATE: Needed to react to loading/error changes
  final state = ref.watch(action.state);

  return Column(
    children: [
      if (state.hasError) Text(state.error.toString()),
      
      ElevatedButton(
        // Disable button while loading
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
            : const Text('Login'),
      ),
    ],
  );
}
```

### MutationTransaction (`tsx`)
The `transaction` (often named `tsx`) argument in `createMutation` allows you to access other providers.

```dart
final updateEventMutation = createMutation<void>((tsx) async {
  // Use tsx.get() to interact with other stores
  tsx.get(analyticsStore).logEvent('update_started');

  // Use tsx.get() to interact with other queries
  final event = await tsx.get(eventQuery.future);
  
  await api.update(event.copyWith(updatedAt: DateTime.now()));
  
  tsx.get(eventBusStore).fire(EventUpdated());
});
```

---

## 4. Stores (`store.dart`)

Stores are for **Synchronous** dependencies. They are simple wrappers around `Provider`.
Use them for:
- Dependency Injection (Repositories, APIs).
- Derived state that requires no async work.
- Event Buses / Controllers.

```dart
// Definition
final authRepositoryStore = createStore<AuthRepository>((ref) {
  return AuthRepository(client: ref.watch(httpClientStore));
});

// Usage
final repo = ref.watch(authRepositoryStore);
```

---

## Best Practices

1.  **File Structure**:
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

2.  **Barrel File**: A `queries.dart` barrel file should export all files inside `queries/` for cleaner imports in the UI.
    ```dart
    library;
    
    export 'get_user.dart';
    export 'list_items.dart';
    export 'update_user.dart';
    export 'delete_item.dart';
    ```

3.  **Separate Side Effects**: Do not put side effects (navigation, toil) inside the mutation definition if they belong in the UI. Use `await action.run()` in the UI handler (e.g. `onPressed`) to execute after success.

4.  **Use `tsx`**: When inside a mutation, prefer using the `transaction` object if provided for better transactional semantics (future proofing).

5.  **AI Navigation**: Keeping all logic in `queries/` allows AI Agents to easily list the directory and understand every capability of the feature (API) just by reading the descriptive filenames.


