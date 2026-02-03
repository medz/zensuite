import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';

class MutationAction<T> {
  MutationAction(this.mutation, this.run, this.reset);

  final Mutation<T> mutation;
  final Future<T> Function() run;
  final void Function() reset;
}

class MutationActionWithParam<T, TParam> {
  MutationActionWithParam(this.mutation, this.run, this.reset);

  final Mutation<T> Function(TParam payload) mutation;
  final Future<T> Function(TParam payload) run;
  final void Function(TParam payload) reset;
}

Provider<MutationAction<T>> createMutation<T>(
  Future<T> Function(MutationTransaction tsx) action,
) => Provider.autoDispose<MutationAction<T>>((ref) {
  final state = Mutation<T>();
  return MutationAction(
    state,
    () => state.run(ref, (tsx) => action(tsx)),
    () => state.reset(ref),
  );
});

Provider<MutationAction<T>> createMutationPersist<T>(
  Future<T> Function(MutationTransaction tsx) action,
) => Provider<MutationAction<T>>((ref) {
  final state = Mutation<T>();
  return MutationAction(
    state,
    () => state.run(ref, (tsx) => action(tsx)),
    () => state.reset(ref),
  );
});

Provider<MutationActionWithParam<T, TParam>> createMutationWithParam<T, TParam>(
  Future<T> Function(MutationTransaction tsx, TParam payload) action,
) => Provider.autoDispose<MutationActionWithParam<T, TParam>>((ref) {
  final state = Mutation<T>();
  final mutationMap = <TParam, Mutation<T>>{};
  ref.onDispose(() => mutationMap.clear());
  return MutationActionWithParam(
    (param) => mutationMap.putIfAbsent(param, () => state(param)),
    (param) => mutationMap
        .putIfAbsent(param, () => state(param))
        .run(ref, (tsx) => action(tsx, param)),
    (param) => mutationMap.putIfAbsent(param, () => state(param)).reset(ref),
  );
});

Provider<MutationActionWithParam<T, TParam>>
createMutationWithParamPersist<T, TParam>(
  Future<T> Function(MutationTransaction tsx, TParam payload) action,
) => Provider<MutationActionWithParam<T, TParam>>((ref) {
  final state = Mutation<T>();
  final mutationMap = <TParam, Mutation<T>>{};
  ref.onDispose(() => mutationMap.clear());
  return MutationActionWithParam(
    (param) => mutationMap.putIfAbsent(param, () => state(param)),
    (param) => mutationMap
        .putIfAbsent(param, () => state(param))
        .run(ref, (tsx) => action(tsx, param)),
    (param) => mutationMap.putIfAbsent(param, () => state(param)).reset(ref),
  );
});
