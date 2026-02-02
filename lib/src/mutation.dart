import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/experimental/mutation.dart';

Provider<MutationAction<T>> createMutation<T>(
  Future<T> Function(MutationTransaction tsx) action,
) => Provider.autoDispose<MutationAction<T>>((ref) {
  final state = Mutation<T>();
  return (
    state,
    () => state.run(ref, (tsx) => action(tsx)),
    () => state.reset(ref),
  );
});

Provider<MutationAction<T>> createMutationPersist<T>(
  Future<T> Function(MutationTransaction tsx) action,
) => Provider<MutationAction<T>>((ref) {
  final state = Mutation<T>();
  return (
    state,
    () => state.run(ref, (tsx) => action(tsx)),
    () => state.reset(ref),
  );
});

Provider<MutationActionWithParam<T, TParam>> createMutationWithParam<T, TParam>(
  Future<T> Function(MutationTransaction tsx, TParam payload) action,
) => Provider.autoDispose<MutationActionWithParam<T, TParam>>((ref) {
  final state = Mutation<T>();
  return (
    (param) => state(param),
    (param) => state(param).run(ref, (tsx) => action(tsx, param)),
    (param) => state(param).reset(ref),
  );
});

Provider<MutationActionWithParam<T, TParam>>
createMutationWithParamPersist<T, TParam>(
  Future<T> Function(MutationTransaction tsx, TParam payload) action,
) => Provider<MutationActionWithParam<T, TParam>>((ref) {
  final state = Mutation<T>();
  return (
    (param) => state(param),
    (param) => state(param).run(ref, (tsx) => action(tsx, param)),
    (param) => state(param).reset(ref),
  );
});

typedef MutationAction<T> = (
  Mutation<T> state,
  Future<T> Function() run,
  void Function() reset,
);

typedef MutationActionWithParam<T, TParam> = (
  Mutation<T> Function(TParam payload) state,
  Future<T> Function(TParam payload) run,
  void Function(TParam payload) reset,
);
