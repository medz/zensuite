import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenquery_hooks/zenquery_hooks.dart';

void main() {
  group('useStore', () {
    testWidgets('returns the created store value', (tester) async {
      late int storeValue;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              storeValue = useStore((ref) => 42);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(storeValue, 42);
    });

    testWidgets('returns same instance across rebuilds', (tester) async {
      final values = <ValueNotifier<int>>[];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HookBuilder(
              builder: (context) {
                final notifier = useStore((ref) => ValueNotifier(0));
                useListenable(notifier);
                values.add(notifier);
                return TextButton(
                  onPressed: () => notifier.value++,
                  child: const Text('Increment'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      // Same instance should be returned
      expect(values.length, 2);
      expect(values[0], same(values[1]));
    });

    testWidgets('rebuilds widget when store value changes', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HookBuilder(
              builder: (context) {
                final counter = useStore((ref) => ValueNotifier(0));
                final count = useValueListenable(counter);
                return Column(
                  children: [
                    Text('Count: $count'),
                    TextButton(
                      onPressed: () => counter.value++,
                      child: const Text('Increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Count: 0'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(find.text('Count: 1'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(find.text('Count: 2'), findsOneWidget);
    });

    testWidgets('disposes subscription when widget is removed', (tester) async {
      final key = GlobalKey();

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            key: key,
            builder: (context) {
              useStore((ref) => 'test');
              return const SizedBox();
            },
          ),
        ),
      );

      // Remove the widget
      await tester.pumpWidget(
        const ProviderScope(child: SizedBox()),
      );

      // No exception should be thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('works with complex types', (tester) async {
      late Map<String, int> storeValue;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              storeValue = useStore((ref) => {'a': 1, 'b': 2});
              return const SizedBox();
            },
          ),
        ),
      );

      expect(storeValue, {'a': 1, 'b': 2});
    });
  });
}
