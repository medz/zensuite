import 'package:flutter/foundation.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:riverpod/riverpod.dart';

typedef FetchFunction<T, TCursor> = Future<List<T>> Function(TCursor? cursor);
typedef NextCursorFunction<T, TCursor> =
    TCursor? Function(List<T>? lastPage, List<List<T>> pages);
typedef InfinityQueryData<T, C> = ({
  MutationTargetFutureCallback fetchNext,
  MutationTargetFutureCallback refresh,
  ValueNotifier<List<List<T>>> pages,
  ValueNotifier<List<T>> data,
  ValueNotifier<bool> hasMore,
  Mutation<void> stateProvider,
});

typedef MutationTargetFutureCallback =
    Future<void> Function(MutationTarget target);

Provider<InfinityQueryData<T, TCursor>> createInfinityQuery<T, TCursor>({
  required FetchFunction<T, TCursor> fetch,
  required NextCursorFunction<T, TCursor> getNextCursor,
}) => Provider.autoDispose((ref) {
  final query = InfinityQuery<T, TCursor>(
    fetch: fetch,
    getNextCursor: getNextCursor,
  );
  ref.onDispose(query.dispose);
  return (
    fetchNext: query.fetchNextPage,
    refresh: query.refresh,
    pages: query.pages,
    data: query.data,
    hasMore: query.hasNext,
    stateProvider: query.loadState,
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
  return (
    fetchNext: query.fetchNextPage,
    refresh: query.refresh,
    pages: query.pages,
    data: query.data,
    hasMore: query.hasNext,
    stateProvider: query.loadState,
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

  /// Fetch the first page of data.
  Future<void> fetchFirstPage(MutationTarget target) async {
    final loadState = target.container.read(this.loadState);
    if (loadState is MutationPending) return;

    await this.loadState.run(target, (tsx) async {
      final result = await _fetch(null);
      pages.value = [result];
    });

    final nextLoadState = target.container.read(this.loadState);
    if (nextLoadState is MutationSuccess) {
      this.loadState.reset(target);
    }
  }

  /// Fetch the next page of data.
  Future<void> fetchNextPage(MutationTarget target) async {
    final loadState = target.container.read(this.loadState);
    if (loadState is MutationPending) return;

    // If no pages yet, fetch first page instead
    if (pages.value.isEmpty) {
      return fetchFirstPage(target);
    }

    final nextCursor = _getNextCursor(pages.value.last, pages.value);
    if (nextCursor == null) return;

    await this.loadState.run(target, (tsx) async {
      final result = await _fetch(nextCursor);
      pages.value = [...pages.value, result];
    });

    final nextLoadState = target.container.read(this.loadState);
    if (nextLoadState is MutationSuccess) {
      this.loadState.reset(target);
    }
  }

  /// Refresh and reload from the beginning.
  Future<void> refresh(MutationTarget target) async {
    pages.value = [];
    await fetchFirstPage(target);
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
