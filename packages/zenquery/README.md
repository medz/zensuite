# ZenQuery

Standardize your data-fetching and data-mutation logic flow. A thin wrapper around Riverpod to reduce boilerplate code.

## Features

- **Simplified Syntax**: concise wrappers for creating Stores, Queries, and Mutations.
- **Automatic Lifecycle Management**: Built-in support for `autoDispose` and persistent providers.
- **Infinite Scrolling**: Robust support for paginated data with `createInfinityQuery`.
- **Mutations**: Structured way to handle side effects with optimistic updates and rollbacks.
- **Editable Queries**: Easily manage local state updates for fetched data.

## Installation

Add `zenquery` to your `pubspec.yaml`:

```yaml
dependencies:
  zenquery: 
```

## Core Concepts

ZenQuery is built on top of Riverpod and introduces a few core concepts to standardize state management.

### Store

A `Store` is a simple wrapper around `Provider`. It's used for synchronous state or logic that doesn't involve asynchronous operations.

- `createStore`: Creates an `autoDispose` provider.
- `createStorePersist`: Creates a provider that stays alive.
- `createStoreFamily`: Creates a family of `autoDispose` providers.
- `createStoreFamilyPersist`: Creates a family provider that stays alive.

```dart
final counterStore = createStore((ref) => 0);
```

### Query

A `Query` is a wrapper around `FutureProvider`. It's designed for fetching data efficiently.

- `createQuery`: Creates an `autoDispose` future provider.
- `createQueryPersist`: Creates a future provider that stays alive.

```dart
final userQuery = createQuery((ref) async {
  return await api.fetchUser();
});
```

#### Editable Query

Sometimes you need to manually update the state of a query (e.g., after a mutation). `createQueryEditable` wraps `AsyncNotifierProvider` to allow local modifications.

```dart
final editableUserQuery = createQueryEditable((ref) async {
  return await api.fetchUser();
});

// Updating the state
ref.read(editableUserQuery.notifier).setValue(newUser);
```

### Mutation

Mutations are for performing side effects (POST, PUT, DELETE requests). They provide a structured way to track the status of the operation (idle, pending, success, error).

- `createMutation`: Creates an `autoDispose` mutation.

```dart
final updateProfileMutation = createMutation<User>((tsx) async {
  return await api.updateProfile(tsx);
});

// Usage in a Widget
ref.read(updateProfileMutation).run();
```

### Infinity Query

`InfinityQuery` is a complete solution for handling paginated lists (infinite scrolling). It manages pages, loading states, and cursors for you.

```dart
final postsQuery = createInfinityQuery<Post, int>(
  fetch: (cursor) async => await api.fetchPosts(page: cursor ?? 0),
  getNextCursor: (lastPage, allPages) => lastPage.isEmpty ? null : allPages.length,
);

// Usage
final postsData = ref.watch(postsQuery);
// postsData.data (ValueNotifier<List<Post>>)
// postsData.fetchNext(target)
```

## API Reference

### Creation Functions

Most creators follow this naming convention:

| Function Name | Return Type | Lifecycle | Description |
|---|---|---|---|
| `create[Type]` | `AutoDisposeProvider` | Auto Dispose | Standard creator, disposes when unused. |
| `create[Type]Persist` | `Provider` | Keep Alive | Persists state even when unused. |
| `create[Type]Family` | `AutoDisposeFamily` | Auto Dispose | Creates a family of providers based on parameters. |

## Dependencies

- flutter_riverpod
- riverpod
