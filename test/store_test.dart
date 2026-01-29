import 'package:flutter_test/flutter_test.dart';
import 'package:zenquery/zenquery.dart';

void main() {
  group('Store Tests', () {
    test('createStore creates an autoDispose provider with initial value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store = createStore((ref) => 42);

      expect(container.read(store), 42);
    });

    test('createStorePersist creates a persistent provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store = createStorePersist((ref) => 'test');

      expect(container.read(store), 'test');
    });

    test('createStoreFamily creates providers based on params', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final storeFamily = createStoreFamily<String, int>(
        (ref, param) => 'Value: $param',
      );

      expect(container.read(storeFamily(1)), 'Value: 1');
      expect(container.read(storeFamily(2)), 'Value: 2');
    });

    test(
      'createStoreFamilyPersist creates persistent providers based on params',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final storeFamily = createStoreFamilyPersist<int, int>(
          (ref, param) => param * 2,
        );

        expect(container.read(storeFamily(10)), 20);
      },
    );
  });
}
