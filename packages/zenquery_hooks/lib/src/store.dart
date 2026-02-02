import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:zenquery/zenquery.dart';

T useStore<T>(T Function(Ref ref) create) => use(StoreHook<T>(create: create));

class StoreHook<T> extends Hook<T> {
  const StoreHook({super.keys, required this.create});

  final T Function(Ref ref) create;

  @override
  HookState<T, Hook<T>> createState() => _StoreHookState<T>();
}

class _StoreHookState<T> extends HookState<T, StoreHook<T>> {
  late final store = createStore<T>(hook.create);
  ProviderSubscription<T>? _sub;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  T build(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    _sub ??= container.listen(store, (previous, next) => _rebuild());
    return _sub!.read();
  }
}
