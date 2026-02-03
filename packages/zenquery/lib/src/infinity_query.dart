import 'package:flutter/foundation.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/riverpod.dart';

typedef FetchFunction<T, TCursor> = Future<List<T>> Function(TCursor? cursor);
typedef NextCursorFunction<T, TCursor> =
    TCursor? Function(List<T>? lastPage, List<List<T>> pages);

class InfinityQueryData<T, C> {
  const InfinityQueryData({
    required this.fetchNext,
    required this.refresh,
    required this.pages,
    required this.data,
    required this.hasNext,
    required this.loadState,
  });

  final FutureCallback fetchNext;
  final FutureCallback refresh;
  final ValueNotifier<List<List<T>>> pages;
  final ValueNotifier<List<T>> data;
  final ValueNotifier<bool> hasNext;
  final Mutation<void> loadState;
}

typedef FutureCallback = Future<void> Function();

Provider<InfinityQueryData<T, TCursor>> createInfinityQuery<T, TCursor>({
  required FetchFunction<T, TCursor> fetch,
  required NextCursorFunction<T, TCursor> getNextCursor,
}) => Provider.autoDispose((ref) {
  final query = InfinityQuery<T, TCursor>(
    fetch: fetch,
    getNextCursor: getNextCursor,
  );
  ref.onDispose(query.dispose);
  Future.microtask(() => query.fetchNextPage(ref));

  return InfinityQueryData(
    fetchNext: () => query.fetchNextPage(ref),
    refresh: () => query.refresh(ref),
    pages: query.pages,
    data: query.data,
    hasNext: query.hasNext,
    loadState: query.loadState,
  );
});

Provider<InfinityQueryData<T, TCursor>> createInfinityQueryPersist<T, TCursor>({
  required FetchFunction<T, TCursor> fetch,
  required NextCursorFunction<T, TCursor> getNextCursor,
}) => Provider((ref) {
  final query = InfinityQuery<T, TCursor>(
    fetch: fetch,
    getNextCursor: getNextCursor,
  );
  ref.onDispose(query.dispose);
  return InfinityQueryData(
    fetchNext: () => query.fetchNextPage(ref),
    refresh: () => query.refresh(ref),
    pages: query.pages,
    data: query.data,
    hasNext: query.hasNext,
    loadState: query.loadState,
  );
});

class InfinityQuery<T, TCursor> {
  InfinityQuery({
    required Future<List<T>> Function(TCursor? param) fetch,
    required TCursor? Function(List<T>? current, List<List<T>> all)
    getNextCursor,
  }) : _getNextCursor = getNextCursor,
       _fetch = fetch {
    pages.addListener(_updateData);
  }

  final Mutation<void> loadState = Mutation<void>();
  final ValueNotifier<List<T>> data = ValueNotifier([]);
  final ValueNotifier<List<List<T>>> pages = ValueNotifier([]);
  final ValueNotifier<bool> hasNext = ValueNotifier(true);

  final FetchFunction<T, TCursor> _fetch;
  final NextCursorFunction<T, TCursor> _getNextCursor;

  /// Current flattened data items.
  List<T> get items => data.value;

  /// Whether currently loading more.
  bool isLoading(ProviderContainer container) =>
      container.read(loadState) is MutationPending;

  Object? error(MutationTarget target) {
    final loadState = target.container.read(this.loadState);
    if (loadState is MutationError) {
      return loadState.error;
    }
    return null;
  }

  int _version = 0;

  /// Fetch the first page of data.
  Future<void> _fetchFirstPage(MutationTarget target) async {
    final loadState = target.container.read(this.loadState);
    if (loadState is MutationPending) return;

    final startVersion = _version;

    await this.loadState.run(target, (tsx) async {
      final result = await _fetch(null);
      if (startVersion != _version) return;
      pages.value = [result];
    });

    final nextLoadState = target.container.read(this.loadState);
    if (nextLoadState is MutationSuccess) {
      if (startVersion != _version) {
        // If version changed, we are not actually successfully loaded for the *current* version.
        // But the Mutation state itself is shared.
        // We arguably should reset it if we ignored the result?
        // Actually, if we ignored the result, the mutation success value is for the *old* fetch.
        // The refresh overwrites mutation state?
        // Refresh calls _fetchFirstPage -> loadState.run.
        // If we are pending, refresh waits?
        // Wait, refresh logic needs to be robust.
        return;
      }
      this.loadState.reset(target);
    }
  }

  /// Fetch the next page of data.
  Future<void> fetchNextPage(MutationTarget target) async {
    final loadState = target.container.read(this.loadState);
    if (loadState is MutationPending) return;

    // If no pages yet, fetch first page instead
    if (pages.value.isEmpty) {
      return _fetchFirstPage(target);
    }

    final nextCursor = _getNextCursor(pages.value.last, pages.value);
    if (nextCursor == null) return;

    final startVersion = _version;

    await this.loadState.run(target, (tsx) async {
      final result = await _fetch(nextCursor);
      if (startVersion != _version) return;
      pages.value = [...pages.value, result];
    });

    final nextLoadState = target.container.read(this.loadState);
    if (nextLoadState is MutationSuccess) {
      if (startVersion != _version) return;
      this.loadState.reset(target);
    }
  }

  /// Refresh and reload from the beginning.
  Future<void> refresh(MutationTarget target) async {
    _version++;
    pages.value = [];
    loadState.reset(target);
    await _fetchFirstPage(target);
  }

  void dispose() {
    pages.removeListener(_updateData);
    pages.dispose();
    data.dispose();
  }

  void _updateData() {
    data.value = pages.value.expand((page) => page).toList();
    hasNext.value = _getNextCursor(pages.value.lastOrNull, pages.value) != null;
  }
}
