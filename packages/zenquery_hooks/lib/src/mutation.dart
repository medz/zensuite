import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:zenquery/zenquery.dart';

MutationAction<T> useMutationAction<T>(
  Future<T> Function(MutationTransaction tsx) action,
) => use(MutationHook<T>(action: action));

class MutationHook<T> extends Hook<MutationAction<T>> {
  const MutationHook({super.keys, required this.action});

  final Future<T> Function(MutationTransaction tsx) action;

  @override
  HookState<MutationAction<T>, Hook<MutationAction<T>>> createState() =>
      _MutationHookState<T>();
}

class _MutationHookState<T>
    extends HookState<MutationAction<T>, MutationHook<T>> {
  late final mutation = createMutation<T>(hook.action);
  ProviderSubscription? _sub;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  MutationAction<T> build(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    _sub = container.listen(mutation, (previous, next) => setState(() {}));
    return container.read(mutation);
  }
}

MutationActionWithParam<T, TParam> useMutationActionWithParam<T, TParam>(
  Future<T> Function(MutationTransaction tsx, TParam payload) action,
) {
  return use(_MutationWithParamHook<T, TParam>(action: action))
      as MutationActionWithParam<T, TParam>;
}

class _MutationWithParamHook<T, TParam> extends Hook<Object> {
  const _MutationWithParamHook({super.keys, required this.action});

  final Future<T> Function(MutationTransaction tsx, TParam payload) action;

  @override
  HookState<Object, Hook<Object>> createState() =>
      _MutationWithParamHookState<T, TParam>();
}

class _MutationWithParamHookState<T, TParam>
    extends HookState<Object, _MutationWithParamHook<T, TParam>> {
  late final mutation = createMutationWithParam<T, TParam>(hook.action);
  ProviderSubscription? _sub;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  MutationActionWithParam<T, TParam> build(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    _sub = container.listen(mutation, (previous, next) => setState(() {}));
    return container.read(mutation);
  }
}

MutationState<T> useMutationState<T>(Mutation<T> mutation) =>
    use(MutationProviderHook<T>(mutation: mutation));

class MutationProviderHook<T> extends Hook<MutationState<T>> {
  const MutationProviderHook({super.keys, required this.mutation});

  final Mutation<T> mutation;

  @override
  HookState<MutationState<T>, Hook<MutationState<T>>> createState() =>
      _MutationProviderHookState<T>();
}

class _MutationProviderHookState<T>
    extends HookState<MutationState<T>, MutationProviderHook<T>> {
  ProviderSubscription<MutationState<T>>? _sub;

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  MutationState<T> build(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    _sub ??= container.listen(
      hook.mutation,
      (previous, next) => setState(() {}),
    );
    return _sub!.read();
  }
}
