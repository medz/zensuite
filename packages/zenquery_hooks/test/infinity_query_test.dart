import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:zenquery_hooks/zenquery_hooks.dart';

void main() {
  group('useInfinityQuery', () {
    testWidgets('starts with initial fetch on mount', (tester) async {
      var fetchCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              useInfinityQuery<int, int>(
                fetch: (cursor) async {
                  fetchCount++;
                  return [1, 2, 3];
                },
                getNextCursor: (lastPage, allPages) => allPages.length,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(fetchCount, greaterThanOrEqualTo(1));
    });

    testWidgets('returns correct initial data structure', (tester) async {
      late InfinityQueryHookResponse<int, int> response;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              response = useInfinityQuery<int, int>(
                fetch: (cursor) async => [1, 2, 3],
                getNextCursor: (lastPage, allPages) => allPages.length,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(response.data, [1, 2, 3]);
      expect(response.pages, [
        [1, 2, 3],
      ]);
      expect(response.hasMore, true);
      expect(response.fetchNext, isA<VoidCallback>());
      expect(response.refresh, isA<VoidCallback>());
    });

    testWidgets('fetchNext loads more pages', (tester) async {
      late InfinityQueryHookResponse<int, int> response;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              response = useInfinityQuery<int, int>(
                fetch: (cursor) async {
                  final start = cursor ?? 0;
                  return [start * 10 + 1, start * 10 + 2, start * 10 + 3];
                },
                getNextCursor: (lastPage, allPages) {
                  if (allPages.length >= 3) return null; // Stop after 3 pages
                  return allPages.length;
                },
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(response.pages.length, 1);
      expect(response.data, [1, 2, 3]);

      // Fetch second page
      response.fetchNext();
      await tester.pumpAndSettle();

      expect(response.pages.length, 2);
      expect(response.data, [1, 2, 3, 11, 12, 13]);
    });

    testWidgets('hasMore becomes false when no more pages', (tester) async {
      late InfinityQueryHookResponse<int, int> response;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              response = useInfinityQuery<int, int>(
                fetch: (cursor) async => [1, 2, 3],
                getNextCursor: (lastPage, allPages) {
                  // Only allow 1 page
                  return null;
                },
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(response.hasMore, false);
    });

    testWidgets('refresh clears and reloads data', (tester) async {
      late InfinityQueryHookResponse<int, int> response;
      var fetchCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              response = useInfinityQuery<int, int>(
                fetch: (cursor) async {
                  fetchCount++;
                  return [fetchCount * 10];
                },
                getNextCursor: (lastPage, allPages) => allPages.length,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      final initialFetchCount = fetchCount;
      expect(response.data.isNotEmpty, true);

      // Fetch next to have multiple pages
      response.fetchNext();
      await tester.pumpAndSettle();

      expect(response.pages.length, 2);

      // Refresh should reset to fresh data
      response.refresh();
      await tester.pumpAndSettle();

      expect(response.pages.length, 1);
      expect(fetchCount, greaterThan(initialFetchCount + 1));
    });

    testWidgets('loadState not trigger when loading first page', (tester) async {
      late InfinityQueryHookResponse<int, int> response;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              response = useInfinityQuery<int, int>(
                fetch: (cursor) async => [1, 2, 3],
                getNextCursor: (lastPage, allPages) => allPages.length,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(response.loadState, isA<MutationIdle<void>>());
    });

    testWidgets('disposes correctly when widget is removed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              useInfinityQuery<String, int>(
                fetch: (cursor) async => ['item'],
                getNextCursor: (lastPage, allPages) => allPages.length,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remove the widget
      await tester.pumpWidget(const ProviderScope(child: SizedBox()));

      expect(tester.takeException(), isNull);
    });

    testWidgets('works with different cursor types', (tester) async {
      late InfinityQueryHookResponse<String, String> response;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              response = useInfinityQuery<String, String>(
                fetch: (cursor) async {
                  final c = cursor ?? 'start';
                  return ['item_$c'];
                },
                getNextCursor: (lastPage, allPages) {
                  if (allPages.length >= 2) return null;
                  return 'page_${allPages.length}';
                },
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(response.data, ['item_start']);

      response.fetchNext();
      await tester.pumpAndSettle();

      expect(response.data, ['item_start', 'item_page_1']);
      expect(response.hasMore, false);
    });

    testWidgets('shows data after fetch completes', (tester) async {
      late InfinityQueryHookResponse<String, int> response;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              response = useInfinityQuery<String, int>(
                fetch: (cursor) async => ['Item 1', 'Item 2'],
                getNextCursor: (lastPage, allPages) => allPages.length,
              );
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(response.data, ['Item 1', 'Item 2']);
      expect(response.hasMore, true);
    });
  });
}
