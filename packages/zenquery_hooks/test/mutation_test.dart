import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:zenquery_hooks/zenquery_hooks.dart';

void main() {
  group('useMutationAction', () {
    testWidgets('returns mutation, run, and reset functions', (tester) async {
      late Mutation<String> mutation;
      late Future<String> Function() run;
      late void Function() reset;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (m, r, rs) = useMutationAction((tsx) async => 'result');
              mutation = m;
              run = r;
              reset = rs;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(mutation, isA<Mutation<String>>());
      expect(run, isA<Future<String> Function()>());
      expect(reset, isA<void Function()>());
    });

    testWidgets('mutation starts in idle state', (tester) async {
      late MutationState<String> state;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (mutation, _, _) = useMutationAction((tsx) async => 'result');
              state = useMutationState(mutation);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(state, isA<MutationIdle<String>>());
    });

    testWidgets('mutation transitions through pending to success',
        (tester) async {
      final completer = Completer<String>();
      late MutationState<String> state;
      late Future<String> Function() run;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (mutation, r, _) = useMutationAction((tsx) => completer.future);
              state = useMutationState(mutation);
              run = r;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(state, isA<MutationIdle<String>>());

      run();
      await tester.pump();

      expect(state, isA<MutationPending<String>>());

      completer.complete('success');
      await tester.pumpAndSettle();

      expect(state, isA<MutationSuccess<String>>());
      expect((state as MutationSuccess<String>).value, 'success');
    });

    testWidgets('mutation transitions to error state on failure',
        (tester) async {
      late MutationState<String> state;
      late Future<String> Function() run;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (mutation, r, _) =
                  useMutationAction((tsx) async => throw Exception('test error'));
              state = useMutationState(mutation);
              run = r;
              return const SizedBox();
            },
          ),
        ),
      );

      try {
        await run();
      } catch (_) {}
      await tester.pumpAndSettle();

      expect(state, isA<MutationError<String>>());
    });

    testWidgets('reset returns mutation to idle state', (tester) async {
      late MutationState<String> state;
      late Future<String> Function() run;
      late void Function() reset;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (mutation, r, rs) = useMutationAction((tsx) async => 'result');
              state = useMutationState(mutation);
              run = r;
              reset = rs;
              return const SizedBox();
            },
          ),
        ),
      );

      await run();
      await tester.pumpAndSettle();

      expect(state, isA<MutationSuccess<String>>());

      reset();
      await tester.pump();

      expect(state, isA<MutationIdle<String>>());
    });

    testWidgets('run returns the result value', (tester) async {
      late Future<String> Function() run;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (_, r, _) = useMutationAction((tsx) async => 'returned value');
              run = r;
              return const SizedBox();
            },
          ),
        ),
      );

      final result = await run();
      expect(result, 'returned value');
    });
  });

  group('useMutationActionWithParam', () {
    testWidgets('handles parameterized mutations', (tester) async {
      late Mutation<String> Function(int) getMutation;
      late Future<String> Function(int) run;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (m, r, _) = useMutationActionWithParam<String, int>(
                (tsx, param) async => 'result: $param',
              );
              getMutation = m;
              run = r;
              return const SizedBox();
            },
          ),
        ),
      );

      final result = await run(42);
      expect(result, 'result: 42');

      expect(getMutation(42), isA<Mutation<String>>());
    });

    testWidgets('different params create different mutation states',
        (tester) async {
      late Mutation<String> Function(String) getMutation;
      late Future<String> Function(String) run;
      late MutationState<String> stateA;
      late MutationState<String> stateB;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (m, r, _) = useMutationActionWithParam<String, String>(
                (tsx, param) async => 'result: $param',
              );
              getMutation = m;
              run = r;
              stateA = useMutationState(getMutation('a'));
              stateB = useMutationState(getMutation('b'));
              return const SizedBox();
            },
          ),
        ),
      );

      await run('a');
      await tester.pumpAndSettle();

      expect(stateA, isA<MutationSuccess<String>>());
      expect(stateB, isA<MutationIdle<String>>());
    });

    testWidgets('reset with param resets specific mutation', (tester) async {
      late Mutation<String> Function(int) getMutation;
      late Future<String> Function(int) run;
      late void Function(int) reset;
      late MutationState<String> state;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (m, r, rs) = useMutationActionWithParam<String, int>(
                (tsx, param) async => 'result: $param',
              );
              getMutation = m;
              run = r;
              reset = rs;
              state = useMutationState(getMutation(1));
              return const SizedBox();
            },
          ),
        ),
      );

      await run(1);
      await tester.pumpAndSettle();

      expect(state, isA<MutationSuccess<String>>());

      reset(1);
      await tester.pump();

      expect(state, isA<MutationIdle<String>>());
    });
  });

  group('useMutationState', () {
    testWidgets('listens to mutation state changes', (tester) async {
      final completer = Completer<int>();
      late MutationState<int> state;
      late Future<int> Function() run;

      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (mutation, r, _) = useMutationAction((tsx) => completer.future);
              state = useMutationState(mutation);
              run = r;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(state, isA<MutationIdle<int>>());

      run();
      await tester.pump();

      expect(state, isA<MutationPending<int>>());

      completer.complete(100);
      await tester.pumpAndSettle();

      expect(state, isA<MutationSuccess<int>>());
      expect((state as MutationSuccess<int>).value, 100);
    });

    testWidgets('disposes subscription when widget is removed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: HookBuilder(
            builder: (context) {
              final (mutation, _, _) = useMutationAction((tsx) async => 'test');
              useMutationState(mutation);
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        const ProviderScope(child: SizedBox()),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
