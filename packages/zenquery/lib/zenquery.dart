/// The entry point for the ZenQuery package.
///
/// ZenQuery provides a set of tools for managing server state in Flutter applications,
/// leveraging the power of Riverpod. It offers a simple and consistent API for
/// handling queries, mutations, and infinite pagination.
///
/// To use ZenQuery, simply import this library:
/// ```dart
/// import 'package:zenquery/zenquery.dart';
/// ```
library;

// Enforce use packages
export 'package:riverpod/riverpod.dart';
export 'package:riverpod/misc.dart';
export 'package:riverpod/experimental/mutation.dart';

// Queries
export 'src/infinity_query.dart';
export 'src/mutation.dart';
export 'src/query.dart';
export 'src/store.dart';
