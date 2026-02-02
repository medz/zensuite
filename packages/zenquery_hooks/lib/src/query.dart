import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zenquery/zenquery.dart';

QueryHookResponse<T> useQuery<T>(Future<T> Function(Ref ref) query) =>
    use(QueryHook<T>(query: query));

typedef QueryHookResponse<T> = (AsyncValue<T> data, VoidCallback refetch);

class QueryHook<T> extends Hook<QueryHookResponse<T>> {
  const QueryHook({super.keys, required this.query});

  final Future<T> Function(Ref ref) query;

  @override
  HookState<QueryHookResponse<T>, Hook<QueryHookResponse<T>>> createState() =>
      _QueryHookState<T>();
}

class _QueryHookState<T> extends HookState<QueryHookResponse<T>, QueryHook<T>> {
  late final query = createQuery<T>(hook.query);

  AsyncValue<T> _state = const AsyncValue.loading();
  ProviderSubscription<AsyncValue<T>>? _sub;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  void _invalidate() => ProviderScope.containerOf(context).invalidate(query);

  @override
  QueryHookResponse<T> build(BuildContext context) {
    _sub ??= ProviderScope.containerOf(
      context,
    ).listen(query, (previous, next) => setState(() => _state = next));
    return (_state, _invalidate);
  }
}
