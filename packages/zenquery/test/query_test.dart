import 'package:flutter_test/flutter_test.dart';
import 'package:zenquery/zenquery.dart';

void main() {
  group('Query Tests', () {
    test('createQuery fetches data successfully', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createQuery((ref) async => 'fetched data');

      expect(container.read(query), const AsyncValue<String>.loading());

      await container.read(query.future);

      expect(container.read(query).value, 'fetched data');
    });

    test('createQueryPersist stays alive', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createQueryPersist((ref) async => 123);

      await container.read(query.future);
      expect(container.read(query).value, 123);
    });

    test('createQueryEditable allows manual value updates', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createQueryEditable((ref) async => 'initial');

      // Initial load
      expect(container.read(query), const AsyncValue<String>.loading());
      await container.read(query.notifier).future;
      expect(container.read(query).value, 'initial');

      // Manual update
      container.read(query.notifier).setValue('manual update');
      expect(container.read(query).value, 'manual update');
    });

    test('createQueryEditable allows manual error updates', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createQueryEditable((ref) async => 'initial');
      await container.read(query.notifier).future;

      final error = Exception('manual error');
      container.read(query.notifier).setError(error, StackTrace.empty);

      expect(container.read(query).hasError, true);
      expect(container.read(query).error, error);
    });

    test('createQueryEditable allows manual loading updates', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createQueryEditable((ref) async => 'initial');
      await container.read(query.notifier).future;

      container.read(query.notifier).setLoading();

      expect(container.read(query).isLoading, true);
    });
  });
}
