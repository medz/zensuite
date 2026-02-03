import 'package:riverpod/riverpod.dart';
import 'package:riverpod/misc.dart';

/// Creates a [Provider] that automatically disposes of its state when listener count reaches zero.
///
/// This is useful for creating stores (state containers) that are alive only when they are being used.
///
/// [store] is a function that creates the state.
Provider<T> createStore<T>(T Function(Ref ref) store) =>
    Provider.autoDispose((ref) => store(ref));

/// Creates a [Provider] that persists its state even when there are no listeners.
///
/// This is useful for creating global stores that need to maintain their state throughout the application's lifecycle.
///
/// [store] is a function that creates the state.
Provider<T> createStorePersist<T>(T Function(Ref ref) store) =>
    Provider((ref) => store(ref));

/// Creates a [ProviderFamily] that automatically disposes of its state when listener count reaches zero.
///
/// This allows creating a family of stores based on a parameter.
///
/// [store] is a function that creates the state, receiving the [Ref] and the parameter.
ProviderFamily<T, TParam> createStoreFamily<T, TParam>(
  T Function(Ref ref, TParam param) store,
) => Provider.autoDispose.family((ref, param) => store(ref, param));

/// Creates a [ProviderFamily] that persists its state even when there are no listeners.
///
/// This allows creating a family of global stores based on a parameter.
///
/// [store] is a function that creates the state, receiving the [Ref] and the parameter.
ProviderFamily<T, TParam> createStoreFamilyPersist<T, TParam>(
  T Function(Ref ref, TParam param) store,
) => Provider.family((ref, param) => store(ref, param));
