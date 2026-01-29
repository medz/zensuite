import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:zenquery/zenquery.dart';

// Mock MutationTarget as we cannot instantiate the abstract class directly
// and using Ref inside a provider to call methods caused "modifying other providers during build" error.
class TestMutationTarget implements MutationTarget {
  TestMutationTarget(this.container);

  @override
  final ProviderContainer container;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('InfinityQuery Tests', () {
    test('createInfinityQuery fetches first page', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createInfinityQuery<int, int>(
        fetch: (cursor) async => [1, 2, 3],
        getNextCursor: (lastPage, allPages) => null,
      );

      final data = container.read(query);

      // Initial state
      expect(data.data.value, isEmpty);
      expect(container.read(data.stateProvider), isA<MutationIdle>());

      final target = TestMutationTarget(container);

      // Fetch first page
      await data.fetchNext(target);

      expect(data.data.value, [1, 2, 3]);
      expect(data.pages.value.length, 1);
      expect(data.hasMore.value, false);
    });

    test('createInfinityQuery fetches next page', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createInfinityQuery<int, int>(
        fetch: (cursor) async {
          if (cursor == null) return [1, 2];
          return [3, 4];
        },
        getNextCursor: (lastPage, allPages) => allPages.length < 2 ? 1 : null,
      );

      final data = container.read(query);
      final target = TestMutationTarget(container);

      // Fetch first page
      await data.fetchNext(target);
      expect(data.data.value, [1, 2]);
      expect(data.hasMore.value, true);

      // Fetch next page
      await data.fetchNext(target);

      expect(data.data.value, [1, 2, 3, 4]);
      expect(data.pages.value.length, 2);
      expect(data.hasMore.value, false);
    });

    test('createInfinityQuery refresh resets data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createInfinityQuery<int, int>(
        fetch: (cursor) async => [1, 2, 3],
        getNextCursor: (lastPage, allPages) => null,
      );

      final data = container.read(query);
      final target = TestMutationTarget(container);

      await data.fetchNext(target);
      expect(data.data.value, [1, 2, 3]);

      await data.refresh(target);

      expect(data.data.value, [1, 2, 3]);
      // Verify it's a fresh load by ensuring pages count is 1 after refresh
      expect(data.pages.value.length, 1);
    });
  });
}
