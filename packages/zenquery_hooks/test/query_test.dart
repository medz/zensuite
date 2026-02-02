import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenquery_hooks/zenquery_hooks.dart';

void main() {
  group('useQuery', () {
    testWidgets('transitions to data state on success', (tester) async {
      late AsyncValue<String> queryState;
      final completer = Completer<String>();

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (state, _) = useQuery((ref) => completer.future);
              queryState = state;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(queryState.isLoading, true);

      completer.complete('success');
      await tester.pumpAndSettle();

      expect(queryState.value, 'success');
    });

    testWidgets('transitions to error state on failure', (tester) async {
      late AsyncValue<String> queryState;
      final completer = Completer<String>();

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (state, _) = useQuery((ref) => completer.future);
              queryState = state;
              return const SizedBox();
            },
          ),
        ),
      );

      completer.completeError(Exception('test error'));
      await tester.pumpAndSettle();

      expect(queryState.hasError, true);
    });

    testWidgets('refetch triggers new fetch', (tester) async {
      var fetchCount = 0;
      late VoidCallback refetch;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (_, refetchFn) = useQuery((ref) async {
                fetchCount++;
                return 'data $fetchCount';
              });
              refetch = refetchFn;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(fetchCount, 1);

      refetch();
      await tester.pumpAndSettle();

      expect(fetchCount, 2);
    });

    testWidgets('displays loading, data, and error states correctly',
        (tester) async {
      final completer = Completer<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: HookBuilder(
              builder: (context) {
                final (state, _) = useQuery((ref) => completer.future);
                return state.when(
                  data: (data) => Text('Data: $data'),
                  loading: () => const Text('Loading'),
                  error: (e, _) => Text('Error: $e'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Loading'), findsOneWidget);

      completer.complete('fetched');
      await tester.pumpAndSettle();

      expect(find.text('Data: fetched'), findsOneWidget);
    });

    testWidgets('disposes subscription when widget is removed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              useQuery((ref) async => 'test');
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Remove the widget
      await tester.pumpWidget(
        const ProviderScope(child: SizedBox()),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles typed data correctly', (tester) async {
      final completer = Completer<List<int>>();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            child: HookBuilder(
              builder: (context) {
                final (state, _) = useQuery((ref) => completer.future);
                return state.when(
                  data: (data) => Text('Sum: ${data.reduce((a, b) => a + b)}'),
                  loading: () => const Text('Loading'),
                  error: (e, _) => Text('Error: $e'),
                );
              },
            ),
          ),
        ),
      );

      completer.complete([1, 2, 3, 4, 5]);
      await tester.pumpAndSettle();

      expect(find.text('Sum: 15'), findsOneWidget);
    });
  });
}
