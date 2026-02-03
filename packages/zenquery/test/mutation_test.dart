import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:zenquery/zenquery.dart';

void main() {
  group('Mutation Tests', () {
    test('createMutation handles successful execution', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutation<String>((tsx) async {
        return 'success';
      });

      final MutationAction(mutation: mutationState, :run) = container.read(
        mutation,
      );

      expect(container.read(mutationState), isA<MutationIdle<String>>());

      final future = run();
      expect(container.read(mutationState), isA<MutationPending<String>>());

      await future;

      final successState = container.read(mutationState);
      expect(successState, isA<MutationSuccess<String>>());
      expect((successState as MutationSuccess<String>).value, 'success');
    });

    test('createMutation handles error execution', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutation<String>((tsx) async {
        throw Exception('failure');
      });

      final MutationAction(mutation: mutationState, :run) = container.read(
        mutation,
      );

      try {
        await run();
      } catch (_) {}

      expect(container.read(mutationState), isA<MutationError<String>>());
    });

    test('createMutation reset clears state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutation<String>((tsx) async {
        return 'success';
      });

      final MutationAction(mutation: mutationState, :run, :reset) = container
          .read(mutation);

      await run();
      expect(container.read(mutationState), isA<MutationSuccess<String>>());

      reset();
      expect(container.read(mutationState), isA<MutationIdle<String>>());
    });

    test('createMutationWithParam handles params', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutationWithParam<String, int>((tsx, param) async {
        return 'success $param';
      });

      final action = container.read(mutation);
      final result = await action.run(1);
      final result2 = await action.run(2);
      final result2State = container.read(action.mutation(2));

      expect(result, 'success 1');
      expect(result2, 'success 2');
      expect(result2State, isA<MutationSuccess<String>>());
    });

    test('createMutationPersist creates persistent mutation', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutationPersist<String>((tsx) async {
        return 'persistent success';
      });

      final MutationAction(mutation: mutationState, :run) = container.read(
        mutation,
      );

      expect(container.read(mutationState), isA<MutationIdle<String>>());

      final result = await run();

      expect(result, 'persistent success');
      expect(container.read(mutationState), isA<MutationSuccess<String>>());
    });

    test(
      'createMutationWithParamPersist handles params persistently',
      () async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final mutation = createMutationWithParamPersist<String, int>((
          tsx,
          param,
        ) async {
          return 'persistent $param';
        });

        final action = container.read(mutation);
        final result = await action.run(10);

        expect(result, 'persistent 10');
        expect(
          container.read(action.mutation(10)),
          isA<MutationSuccess<String>>(),
        );
      },
    );

    test('createMutationWithParam reset clears specific param state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutationWithParam<String, int>((tsx, param) async {
        return 'success $param';
      });

      final action = container.read(mutation);
      await action.run(1);
      await action.run(2);

      expect(
        container.read(action.mutation(1)),
        isA<MutationSuccess<String>>(),
      );
      expect(
        container.read(action.mutation(2)),
        isA<MutationSuccess<String>>(),
      );

      // Reset only param 1
      action.reset(1);

      expect(container.read(action.mutation(1)), isA<MutationIdle<String>>());
      expect(
        container.read(action.mutation(2)),
        isA<MutationSuccess<String>>(),
      );
    });

    test('createMutationPersist reset clears state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutationPersist<String>((tsx) async {
        return 'persistent result';
      });

      final MutationAction(mutation: mutationState, :run, :reset) = container
          .read(mutation);

      await run();
      expect(container.read(mutationState), isA<MutationSuccess<String>>());

      reset();
      expect(container.read(mutationState), isA<MutationIdle<String>>());
    });

    test('createMutationWithParamPersist reset clears param state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutationWithParamPersist<String, int>((
        tsx,
        param,
      ) async {
        return 'persistent $param';
      });

      final action = container.read(mutation);
      await action.run(5);

      expect(
        container.read(action.mutation(5)),
        isA<MutationSuccess<String>>(),
      );

      action.reset(5);

      expect(container.read(action.mutation(5)), isA<MutationIdle<String>>());
    });
  });
}
