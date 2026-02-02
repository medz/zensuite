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

      final (state, run, _) = container.read(mutation);

      expect(container.read(state), isA<MutationIdle<String>>());

      final future = run();
      expect(container.read(state), isA<MutationPending<String>>());

      await future;

      expect(container.read(state), isA<MutationSuccess<String>>());
      expect(await future, 'success');
    });

    test('createMutation handles error execution', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutation<String>((tsx) async {
        throw Exception('failure');
      });

      final (state, run, _) = container.read(mutation);

      try {
        await run();
      } catch (_) {}

      expect(container.read(state), isA<MutationError<String>>());
    });

    test('createMutation reset clears state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutation<String>((tsx) async {
        return 'success';
      });

      final (state, run, reset) = container.read(mutation);

      await run();
      expect(container.read(state), isA<MutationSuccess<String>>());

      reset();
      expect(container.read(state), isA<MutationIdle<String>>());
    });

    test('createMutationWithParam handles params', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mutation = createMutationWithParam<String, int>((tsx, param) async {
        return 'success $param';
      });

      final (state, run, _) = container.read(mutation);
      final result = await run(1);
      final result2 = await run(2);
      final result2State = container.read(state(2));

      expect(result, 'success 1');
      expect(result2, 'success 2');
      expect(result2State, isA<MutationSuccess<String>>());
    });
  });
}
