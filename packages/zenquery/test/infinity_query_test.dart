import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:zenquery/zenquery.dart';

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
      expect(container.read(data.loadState), isA<MutationIdle>());

      // Fetch first page
      await data.fetchNext();

      expect(data.data.value, [1, 2, 3]);
      expect(data.pages.value.length, 1);
      expect(data.hasNext.value, false);
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

      // Fetch first page
      await data.fetchNext();
      expect(data.data.value, [1, 2]);
      expect(data.hasNext.value, true);

      // Fetch next page
      await data.fetchNext();

      expect(data.data.value, [1, 2, 3, 4]);
      expect(data.pages.value.length, 2);
      expect(data.hasNext.value, false);
    });

    test('createInfinityQuery refresh resets data', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final query = createInfinityQuery<int, int>(
        fetch: (cursor) async => [1, 2, 3],
        getNextCursor: (lastPage, allPages) => null,
      );

      final data = container.read(query);

      await data.fetchNext();
      expect(data.data.value, [1, 2, 3]);

      await data.refresh();

      expect(data.data.value, [1, 2, 3]);
      // Verify it's a fresh load by ensuring pages count is 1 after refresh
      expect(data.pages.value.length, 1);
    });
  });
}
