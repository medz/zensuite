import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:riverpod/experimental/mutation.dart';
import 'package:zenquery_hooks/zenquery_hooks.dart';

void main() {
  runApp(const ProviderScope(child: MaterialApp(home: HomePage())));
}

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: 4);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZenQuery Hooks Example'),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'useQuery'),
            Tab(text: 'useMutation'),
            Tab(text: 'useInfinityQuery'),
            Tab(text: 'useStore'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: const [
          QueryExample(),
          MutationExample(),
          InfinityQueryExample(),
          StoreExample(),
        ],
      ),
    );
  }
}

class QueryExample extends HookWidget {
  const QueryExample({super.key});

  @override
  Widget build(BuildContext context) {
    final (data, refetch) = useQuery((ref) async {
      await Future.delayed(const Duration(seconds: 1));
      return 'Fetched at ${DateTime.now()}';
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          data.when(
            data: (value) => Text(value),
            error: (e, s) => Text('Error: $e'),
            loading: () => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: refetch, child: const Text('Refetch')),
        ],
      ),
    );
  }
}

class MutationExample extends HookWidget {
  const MutationExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: Implicitly typed for State, Run, Reset
    final (mutation, run, reset) = useMutationAction((tsx) async {
      await Future.delayed(const Duration(seconds: 1));
      if (DateTime.now().second % 2 == 0) throw 'Random Error';
      return 'Success!';
    });
    final state = useMutationState(mutation);
    final (
      mutationParam,
      runParam,
      resetParam,
    ) = useMutationActionWithParam<String, String>((tsx, param) async {
      await Future.delayed(const Duration(seconds: 1));
      if (DateTime.now().second % 2 == 0) throw 'Random Error $param';
      return 'Success! $param';
    });

    final stateParam = useMutationState(mutationParam('test'));

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              if (state is MutationPending) const CircularProgressIndicator(),
              if (state is MutationSuccess<String>)
                Text('Result: ${state.value}'),
              if (state is MutationError)
                Text('Error: ${(state as MutationError).error}'),
              if (state is! MutationPending &&
                  state is! MutationSuccess &&
                  state is! MutationError)
                const Text('Press button to start'),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: run, child: const Text('Run Mutation')),
              ElevatedButton(onPressed: reset, child: const Text('Reset')),
            ],
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              if (stateParam is MutationPending)
                const CircularProgressIndicator(),
              if (stateParam is MutationSuccess<String>)
                Text('Result: ${stateParam.value}'),
              if (stateParam is MutationError)
                Text('Error: ${(stateParam as MutationError).error}'),
              if (stateParam is! MutationPending &&
                  stateParam is! MutationSuccess &&
                  stateParam is! MutationError)
                const Text('Press button to start'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => runParam('test'),
                child: const Text('Run Mutation'),
              ),
              ElevatedButton(
                onPressed: () => resetParam('test'),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InfinityQueryExample extends HookWidget {
  const InfinityQueryExample({super.key});

  @override
  Widget build(BuildContext context) {
    final infinityQuery = useInfinityQuery<String, int>(
      fetch: (cursor) async {
        await Future.delayed(const Duration(milliseconds: 500));
        final start = cursor ?? 0;
        return List.generate(10, (index) => 'Item ${start + index}');
      },
      getNextCursor: (lastPage, pages) {
        if (pages.length >= 5) return null;
        return pages.length * 10;
      },
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: infinityQuery.refresh,
        child: const Icon(Icons.refresh),
      ),
      body: Column(
        children: [
          if (infinityQuery.loadState is MutationError)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: ${infinityQuery.loadState}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: infinityQuery.data.length + 1,
              itemBuilder: (context, index) {
                if (index == infinityQuery.data.length) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: infinityQuery.hasMore
                          ? (infinityQuery.loadState.isPending
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: infinityQuery.fetchNext,
                                    child: const Text('Load More'),
                                  ))
                          : const Text('No more items'),
                    ),
                  );
                }
                return ListTile(title: Text(infinityQuery.data[index]));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StoreExample extends HookWidget {
  const StoreExample({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = useStore((ref) => ValueNotifier(0));

    // We need to listen to the ValueNotifier
    final count = useValueListenable(counter);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Count: $count',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => counter.value++,
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}
