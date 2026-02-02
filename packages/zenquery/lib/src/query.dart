import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart';

FutureProvider<T> createQuery<T>(Future<T> Function(Ref ref) query) =>
    FutureProvider.autoDispose((ref) => query(ref));

FutureProvider<T> createQueryPersist<T>(Future<T> Function(Ref ref) query) =>
    FutureProvider((ref) => query(ref));

FutureProviderFamily<T, TParam> createQueryFamily<T, TParam>(
  Future<T> Function(Ref ref, TParam param) query,
) => FutureProvider.autoDispose.family((ref, param) => query(ref, param));

FutureProviderFamily<T, TParam> createQueryFamilyPersist<T, TParam>(
  Future<T> Function(Ref ref, TParam param) query,
) => FutureProvider.family((ref, param) => query(ref, param));

AsyncNotifierProvider<QueryEditable<NResult>, NResult>
createQueryEditable<NResult>(Future<NResult> Function(Ref ref) query) =>
    AsyncNotifierProvider.autoDispose<QueryEditable<NResult>, NResult>(
      () => QueryEditable(query),
    );

AsyncNotifierProvider<QueryEditable<NResult>, NResult>
createQueryEditablePersist<NResult>(Future<NResult> Function(Ref ref) query) =>
    AsyncNotifierProvider<QueryEditable<NResult>, NResult>(
      () => QueryEditable(query),
    );

AsyncNotifierProviderFamily<
  QueryEditableFamily<NResult, NParam>,
  NResult,
  NParam
>
createQueryEditableFamily<NResult, NParam>(
  Future<NResult> Function(Ref ref, NParam param) query,
) => AsyncNotifierProvider.autoDispose
    .family<QueryEditableFamily<NResult, NParam>, NResult, NParam>(
      (param) => QueryEditableFamily(query, param),
    );

AsyncNotifierProviderFamily<
  QueryEditableFamily<NResult, NParam>,
  NResult,
  NParam
>
createQueryEditableFamilyPersist<NResult, NParam>(
  Future<NResult> Function(Ref ref, NParam param) query,
) =>
    AsyncNotifierProvider.family<
      QueryEditableFamily<NResult, NParam>,
      NResult,
      NParam
    >((param) => QueryEditableFamily(query, param));

class QueryEditable<NResult> extends AsyncNotifier<NResult> {
  QueryEditable(this.query);

  final Future<NResult> Function(Ref ref) query;

  @override
  Future<NResult> build() async => query(ref);

  void setValue(NResult value) => state = AsyncValue.data(value);

  void setError(Object error, StackTrace stackTrace) =>
      state = AsyncValue.error(error, stackTrace);

  void setLoading() => state = AsyncValue.loading();
}

class QueryEditableFamily<NResult, NParam> extends AsyncNotifier<NResult> {
  QueryEditableFamily(this.query, this.param);

  final Future<NResult> Function(Ref ref, NParam param) query;
  final NParam param;

  @override
  Future<NResult> build() async => query(ref, param);

  void setValue(NResult value) => state = AsyncValue.data(value);

  void setError(Object error, StackTrace stackTrace) =>
      state = AsyncValue.error(error, stackTrace);

  void setLoading([num progress = 0]) =>
      state = AsyncValue.loading(progress: progress);
}
