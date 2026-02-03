# ZenQuery

[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)](https://flutter.dev)

**Backend-agnostic asynchronous state management for Flutter.** A powerful, opinionated wrapper around Riverpod that standardizes data-fetching and mutation patterns, inspired by TanStack Query.

## ✨ Features

- 🌐 **Backend Agnostic** - Works with REST, GraphQL, Firebase, Supabase, or any data source
- 📦 **Simplified Syntax** - Concise wrappers that reduce boilerplate by up to 70%
- ♻️ **Automatic Lifecycle** - Smart `autoDispose` and persistent provider management
- ∞ **Infinite Scrolling** - Built-in pagination support with `InfinityQuery`
- 🔄 **Structured Mutations** - Type-safe side effects with status tracking
- ✏️ **Editable Queries** - Local state management for optimistic updates
- 🎯 **Type Safe** - Full Dart type safety with generics
- 🧩 **Riverpod Powered** - Built on Riverpod's proven architecture

## 🌐 Backend Agnostic Design

ZenQuery doesn't care where your data comes from. It provides a unified interface for any backend:

```dart
// REST API
final restQuery = createQuery((ref) async {
  final response = await http.get(Uri.parse('https://api.example.com/users'));
  return User.fromJson(jsonDecode(response.body));
});

// GraphQL
final graphqlQuery = createQuery((ref) async {
  final result = await client.query(QueryOptions(document: gql(getUserQuery)));
  return User.fromJson(result.data['user']);
});

// Firebase
final firebaseQuery = createQuery((ref) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return User.fromJson(doc.data()!);
});

// Supabase
final supabaseQuery = createQuery((ref) async {
  final data = await Supabase.instance.client.from('users').select().single();
  return User.fromJson(data);
});

// Local Database (Drift, Hive, etc.)
final localQuery = createQuery((ref) async {
  final db = ref.read(databaseProvider);
  return await db.getUser(userId);
});
```

**The pattern stays the same, regardless of your backend.**

## 📦 Installation

Add `zenquery` to your `pubspec.yaml`:

```yaml
dependencies:
  zenquery: ^0.1.0
  flutter_riverpod: ^3.2.0
```

## 🚀 Quick Start

### 1. Wrap Your App

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
```

### 2. Create Your First Query

```dart
import 'package:zenquery/zenquery.dart';

// Define your query
final userQuery = createQuery((ref) async {
  // Works with any backend!
  return await yourApi.fetchUser();
});

// Use in a widget
class UserProfile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userQuery);
    
    return userAsync.when(
      data: (user) => Text('Hello, ${user.name}!'),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### 3. Create a Mutation

```dart
final updateProfileMutation = createMutation<User>((tsx) async {
  // Works with any backend!
  return await yourApi.updateProfile(newData);
});

// Use in a widget
ElevatedButton(
  onPressed: () async {
    final action = ref.read(updateProfileMutation);
    await action.run();
  },
  child: Text('Update Profile'),
)
```

## 📚 Core Concepts

### Store - Synchronous State

A `Store` wraps Riverpod's `Provider` for synchronous state or services that don't involve async operations.

**Use Cases:**
- Dependency injection (API clients, repositories)
- Configuration and settings
- Computed values from other providers

```dart
// API service instance
final apiService = createStore((ref) => ApiService());

// Configuration
final apiConfig = createStore((ref) => ApiConfig(
  baseUrl: 'https://api.example.com',
  timeout: Duration(seconds: 30),
));

// Computed value
final isAuthenticated = createStore((ref) {
  final user = ref.watch(currentUserQuery);
  return user.value != null;
});
```

**Variants:**
- `createStore` - Auto-disposes when unused
- `createStorePersist` - Stays alive throughout app lifecycle
- `createStoreFamily` - Parameterized auto-dispose providers
- `createStoreFamilyPersist` - Parameterized persistent providers

---

### Query - Data Fetching

A `Query` wraps `FutureProvider` for efficient, cacheable data fetching from any backend.

**Use Cases:**
- Fetching user data
- Loading configuration from server
- Reading from databases
- Any async read operation

```dart
// Simple query
final userQuery = createQuery((ref) async {
  final api = ref.read(apiService);
  return await api.fetchUser();
});

// Query with dependencies
final userPostsQuery = createQuery((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  final api = ref.read(apiService);
  return await api.fetchUserPosts(userId);
});

// Persistent query (cached across app)
final appConfigQuery = createQueryPersist((ref) async {
  return await api.fetchAppConfig();
});
```

**Variants:**
- `createQuery` - Auto-disposes when unused
- `createQueryPersist` - Cached throughout app lifecycle
- `createQueryFamily` - Parameterized queries (e.g., by user ID)

**Backend Examples:**

```dart
// REST API
final restUserQuery = createQuery((ref) async {
  final response = await http.get(Uri.parse('$baseUrl/user'));
  return User.fromJson(jsonDecode(response.body));
});

// GraphQL
final graphqlUserQuery = createQuery((ref) async {
  final result = await client.query(QueryOptions(document: gql('''
    query GetUser {
      user { id name email }
    }
  ''')));
  return User.fromJson(result.data['user']);
});

// Firebase Firestore
final firestoreUserQuery = createQuery((ref) async {
  final snapshot = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();
  return User.fromJson(snapshot.data()!);
});
```

---

### Editable Query - Optimistic Updates

Sometimes you need to update query state locally (e.g., optimistic updates). `createQueryEditable` wraps `AsyncNotifierProvider` for mutable queries.

**Use Cases:**
- Optimistic UI updates
- Local edits before saving
- Manual cache updates after mutations

```dart
final editableUserQuery = createQueryEditable((ref) async {
  return await api.fetchUser();
});

// Update locally
ref.read(editableUserQuery.notifier).setValue(updatedUser);

// Or update with async operation
ref.read(editableUserQuery.notifier).update((user) async {
  return user.copyWith(name: 'New Name');
});
```

**Example: Optimistic Update**

```dart
final updateNameMutation = createMutation<User>((tsx) async {
  final newName = tsx.container.read(newNameProvider);
  
  // Optimistically update UI
  final currentUser = tsx.container.read(editableUserQuery).value;
  if (currentUser != null) {
    tsx.container.read(editableUserQuery.notifier)
      .setValue(currentUser.copyWith(name: newName));
  }
  
  try {
    // Perform actual update
    return await api.updateUserName(newName);
  } catch (e) {
    // Rollback on error
    if (currentUser != null) {
      tsx.container.read(editableUserQuery.notifier).setValue(currentUser);
    }
    rethrow;
  }
});
```

---

### Mutation - Side Effects

Mutations handle write operations (POST, PUT, DELETE) with built-in status tracking and error handling.

**Use Cases:**
- Creating, updating, or deleting data
- Form submissions
- Any operation that modifies server state

```dart
// Simple mutation
final createPostMutation = createMutation<Post>((tsx) async {
  final content = tsx.container.read(postContentProvider);
  return await api.createPost(content);
});

// Mutation with parameters
final deletePostMutation = createMutationWithParam<void, String>((tsx, postId) async {
  await api.deletePost(postId);
});

// Usage in widget
final action = ref.read(createPostMutation);
final mutation = action.mutation;

// Check status
if (mutation is MutationPending) {
  // Show loading
} else if (mutation is MutationSuccess<Post>) {
  // Show success with mutation.data
} else if (mutation is MutationError) {
  // Show error with mutation.error
}

// Execute mutation
await action.run();
// Invalidate query
ref.invalidate(getPostsQuery); // See #Integration with ZenBus for better approach

// Reset mutation state
action.reset();
```

**Backend Examples:**

```dart
// REST API
final restCreateMutation = createMutationWithParam<Post, PostData>((tsx, data) async {
  final response = await http.post(
    Uri.parse('$baseUrl/posts'),
    body: jsonEncode(data.toJson()),
  );
  return Post.fromJson(jsonDecode(response.body));
});

// GraphQL
final graphqlCreateMutation = createMutationWithParam<Post, PostData>((tsx, data) async {
  final result = await client.mutate(MutationOptions(
    document: gql(createPostMutation),
    variables: data.toJson(),
  ));
  return Post.fromJson(result.data['createPost']);
});

// Firebase
final firebaseCreateMutation = createMutationWithParam<Post, PostData>((tsx, data) async {
  final docRef = await FirebaseFirestore.instance
    .collection('posts')
    .add(data.toJson());
  return Post.fromJson({...data.toJson(), 'id': docRef.id});
});
```

**Variants:**
- `createMutation` - No parameters
- `createMutationWithParam` - Accepts parameters
- `createMutationPersist` / `createMutationWithParamPersist` - Persistent versions

---

### Infinity Query - Pagination

Complete solution for infinite scrolling and pagination, backend-agnostic.

**Use Cases:**
- Social media feeds
- Product listings
- Search results
- Any paginated data

```dart
final postsQuery = createInfinityQuery<Post, int>(
  fetch: (cursor) async {
    // cursor is null for first page, then 1, 2, 3...
    final page = cursor ?? 0;
    return await api.fetchPosts(page: page, limit: 20);
  },
  getNextCursor: (lastPage, allPages) {
    // Return null when no more pages
    if (lastPage == null || lastPage.isEmpty) return null;
    return allPages.length; // Next page number
  },
);

// Usage in widget
class PostsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(postsQuery);
    final posts = query.data.value; // Flattened list of all posts
    
    return ListView.builder(
      itemCount: posts.length + (query.hasNext.value ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == posts.length) {
          // Load more trigger
          query.fetchNext();
          return CircularProgressIndicator();
        }
        return PostCard(post: posts[index]);
      },
    );
  }
}
```

**Backend Examples:**

```dart
// REST API with offset pagination
final restPostsQuery = createInfinityQuery<Post, int>(
  fetch: (cursor) async {
    final offset = (cursor ?? 0) * 20;
    final response = await http.get(
      Uri.parse('$baseUrl/posts?offset=$offset&limit=20'),
    );
    return (jsonDecode(response.body) as List)
      .map((json) => Post.fromJson(json))
      .toList();
  },
  getNextCursor: (lastPage, allPages) {
    return lastPage?.isEmpty ?? true ? null : allPages.length;
  },
);

// GraphQL with cursor pagination
final graphqlPostsQuery = createInfinityQuery<Post, String>(
  fetch: (cursor) async {
    final result = await client.query(QueryOptions(
      document: gql('''
        query GetPosts(\$after: String) {
          posts(first: 20, after: \$after) {
            edges { node { id title content } }
            pageInfo { endCursor hasNextPage }
          }
        }
      '''),
      variables: {'after': cursor},
    ));
    return result.data['posts']['edges']
      .map((edge) => Post.fromJson(edge['node']))
      .toList();
  },
  getNextCursor: (lastPage, allPages) {
    // Extract cursor from last query result
    return hasNextPage ? endCursor : null;
  },
);

// Firebase with cursor pagination
final firebasePostsQuery = createInfinityQuery<Post, DocumentSnapshot>(
  fetch: (cursor) async {
    var query = FirebaseFirestore.instance
      .collection('posts')
      .orderBy('createdAt', descending: true)
      .limit(20);
    
    if (cursor != null) {
      query = query.startAfterDocument(cursor);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Post.fromJson(doc.data())).toList();
  },
  getNextCursor: (lastPage, allPages) {
    return lastPage?.isEmpty ?? true ? null : lastDocumentSnapshot;
  },
);
```

**API:**
- `query.data` - `ValueNotifier<List<T>>` of all items
- `query.pages` - `ValueNotifier<List<List<T>>>` of pages
- `query.hasNext` - `ValueNotifier<bool>` for more pages
- `query.loadState` - `Mutation<void>` for loading status
- `query.fetchNext()` - Load next page
- `query.refresh()` - Reload from beginning

---

## 🤝 Integration with ZenBus

You can use **ZenBus** (part of ZenSuite) to decouple your mutations from your queries. We recommend creating a **domain-specific bus** and using the `where` parameter to filter events efficiently.

### 1. Define Domain Events

Use a sealed class or base class for your domain events.

```dart
sealed class UserEvent {}

class UserUpdatedEvent extends UserEvent {
  final String userId;
  final User? newUser;
  UserUpdatedEvent(this.userId, {this.newUser});
}

class UserDeletedEvent extends UserEvent {
  final String userId;
  UserDeletedEvent(this.userId);
}
```

### 2. Create the Domain Bus

Create a single bus for the user domain.

```dart
final userBus = createStore((ref) => ZenBus<UserEvent>.alienSignals());
```

### 3. The Query (Filtered Subscription)

The query subscribes to the domain bus but *only* receives relevant events using the `where` filter. ZenBus optimizations ensure this is extremely fast.

```dart
final userQuery = createQueryFamily<User, String>((ref, userId) async {
  // Subscribe with filter
  final sub = ref.read(userBus).listen(
    (event) {
      if (event is UserUpdatedEvent) {
        // 🔄 Self-invalidate to trigger a refresh
        ref.invalidateSelf();
      }
    },
    // ⚡️ Performance: Only wake up listener for this user
    where: (event) => 
      (event is UserUpdatedEvent && event.userId == userId) ||
      (event is UserDeletedEvent && event.userId == userId),
  );
  
  ref.onDispose(sub.cancel);

  return await api.fetchUser(userId);
});
```

### 4. The Mutation (Fire Event)

Mutations simply fire events on the domain bus.

```dart
final updateUserMutation = createMutation<User>((tsx) async {
  final updatedUser = await api.updateUser(...);
  
  // 🔥 Fire event
  tsx.get(userBus).fire(
    UserUpdatedEvent(updatedUser.id, newUser: updatedUser),
  );
  
  return updatedUser;
});
```


## 🎯 Real-World Examples

### Example 1: User Profile with Mutations

```dart
// Queries
final userQuery = createQueryEditable((ref) async {
  final api = ref.read(apiService);
  return await api.fetchCurrentUser();
});

// Mutations
final updateProfileMutation = createMutationWithParam<User, ProfileData>(
  (tsx, data) async {
    final api = tsx.container.read(apiService);
    
    // Optimistic update
    final current = tsx.container.read(userQuery).value;
    if (current != null) {
      tsx.container.read(userQuery.notifier).setValue(
        current.copyWith(name: data.name, bio: data.bio),
      );
    }
    
    try {
      return await api.updateProfile(data);
    } catch (e) {
      // Rollback on error
      if (current != null) {
        tsx.container.read(userQuery.notifier).setValue(current);
      }
      rethrow;
    }
  },
);

// Widget
class ProfileScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userQuery);
    final updateAction = ref.read(updateProfileMutation);
    
    return userAsync.when(
      data: (user) => Column(
        children: [
          Text(user.name),
          ElevatedButton(
            onPressed: () async {
              await updateAction.run(ProfileData(
                name: 'New Name',
                bio: 'New Bio',
              ));
            },
            child: updateAction.mutation is MutationPending
              ? CircularProgressIndicator()
              : Text('Update Profile'),
          ),
        ],
      ),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

### Example 2: Infinite Scroll Feed

```dart
final feedQuery = createInfinityQuery<Post, String>(
  fetch: (cursor) async {
    final api = ref.read(apiService);
    return await api.fetchFeed(cursor: cursor, limit: 20);
  },
  getNextCursor: (lastPage, allPages) {
    return lastPage?.isEmpty ?? true ? null : lastPage.last.id;
  },
);

class FeedScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(feedQuery);
    final posts = query.data.value;
    
    return RefreshIndicator(
      onRefresh: query.refresh,
      child: ListView.builder(
        itemCount: posts.length + (query.hasNext.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == posts.length) {
            query.fetchNext();
            return Center(child: CircularProgressIndicator());
          }
          return PostCard(post: posts[index]);
        },
      ),
    );
  }
}
```

## 📖 API Reference

### Creation Functions

| Function | Return Type | Lifecycle | Use Case |
|----------|-------------|-----------|----------|
| `createStore` | `Provider` | Auto Dispose | Synchronous state/services |
| `createStorePersist` | `Provider` | Keep Alive | App-wide services |
| `createStoreFamily` | `ProviderFamily` | Auto Dispose | Parameterized state |
| `createQuery` | `FutureProvider` | Auto Dispose | Data fetching |
| `createQueryPersist` | `FutureProvider` | Keep Alive | App-wide data |
| `createQueryEditable` | `AsyncNotifierProvider` | Auto Dispose | Mutable queries |
| `createMutation` | `Provider<MutationAction>` | Auto Dispose | Side effects |
| `createMutationWithParam` | `Provider<MutationAction>` | Auto Dispose | Parameterized mutations |
| `createInfinityQuery` | `Provider<InfinityQueryData>` | Auto Dispose | Pagination |

## 🤝 Dependencies

- `flutter_riverpod` - State management foundation
- `riverpod` - Core provider system

## 🌟 Why ZenQuery?

### Before ZenQuery

```dart
final userProvider = FutureProvider.autoDispose<User>((ref) async {
  return await api.fetchUser();
});

final updateUserProvider = Provider.autoDispose<void>((ref) {
  // Complex mutation setup...
});
```

### After ZenQuery

```dart
final userQuery = createQuery((ref) async => await api.fetchUser());
final updateMutation = createMutation<User>((tsx) async => await api.updateUser());
```

**70% less boilerplate. 100% more clarity.**

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Inspired by [TanStack Query](https://tanstack.com/query)
- Built on [Riverpod](https://riverpod.dev)

## 📞 Support

- 🐛 [Report a bug](https://github.com/definev/zensuite/issues)
- 💡 [Request a feature](https://github.com/definev/zensuite/issues)
- 📖 [View documentation](https://github.com/definev/zensuite/tree/main/packages/zenquery)

---

Made with ❤️ by Bui Dai Duong
