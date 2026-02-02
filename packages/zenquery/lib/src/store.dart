import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

Provider<T> createStore<T>(T Function(Ref ref) store) =>
    Provider.autoDispose((ref) => store(ref));

Provider<T> createStorePersist<T>(T Function(Ref ref) store) =>
    Provider((ref) => store(ref));

ProviderFamily<T, TParam> createStoreFamily<T, TParam>(
  T Function(Ref ref, TParam param) store,
) => Provider.autoDispose.family((ref, param) => store(ref, param));

ProviderFamily<T, TParam> createStoreFamilyPersist<T, TParam>(
  T Function(Ref ref, TParam param) store,
) => Provider.family((ref, param) => store(ref, param));
