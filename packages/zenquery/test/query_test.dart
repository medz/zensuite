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

    test('createQueryFamily fetches data with params', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queryFamily = createQueryFamily<String, int>(
        (ref, param) async => 'fetched $param',
      );

      await container.read(queryFamily(1).future);
      await container.read(queryFamily(2).future);

      expect(container.read(queryFamily(1)).value, 'fetched 1');
      expect(container.read(queryFamily(2)).value, 'fetched 2');
    });

    test('createQueryFamilyPersist stays alive with params', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queryFamily = createQueryFamilyPersist<int, int>(
        (ref, param) async => param * 10,
      );

      await container.read(queryFamily(5).future);

      expect(container.read(queryFamily(5)).value, 50);
    });

    test('createQueryEditablePersist allows manual updates', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createQueryEditablePersist((ref) async => 'initial');

      await container.read(query.notifier).future;
      expect(container.read(query).value, 'initial');

      container.read(query.notifier).setValue('persistent update');
      expect(container.read(query).value, 'persistent update');
    });

    test(
      'createQueryEditableFamily allows manual updates with params',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final queryFamily = createQueryEditableFamily<String, int>(
          (ref, param) async => 'initial $param',
        );

        await container.read(queryFamily(1).notifier).future;
        expect(container.read(queryFamily(1)).value, 'initial 1');

        container.read(queryFamily(1).notifier).setValue('updated 1');
        expect(container.read(queryFamily(1)).value, 'updated 1');
      },
    );

    test('createQueryEditableFamilyPersist stays alive with params', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queryFamily = createQueryEditableFamilyPersist<String, int>(
        (ref, param) async => 'persistent $param',
      );

      await container.read(queryFamily(100).notifier).future;
      expect(container.read(queryFamily(100)).value, 'persistent 100');

      container.read(queryFamily(100).notifier).setValue('modified 100');
      expect(container.read(queryFamily(100)).value, 'modified 100');
    });

    test('QueryEditableFamily setLoading with progress', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queryFamily = createQueryEditableFamily<String, int>(
        (ref, param) async => 'data $param',
      );

      await container.read(queryFamily(1).notifier).future;

      container.read(queryFamily(1).notifier).setLoading(0.5);

      final state = container.read(queryFamily(1));
      expect(state.isLoading, true);
    });

    test('QueryEditableFamily setError sets error state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queryFamily = createQueryEditableFamily<String, int>(
        (ref, param) async => 'data $param',
      );

      await container.read(queryFamily(1).notifier).future;

      final error = Exception('family error');
      container.read(queryFamily(1).notifier).setError(error, StackTrace.empty);

      expect(container.read(queryFamily(1)).hasError, true);
      expect(container.read(queryFamily(1)).error, error);
    });
  });
}
