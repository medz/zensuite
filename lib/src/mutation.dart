import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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

ProviderFamily<MutationAction<T>, TParam> createMutationFamily<T, TParam>(
  Future<T> Function(MutationTransaction tsx, TParam payload) action,
) => Provider.autoDispose.family<MutationAction<T>, TParam>((ref, param) {
  final state = Mutation<T>();
  return (
    state,
    () => state.run(ref, (tsx) => action(tsx, param)),
    () => state.reset(ref),
  );
});

ProviderFamily<MutationAction<T>, TParam>
createMutationFamilyPersist<T, TParam>(
  Future<T> Function(MutationTransaction tsx, TParam payload) action,
) => Provider.family<MutationAction<T>, TParam>((ref, param) {
  final state = Mutation<T>();
  return (
    state,
    () => state.run(ref, (tsx) => action(tsx, param)),
    () => state.reset(ref),
  );
});

typedef MutationAction<T> = (
  Mutation<T> state,
  Future<T> Function() run,
  void Function() reset,
);
