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
  });
}
