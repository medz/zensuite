import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:zenquery/zenquery.dart';

class InfinityQueryHookResponse<T, TCursor> {
  InfinityQueryHookResponse({
    required this.fetchNext,
    required this.refresh,
    required this.pages,
    required this.data,
    required this.hasMore,
    required this.loadState,
  });

  final VoidCallback fetchNext;
  final VoidCallback refresh;
  final List<List<T>> pages;
  final List<T> data;
  final bool hasMore;
  final MutationState<void> loadState;
}

InfinityQueryHookResponse<T, TCursor> useInfinityQuery<T, TCursor>({
  required FetchFunction<T, TCursor> fetch,
  required NextCursorFunction<T, TCursor> getNextCursor,
}) => use(
  InfinityQueryHook<T, TCursor>(fetch: fetch, getNextCursor: getNextCursor),
);

class InfinityQueryHook<T, TCursor>
    extends Hook<InfinityQueryHookResponse<T, TCursor>> {
  const InfinityQueryHook({
    super.keys,
    required this.fetch,
    required this.getNextCursor,
  });

  final FetchFunction<T, TCursor> fetch;
  final NextCursorFunction<T, TCursor> getNextCursor;

  @override
  // ignore: library_private_types_in_public_api
  _InfinityQueryHookState<T, TCursor> createState() =>
      _InfinityQueryHookState<T, TCursor>();
}

class _InfinityQueryHookState<T, TCursor>
    extends
        HookState<
          InfinityQueryHookResponse<T, TCursor>,
          InfinityQueryHook<T, TCursor>
        > {
  late final query = createInfinityQuery<T, TCursor>(
    fetch: hook.fetch,
    getNextCursor: hook.getNextCursor,
  );

  ProviderSubscription<MutationState<void>>? _mutationSub;
  ProviderSubscription<InfinityQueryData<T, TCursor>>? _sub;

  @override
  void dispose() {
    _mutationSub?.close();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  InfinityQueryHookResponse<T, TCursor> build(BuildContext context) {
    final container = ProviderScope.containerOf(context);

    // Read the current data
    _sub ??= container.listen(query, (previous, next) => _rebuild());
    final data = _sub!.read();
    // Also listen to the mutation state
    _mutationSub ??= container.listen(
      data.loadState,
      (prev, next) => _rebuild(),
    );
    data.data.removeListener(_rebuild);
    data.hasMore.removeListener(_rebuild);

    data.data.addListener(_rebuild);
    data.hasMore.addListener(_rebuild);

    return InfinityQueryHookResponse(
      fetchNext: () => data.fetchNext(container),
      refresh: () => data.refresh(container),
      pages: data.pages.value,
      data: data.data.value,
      hasMore: data.hasMore.value,
      loadState: _mutationSub!.read(),
    );
  }
}
